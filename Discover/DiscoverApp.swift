//
//  DiscoverApp.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI
import FirebaseCore

@main
struct DiscoverApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var firebaseService = FirebaseService()
    @StateObject private var spotifyService = SpotifyService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView(
                    authService: authService,
                    firebaseService: firebaseService,
                    spotifyService: spotifyService
                )
                .task {
                    // Charger la photo de profil depuis Firestore au démarrage
                    await authService.loadUserFromFirestore(firebaseService: firebaseService)
                }
            } else {
                AuthenticationView(
                    authService: authService,
                    firebaseService: firebaseService
                )
            }
        }
    }
}
