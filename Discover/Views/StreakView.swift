//
//  StreakView.swift
//  Discover
//
//  Created by Antigravity on 26/12/2025.
//

import SwiftUI

struct StreakView: View {
    let streakCount: Int
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 16))
            
            if showLabel {
                Text(streakCount > 1 ? String(format: "streak.days.plural".localized, streakCount) : String(format: "streak.days".localized, streakCount))
                    .font(.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(.primary)
            } else {
                Text("\(streakCount)")
                    .font(.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    Group {
        StreakView(streakCount: 5)
        StreakView(streakCount: 1, showLabel: false)
    }
    .padding()
}
