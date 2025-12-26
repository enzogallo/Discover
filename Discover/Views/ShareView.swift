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
                            .font(.plusJakartaSans(size: 15))
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
                        
                        TextField("share.search.placeholder".localized, text: $searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchQuery) { oldValue, newValue in
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
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.plusJakartaSans(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                // Résultats
                if isLoading {
                    Spacer()
                    ProgressView("share.searching".localized)
                    Spacer()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("share.no.results".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("share.search.prompt".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
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
            .navigationTitle("share.title".localized)
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
                    errorMessage = "common.error.prefix".localized(with: error.localizedDescription)
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
        timeUntilNextPost = "share.already.shared.today".localized
    }
    
    private func shareMusic(_ item: MusicItem) async {
        guard let user = authService.currentUser else { return }
        guard canPost else {
            await MainActor.run {
                errorMessage = "share.error.already.shared".localized
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
                errorMessage = "common.error.prefix".localized(with: error.localizedDescription)
            }
        }
    }
}
