//
//  ShareView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct ShareView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    @State private var searchQuery: String = ""
    @State private var searchResults: [MusicItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var canPost: Bool = true
    @State private var timeUntilNextPost: String = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Message si déjà posté aujourd'hui
                if !canPost {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(timeUntilNextPost)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                }
                
                // Barre de recherche
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Rechercher un artiste, album ou morceau...", text: $searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchQuery) { newValue in
                                // Annuler la recherche précédente
                                searchTask?.cancel()
                                
                                // Si le champ est vide, vider les résultats
                                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    searchResults = []
                                    return
                                }
                                
                                // Lancer une nouvelle recherche après 0.5 seconde de délai (debounce)
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                                    
                                    // Vérifier que la tâche n'a pas été annulée
                                    guard !Task.isCancelled else { return }
                                    
                                    await performSearch()
                                }
                            }
                            .onSubmit {
                                searchTask?.cancel()
                                Task {
                                    await performSearch()
                                }
                            }
                        
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                // Résultats
                if isLoading {
                    Spacer()
                    ProgressView("Recherche...")
                    Spacer()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Aucun résultat")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Recherchez un morceau ou un album")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { item in
                                MusicItemCard(
                                    item: item,
                                    canPost: canPost,
                                    onSelect: {
                                        Task {
                                            await shareMusic(item)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Partager")
            .task {
                await checkCanPost()
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }
    
    private func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let results = try await spotifyService.searchMusic(query: query)
            await MainActor.run {
                // Vérifier que la requête n'a pas changé pendant la recherche
                if self.searchQuery.trimmingCharacters(in: .whitespaces) == query {
                    searchResults = results
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                // Vérifier que la requête n'a pas changé pendant la recherche
                if self.searchQuery.trimmingCharacters(in: .whitespaces) == query {
                    errorMessage = "Erreur: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }
    
    private func checkCanPost() async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            let canPostResult = try await firebaseService.canUserPost(userId: userId)
            await MainActor.run {
                canPost = canPostResult
                if !canPost {
                    updateTimeUntilNextPost()
                }
            }
        } catch {
            // En cas d'erreur, on autorise quand même (pour ne pas bloquer)
            await MainActor.run {
                canPost = true
            }
        }
    }
    
    private func updateTimeUntilNextPost() {
        // Cette fonction devrait calculer le temps restant
        // Pour simplifier, on affiche juste un message
        timeUntilNextPost = "Vous avez déjà partagé aujourd'hui. Réessayez demain."
    }
    
    private func shareMusic(_ item: MusicItem) async {
        guard let user = authService.currentUser else { return }
        guard canPost else {
            await MainActor.run {
                errorMessage = "Vous avez déjà partagé un morceau dans les dernières 24 heures"
            }
            return
        }
        
        let post = Post(
            userPseudonym: user.pseudonym,
            userId: user.id,
            musicTitle: item.title,
            artistName: item.artist,
            spotifyID: item.spotifyID,
            coverArtURL: item.coverArtURL,
            spotifyURL: item.spotifyURL,
            isAlbum: item.isAlbum
        )
        
        do {
            try await firebaseService.createPost(post)
            await MainActor.run {
                searchQuery = ""
                searchResults = []
                errorMessage = ""
                canPost = false
                updateTimeUntilNextPost()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct MusicItemCard: View {
    let item: MusicItem
    let canPost: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: item.coverArtURL)) { image in
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
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(item.isAlbum ? "Album" : "Morceau")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if canPost {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canPost)
    }
}
