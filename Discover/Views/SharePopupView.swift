//
//  SharePopupView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct SharePopupView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery: String = ""
    @State private var searchResults: [MusicItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var canPost: Bool = true
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Fond blanc
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec Discover et Add
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("share.discover".localized)
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
                    
                    Text("share.add".localized)
                        .font(.plusJakartaSansSemiBold(size: 17))
                        .foregroundColor(Color(hex: "222222"))
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                
                // Barre de recherche
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    
                    TextField("share.search.placeholder".localized, text: $searchQuery)
                        .font(.plusJakartaSans(size: 15))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchQuery) { newValue in
                            searchTask?.cancel()
                            
                            if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                searchResults = []
                                return
                            }
                            
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000)
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
                                .padding(.trailing, 16)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.97))
                .cornerRadius(25)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Résultats
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("share.no.results".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.secondary)
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
                    VStack(spacing: 0) {
                        if !errorMessage.isEmpty {
                            HStack {
                                Text(errorMessage)
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                Spacer()
                            }
                            .background(Color.red.opacity(0.1))
                        }
                        
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
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        }
        .task {
            await checkCanPost()
        }
        .onDisappear {
            searchTask?.cancel()
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
                if self.searchQuery.trimmingCharacters(in: .whitespaces) == query {
                    searchResults = results
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
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
            }
        } catch {
            await MainActor.run {
                canPost = true
            }
        }
    }
    
    private func shareMusic(_ item: MusicItem) async {
        print("shareMusic appelé pour: \(item.title)")
        
        guard let user = authService.currentUser else {
            print("Erreur: Pas d'utilisateur connecté")
            await MainActor.run {
                errorMessage = "auth.error.not.connected".localized
            }
            return
        }
        
        guard canPost else {
            print("Erreur: Ne peut pas poster (canPost = false)")
            await MainActor.run {
                errorMessage = "share.error.already.shared".localized
            }
            return
        }
        
        print("Création du post...")
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
            print("Tentative de création du post dans Firestore...")
            try await firebaseService.createPost(post)
            print("Post créé avec succès!")
            await MainActor.run {
                searchQuery = ""
                searchResults = []
                errorMessage = ""
                canPost = false
                dismiss()
            }
        } catch {
            print("Erreur lors du partage: \(error)")
            await MainActor.run {
                errorMessage = "common.error.prefix".localized(with: error.localizedDescription)
            }
        }
    }
}
