//
//  LoadingSpinner.swift
//  Discover
//
//  Created by Enzo Gallo on 06/12/2025.
//

import SwiftUI

struct LoadingSpinner: View {
    let message: String?
    let size: CGFloat
    @State private var rotation: Double = 0
    
    init(message: String? = nil, size: CGFloat = 50) {
        self.message = message
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Spinner avec gradient orange-jaune
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: size, height: size)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
            
            if let message = message {
                Text(message)
                    .font(.plusJakartaSans(size: 15))
                    .foregroundColor(.themeSecondaryText)
            }
        }
    }
}

// Variante avec overlay pour les vues qui chargent en plein écran
struct LoadingOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            LoadingSpinner(message: message)
        }
    }
}

