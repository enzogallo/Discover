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
    @State private var selectedTab: Int = 0
    @State private var showSharePopup = false
    
    var body: some View {
        ZStack {
            // Contenu selon l'onglet sélectionné
            if selectedTab == 0 {
                FeedView(
                    authService: authService,
                    firebaseService: firebaseService,
                    spotifyService: spotifyService,
                    onParticipate: { showSharePopup = true },
                    onProfileTap: { selectedTab = 1 }
                )
            } else {
                NewProfileView(
                    authService: authService,
                    firebaseService: firebaseService,
                    spotifyService: spotifyService
                )
            }
            
            // Navigation bar en bas
            VStack {
                Spacer()
                BottomNavBar(selectedTab: $selectedTab, showSharePopup: $showSharePopup, authService: authService)
            }
        }
        .sheet(isPresented: $showSharePopup, onDismiss: {
            Task {
                // Forcer un rechargement du feed pour mettre à jour l'état Reveal
                NotificationCenter.default.post(name: NSNotification.Name("RefreshFeed"), object: nil)
            }
        }) {
            SharePopupView(
                authService: authService,
                firebaseService: firebaseService,
                spotifyService: spotifyService
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

