//
//  NewProfileView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct NewProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var userPosts: [Post] = []
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Fond blanc
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header avec Discover et Settings
                    HStack {
                        Button(action: {}) {
                            Text("profile.discover".localized)
                                .font(.plusJakartaSansSemiBold(size: 17))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(hex: "222222"))
                                .cornerRadius(22)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        Button(action: {
                            showSettings = true
                        }) {
                            ZStack {
                                // Contour ovale horizontal (pill shape)
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 1.5)
                                    .frame(width: 60, height: 32)
                                
                                // Icône settings centrée
                                Image("logo_settings")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                    
                    // Photo de profil avec bordure orange-jaune
                    if let user = authService.currentUser {
                        // Photo de profil carrée avec coins très arrondis
                        Group {
                            if let profileURL = user.profilePictureURL, let url = URL(string: profileURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 50))
                                        )
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 50))
                                    )
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .padding(.top, 24)
                        
                        // Nom d'utilisateur
                        Text(user.pseudonym)
                            .font(.plusJakartaSansBold(size: 24))
                            .foregroundColor(Color(hex: "222222"))
                            .padding(.top, 12)
                        
                        // Followers / Following
                        HStack(spacing: 60) {
                            VStack(spacing: 4) {
                                Text("\(followerCount)")
                                    .font(.plusJakartaSansBold(size: 20))
                                    .foregroundColor(Color(hex: "222222"))
                                Text("profile.followers".localized)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(Color(hex: "222222"))
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(followingCount)")
                                    .font(.plusJakartaSansBold(size: 20))
                                    .foregroundColor(Color(hex: "222222"))
                                Text("profile.following".localized)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(Color(hex: "222222"))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Grille de posts
                        if isLoading && userPosts.isEmpty {
                            ProgressView("feed.loading".localized)
                                .padding(.top, 40)
                        } else if userPosts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("profile.no.posts".localized)
                                    .font(.plusJakartaSans(size: 15))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(userPosts) { post in
                                    AsyncImage(url: URL(string: post.coverArtURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    .frame(height: (UIScreen.main.bounds.width - 48) / 2)
                                    .cornerRadius(12)
                                    .clipped()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(authService: authService, firebaseService: firebaseService)
        }
        .task {
            await loadProfileData()
        }
    }
    
    private func loadProfileData() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        
        async let posts = firebaseService.fetchUserPosts(userId: userId)
        async let followers = firebaseService.getFollowerCount(userId: userId)
        async let following = firebaseService.getFollowingCount(userId: userId)
        
        do {
            let (userPostsResult, followersResult, followingResult) = try await (posts, followers, following)
            
            await MainActor.run {
                userPosts = userPostsResult
                followerCount = followersResult
                followingCount = followingResult
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
