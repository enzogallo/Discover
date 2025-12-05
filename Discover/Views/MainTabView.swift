//
//  MainTabView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    
    var body: some View {
        TabView {
            FeedView(firebaseService: firebaseService, spotifyService: spotifyService)
                .tabItem {
                    Label("Découvrir", systemImage: "music.note.list")
                }
            
            ShareView(
                authService: authService,
                firebaseService: firebaseService,
                spotifyService: spotifyService
            )
                .tabItem {
                    Label("Partager", systemImage: "plus.circle")
                }
            
            ProfileView(
                authService: authService,
                firebaseService: firebaseService
            )
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}
