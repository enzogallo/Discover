//
//  FeedView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && firebaseService.posts.isEmpty {
                    ProgressView("Chargement...")
                } else if firebaseService.posts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Aucun partage pour le moment")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(firebaseService.posts) { post in
                                PostCard(post: post, spotifyService: spotifyService)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Découvrir")
            .refreshable {
                await loadPosts()
            }
            .task {
                await loadPosts()
            }
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await firebaseService.fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct PostCard: View {
    let post: Post
    let spotifyService: SpotifyService
    
    var body: some View {
        Button(action: {
            spotifyService.openInSpotify(spotifyURL: post.spotifyURL)
        }) {
            HStack(spacing: 12) {
                // Pochette
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
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.musicTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(post.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(post.userPseudonym)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(post.isAlbum ? "Album" : "Morceau")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(post.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
