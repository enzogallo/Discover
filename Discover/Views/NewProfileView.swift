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
    @ObservedObject var spotifyService: SpotifyService
    @State private var userPosts: [Post] = []
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var showSettings = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showDiscoverLogo: Bool = false
    @State private var selectedPostToDelete: Post? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            ScrollView {
                GeometryReader { geometry in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                VStack(spacing: 0) {
                    // Header avec Discover et Settings
                    HStack {
                        Button(action: {}) {
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
                        .opacity(showDiscoverLogo ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showDiscoverLogo)
                        
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
                            if let profileURL = user.profilePictureURL {
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
                        Text(user.pseudonym)
                            .font(.plusJakartaSansBold(size: 24))
                            .foregroundColor(.themePrimaryText)
                            .padding(.top, 12)
                        
                        if user.activeStreak > 0 {
                            StreakView(streakCount: user.activeStreak)
                                .padding(.top, 8)
                        }


                        
                        // Followers / Following
                        HStack(spacing: 60) {
                            VStack(spacing: 4) {
                                Text("\(followerCount)")
                                    .font(.plusJakartaSansBold(size: 20))
                                    .foregroundColor(.themePrimaryText)
                                Text("profile.followers".localized)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(.themePrimaryText)
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(followingCount)")
                                    .font(.plusJakartaSansBold(size: 20))
                                    .foregroundColor(.themePrimaryText)
                                Text("profile.following".localized)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(.themePrimaryText)
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
                                    .aspectRatio(1, contentMode: .fill)
                                    .cornerRadius(12)
                                    .clipped()
                                    .contextMenu {
                                        Button(action: {
                                            if let url = URL(string: post.spotifyURL) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            Label("profile.open.spotify".localized, systemImage: "music.note")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            selectedPostToDelete = post
                                            showDeleteConfirmation = true
                                        }) {
                                            Label("profile.delete.post".localized, systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDiscoverLogo = scrollOffset < -100
                }
            }
        }
        .alert("profile.delete.confirmation.title".localized, isPresented: $showDeleteConfirmation, presenting: selectedPostToDelete) { post in
            Button("common.cancel".localized, role: .cancel) { }
            Button("profile.delete.confirm".localized, role: .destructive) {
                Task {
                    await deletePost(post)
                }
            }
        } message: { post in
            Text("profile.delete.confirmation.message".localized)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(authService: authService, firebaseService: firebaseService, spotifyService: spotifyService)
        }
        .task {
            await loadProfileData()
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
    
    private func deletePost(_ post: Post) async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            try await firebaseService.deletePost(postId: post.id, userId: userId)
            await MainActor.run {
                userPosts.removeAll { $0.id == post.id }
            }
        } catch {
            print("Erreur lors de la suppression du post: \(error)")
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

