//
//  ProfileView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var userPosts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête avec pseudonyme
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        if let user = authService.currentUser {
                            Text(user.pseudonym)
                                .font(.plusJakartaSansBold(size: 28))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(.systemGray6))
                    
                    // Liste des posts
                    if isLoading && userPosts.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView("Chargement...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)
                    } else if userPosts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("profile.no.posts".localized)
                                .font(.plusJakartaSans(size: 15))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(userPosts) { post in
                                UserPostCard(post: post)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("profile.my.profile".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.logout".localized) {
                        authService.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .task {
                await loadUserPosts()
            }
        }
    }
    
    private func loadUserPosts() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let posts = try await firebaseService.fetchUserPosts(userId: userId)
            await MainActor.run {
                userPosts = posts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct UserPostCard: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
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
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.musicTitle)
                    .font(.plusJakartaSansSemiBold(size: 17))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(post.artistName)
                    .font(.plusJakartaSans(size: 15))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(post.isAlbum ? "common.album".localized : "common.track".localized)
                        .font(.plusJakartaSans(size: 12))
                        .foregroundColor(.blue)
                    
                    Text("common.bullet".localized)
                        .font(.plusJakartaSans(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text(formatDate(post.timestamp))
                        .font(.plusJakartaSans(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
