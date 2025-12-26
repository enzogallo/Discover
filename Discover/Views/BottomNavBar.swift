//
//  BottomNavBar.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Int
    @Binding var showSharePopup: Bool
    @ObservedObject var authService: AuthService
    
    var body: some View {
        HStack {
            Spacer()
            
            // Home icon
            Button(action: {
                selectedTab = 0
            }) {
                Image(selectedTab == 0 ? "home_filled" : "home_empty")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            // Add button (centered, larger)
            Button(action: {
                showSharePopup = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.themePrimaryText)
                    .clipShape(Circle())
            }
            .offset(y: -8)
            
            Spacer()
            
            // Profile icon
            Button(action: {
                selectedTab = 1
            }) {
                Group {
                    if let user = authService.currentUser,
                       let profileURL = user.profilePictureURL {
                        if profileURL.hasPrefix("data:image"),
                           let data = Data(base64Encoded: profileURL.replacingOccurrences(of: "data:image/jpeg;base64,", with: "").replacingOccurrences(of: "data:image/png;base64,", with: "")),
                           let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let url = URL(string: profileURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                )
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            )
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(selectedTab == 1 ? Color.themePrimaryText : Color.clear, lineWidth: 2)
                )
            }
            
            Spacer()
        }
        .frame(height: 60)
        .background(
            ZStack {
                RoundedCorner(radius: 30, corners: [.allCorners])
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                RoundedCorner(radius: 30, corners: [.allCorners])
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
