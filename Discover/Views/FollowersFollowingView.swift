//
//  FollowersFollowingView.swift
//  Discover
//
//  Created by Enzo Gallo on 06/12/2025.
//

import SwiftUI

struct FollowersFollowingView: View {
    let userId: String
    let userPseudonym: String
    let initialTab: FollowTab
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var selectedTab: FollowTab
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var isLoading: Bool = false
    @State private var navigationPath = NavigationPath()
    
    @Environment(\.dismiss) var dismiss
    
    enum FollowTab {
        case followers
        case following
    }
    
    init(userId: String, userPseudonym: String, initialTab: FollowTab = .followers, authService: AuthService, firebaseService: FirebaseService) {
        self.userId = userId
        self.userPseudonym = userPseudonym
        self.initialTab = initialTab
        self.authService = authService
        self.firebaseService = firebaseService
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()
                
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
                    
                    // Nom d'utilisateur
                    Text(userPseudonym)
                        .font(.plusJakartaSansBold(size: 24))
                        .foregroundColor(.themePrimaryText)
                        .padding(.top, 16)
                    
                    // Sélecteur d'onglets
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedTab = .followers
                        }) {
                            VStack(spacing: 8) {
                                Text("profile.followers".localized)
                                    .font(.plusJakartaSansSemiBold(size: 16))
                                    .foregroundColor(selectedTab == .followers ? .themePrimaryText : .themeSecondaryText)
                                
                                Rectangle()
                                    .fill(selectedTab == .followers ? Color.orange : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            selectedTab = .following
                        }) {
                            VStack(spacing: 8) {
                                Text("profile.following".localized)
                                    .font(.plusJakartaSansSemiBold(size: 16))
                                    .foregroundColor(selectedTab == .following ? .themePrimaryText : .themeSecondaryText)
                                
                                Rectangle()
                                    .fill(selectedTab == .following ? Color.orange : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    // Liste des utilisateurs
                    if isLoading {
                        Spacer()
                        ProgressView("feed.loading".localized)
                            .padding(.top, 40)
                        Spacer()
                    } else {
                        let users = selectedTab == .followers ? followers : following
                        
                        if users.isEmpty {
                            Spacer()
                            VStack(spacing: 20) {
                                Image(systemName: selectedTab == .followers ? "person.2" : "person.2.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(selectedTab == .followers ? "profile.no.followers".localized : "profile.no.following".localized)
                                    .font(.plusJakartaSans(size: 15))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.top, 40)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(users) { user in
                                        UserRowView(
                                            user: user,
                                            currentUserId: authService.currentUser?.id,
                                            firebaseService: firebaseService,
                                            authService: authService
                                        )
                                        .onTapGesture {
                                            if user.id != authService.currentUser?.id {
                                                navigationPath.append(user.id)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: String.self) { userId in
                OtherUserProfileView(
                    userId: userId,
                    userPseudonym: "",
                    authService: authService,
                    firebaseService: firebaseService
                )
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedTab) { _ in
            Task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        do {
            if selectedTab == .followers {
                let followersList = try await firebaseService.getFollowers(userId: userId)
                await MainActor.run {
                    followers = followersList
                    isLoading = false
                }
            } else {
                let followingList = try await firebaseService.getFollowing(userId: userId)
                await MainActor.run {
                    following = followingList
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    let currentUserId: String?
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var authService: AuthService
    @State private var isFollowing: Bool = false
    @State private var isLoadingFollow: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo de profil
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
                            defaultProfileIcon
                        }
                    } else {
                        defaultProfileIcon
                    }
                } else {
                    defaultProfileIcon
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            
            // Pseudonyme
            VStack(alignment: .leading, spacing: 4) {
                Text(user.pseudonym)
                    .font(.plusJakartaSansSemiBold(size: 16))
                    .foregroundColor(.themePrimaryText)
                
                if user.activeStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("\(user.activeStreak)")
                            .font(.plusJakartaSans(size: 12))
                            .foregroundColor(.themeSecondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Bouton Follow/Unfollow (seulement si ce n'est pas l'utilisateur actuel)
            if let currentUserId = currentUserId, user.id != currentUserId {
                Button(action: {
                    Task {
                        await toggleFollow()
                    }
                }) {
                    if isLoadingFollow {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 32)
                            .padding(.horizontal, 16)
                    } else {
                        Text(isFollowing ? "profile.unfollow".localized : "profile.follow".localized)
                            .font(.plusJakartaSansSemiBold(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 32)
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
                            .cornerRadius(16)
                    }
                }
                .disabled(isLoadingFollow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.themeBackground)
        .task {
            if let currentUserId = currentUserId, user.id != currentUserId {
                await checkFollowStatus()
            }
        }
    }
    
    private var defaultProfileIcon: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 24))
            )
    }
    
    private func checkFollowStatus() async {
        guard let currentUserId = currentUserId else { return }
        
        do {
            let following = try await firebaseService.isFollowing(followerId: currentUserId, followingId: user.id)
            await MainActor.run {
                isFollowing = following
            }
        } catch {
            print("Erreur lors de la vérification du statut de follow: \(error)")
        }
    }
    
    private func toggleFollow() async {
        guard let currentUserId = currentUserId else { return }
        
        isLoadingFollow = true
        
        do {
            if isFollowing {
                try await firebaseService.unfollowUser(followerId: currentUserId, followingId: user.id)
                await MainActor.run {
                    isFollowing = false
                    isLoadingFollow = false
                }
            } else {
                try await firebaseService.followUser(followerId: currentUserId, followingId: user.id)
                await MainActor.run {
                    isFollowing = true
                    isLoadingFollow = false
                }
            }
        } catch {
            await MainActor.run {
                isLoadingFollow = false
            }
            print("Erreur lors du follow/unfollow: \(error)")
        }
    }
}

