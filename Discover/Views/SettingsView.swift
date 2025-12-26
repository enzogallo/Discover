//
//  SettingsView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header avec Discover et Paramètres
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("settings.discover".localized)
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
                        
                        Text("settings.title".localized)
                            .font(.plusJakartaSansSemiBold(size: 17))
                            .foregroundColor(.themePrimaryText)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                    
                    // Contenu
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile Section (Keep as Card)
                            NavigationLink(destination: EditProfileView(authService: authService, firebaseService: firebaseService)) {
                                HStack(spacing: 16) {
                                    if let profileURL = authService.currentUser?.profilePictureURL,
                                       let data = Data(base64Encoded: profileURL.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                                       let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(authService.currentUser?.pseudonym ?? "")
                                            .font(.plusJakartaSansBold(size: 18))
                                            .foregroundColor(.themePrimaryText)
                                        
                                        Text("settings.edit.profile".localized)
                                            .font(.plusJakartaSansMedium(size: 14))
                                            .foregroundColor(.themePrimaryText.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.themePrimaryText.opacity(0.3))
                                }
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                            }

                            // Spotify Connection (Back to List style with more vertical space)
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(spotifyService.isUserAuthenticated ? Color.init(red: 29/255, green: 185/255, blue: 84/255) : Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .foregroundColor(spotifyService.isUserAuthenticated ? .white : .themePrimaryText.opacity(0.5))
                                                .font(.system(size: 18, weight: .medium))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        if spotifyService.isUserAuthenticated {
                                            Text("spotify.connected.as".localized(with: spotifyService.spotifyUserName ?? "User"))
                                                .font(.plusJakartaSansBold(size: 16))
                                                .foregroundColor(.themePrimaryText)
                                            
                                            Button(action: {
                                                spotifyService.logout()
                                            }) {
                                                Text("spotify.disconnect".localized)
                                                    .font(.plusJakartaSansMedium(size: 14))
                                                    .foregroundColor(.red)
                                            }
                                        } else {
                                            Text("spotify.connect".localized)
                                                .font(.plusJakartaSansBold(size: 16))
                                                .foregroundColor(.themePrimaryText)
                                            
                                            Button(action: {
                                                spotifyService.login()
                                            }) {
                                                Text("auth.login".localized)
                                                    .font(.plusJakartaSansMedium(size: 14))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 40)

                            // Supprimer le compte (Back to List style)
                            HStack(spacing: 16) {
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "trash")
                                                .foregroundColor(.themePrimaryText.opacity(0.5))
                                                .font(.system(size: 18, weight: .medium))
                                        )
                                }
                                
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Text("settings.delete.account".localized)
                                        .font(.plusJakartaSansMedium(size: 16))
                                        .foregroundColor(.themePrimaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                        }
                    }
                    
                    Spacer()
                    
                    // Déconnexion
                    Button(action: {
                        spotifyService.logout()
                        authService.logout()
                        dismiss()
                    }) {
                        Text("settings.logout".localized)
                            .font(.plusJakartaSansSemiBold(size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("settings.delete.confirmation.title".localized, isPresented: $showDeleteConfirmation) {
            Button("settings.delete.confirmation.cancel".localized, role: .cancel) {}
            Button("settings.delete.confirmation.delete".localized, role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("settings.delete.confirmation.message".localized)
        }
    }
    
    private func deleteAccount() async {
        guard let userId = authService.currentUser?.id else { return }
        
        await MainActor.run {
            isDeleting = true
        }
        
        do {
            try await firebaseService.deleteUserData(userId: userId)
            await MainActor.run {
                spotifyService.logout()
                authService.logout()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDeleting = false
                print("Erreur lors de la suppression: \(error.localizedDescription)")
                // Afficher une alerte d'erreur à l'utilisateur
            }
        }
    }
}
