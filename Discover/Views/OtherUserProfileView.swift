//
//  OtherUserProfileView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct OtherUserProfileView: View {
    let userId: String
    let userPseudonym: String
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var userPosts: [Post] = []
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isFollowing: Bool = false
    @State private var user: User? = nil
    @State private var isLoading: Bool = false
    @State private var showFollowersFollowing: Bool = false
    @State private var followersFollowingTab: FollowersFollowingView.FollowTab = .followers

    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            if isLoading && user == nil {
                LoadingOverlay(message: "feed.loading".localized)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header avec Discover
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("profile.discover".localized)
                                    .font(.plusJakartaSansSemiBold(size: 17))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(Color.discoverBlack)
                                    .cornerRadius(22)
                            }
                            .padding(.leading, 16)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        
                        Group {
                            if let user = user, let profileURL = user.profilePictureURL {
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
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                } else {
                                    defaultProfileIcon
                                }
                            } else {
                                defaultProfileIcon
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
                        Text(userPseudonym)
                            .font(.plusJakartaSansBold(size: 24))
                            .foregroundColor(.themePrimaryText)
                            .padding(.top, 12)
                        
                        if let user = user, user.activeStreak > 0 {
                            StreakView(streakCount: user.activeStreak)
                                .padding(.top, 8)
                        }


                        
                        // Bouton Follow/Unfollow
                        Button(action: {
                            Task {
                                await toggleFollow()
                            }
                        }) {
                            Text(isFollowing ? "profile.unfollow".localized : "profile.follow".localized)
                                .font(.plusJakartaSansSemiBold(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 36)
                                .background(
                                    Group {
                                        if isFollowing {
                                            Color.gray
                                        } else {
                                            LinearGradient(
                                                colors: [Color.orange, Color.yellow],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .cornerRadius(18)
                        }
                        .padding(.top, 16)
                        
                        // Followers / Following
                        HStack(spacing: 60) {
                            Button(action: {
                                followersFollowingTab = .followers
                                showFollowersFollowing = true
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(followerCount)")
                                        .font(.plusJakartaSansBold(size: 20))
                                        .foregroundColor(.themePrimaryText)
                                    Text("profile.followers".localized)
                                        .font(.plusJakartaSans(size: 14))
                                        .foregroundColor(.themePrimaryText)
                                }
                            }
                            
                            Button(action: {
                                followersFollowingTab = .following
                                showFollowersFollowing = true
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(followingCount)")
                                        .font(.plusJakartaSansBold(size: 20))
                                        .foregroundColor(.themePrimaryText)
                                    Text("profile.following".localized)
                                        .font(.plusJakartaSans(size: 14))
                                        .foregroundColor(.themePrimaryText)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Grille de posts
                        if isLoading && userPosts.isEmpty {
                            LoadingSpinner(message: "feed.loading".localized)
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
                                    .aspectRatio(1, contentMode: .fill)
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
        .task {
            await loadProfileData()
        }
        .sheet(isPresented: $showFollowersFollowing) {
            FollowersFollowingView(
                userId: userId,
                userPseudonym: userPseudonym,
                initialTab: followersFollowingTab,
                authService: authService,
                firebaseService: firebaseService
            )
        }
    }
    
    private var defaultProfileIcon: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 50))
            )
    }

    private func loadProfileData() async {
        isLoading = true
        
        guard let currentUserId = authService.currentUser?.id else {
            isLoading = false
            return
        }
        
        async let userResult = firebaseService.getUserById(userId: userId)
        async let posts = firebaseService.fetchUserPosts(userId: userId)
        async let followers = firebaseService.getFollowerCount(userId: userId)
        async let following = firebaseService.getFollowingCount(userId: userId)
        async let followingState = firebaseService.isFollowing(followerId: currentUserId, followingId: userId)
        
        do {
            let (userObj, userPostsResult, followersResult, followingResult, isFollowingResult) = try await (userResult, posts, followers, following, followingState)
            
            // Précharger les premières images de la grille (6 premières pour une grille 2x3)
            let postsToPreload = userPostsResult.prefix(6)
            await ImagePreloader.shared.preloadCriticalImages(from: Array(postsToPreload), count: 6)
            
            // Précharger la photo de profil si disponible
            if let profileURL = userObj?.profilePictureURL, !profileURL.hasPrefix("data:image") {
                _ = await ImagePreloader.shared.preloadImage(from: profileURL)
            }
            
            await MainActor.run {
                self.user = userObj
                userPosts = userPostsResult

                followerCount = followersResult
                followingCount = followingResult
                isFollowing = isFollowingResult
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func toggleFollow() async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            if isFollowing {
                try await firebaseService.unfollowUser(followerId: currentUserId, followingId: userId)
                let newFollowerCount = try await firebaseService.getFollowerCount(userId: userId)
                await MainActor.run {
                    isFollowing = false
                    followerCount = newFollowerCount
                }
            } else {
                try await firebaseService.followUser(followerId: currentUserId, followingId: userId)
                let newFollowerCount = try await firebaseService.getFollowerCount(userId: userId)
                await MainActor.run {
                    isFollowing = true
                    followerCount = newFollowerCount
                }
            }
        } catch {
            print("Erreur lors du follow/unfollow: \(error)")
        }
    }
}
