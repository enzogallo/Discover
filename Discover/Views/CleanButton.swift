//
//  CleanButton.swift
//  Discover
//
//  Created by Auto on 06/12/2025.
//

import SwiftUI

struct CleanButton: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let borderGradient: LinearGradient
    
    init(
        text: String,
        backgroundColor: Color = Color.black.opacity(0.6),
        textColor: Color = .white,
        borderGradient: LinearGradient? = nil
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderGradient = borderGradient ?? LinearGradient(
            colors: [.white.opacity(0.3), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Text(text)
            .font(.plusJakartaSansSemiBold(size: 15))
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(borderGradient, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    ZStack {
        Color.gray
        VStack(spacing: 20) {
            CleanButton(text: "Test Button")
            CleanButton(
                text: "Orange Button",
                backgroundColor: Color.orange.opacity(0.8)
            )
            CleanButton(
                text: "Blue Button",
                backgroundColor: Color.blue.opacity(0.6),
                borderGradient: LinearGradient(
                    colors: [.white.opacity(0.4), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

