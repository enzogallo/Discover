//
//  CountdownView.swift
//  Discover
//
//  Created by Antigravity on 26/12/2025.
//

import SwiftUI
import Combine

struct CountdownView: View {
    @State private var timeRemaining: String = "00:00:00"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .symbolEffect(.pulse, options: .repeating)
            
            Text(timeRemaining)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onReceive(timer) { _ in
            updateTime()
        }
        .onAppear {
            updateTime()
        }
    }
    
    private func updateTime() {
        let calendar = Calendar.current
        let now = Date()
        
        // Target: Prochain minuit
        guard let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            return
        }
        
        let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: nextMidnight)
        
        if let hour = diff.hour, let minute = diff.minute, let second = diff.second {
            timeRemaining = String(format: "%02d:%02d:%02d", hour, minute, second)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        CountdownView()
    }
}
