//
//  AuthenticationView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var pseudonym: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo ou titre
            VStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Discover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Partagez votre musique")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Formulaire
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pseudonyme")
                        .font(.headline)
                    
                    TextField("Entre 3 et 15 caractères", text: $pseudonym)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continuer")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidPseudonym ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isValidPseudonym || isLoading)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    private var isValidPseudonym: Bool {
        pseudonym.count >= 3 && pseudonym.count <= 15
    }
    
    private func handleLogin() {
        guard isValidPseudonym else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Si c'est le même pseudonyme que l'utilisateur actuel, on le laisse continuer
                if authService.currentUser?.pseudonym == pseudonym {
                    await MainActor.run {
                        authService.login(pseudonym: pseudonym)
                        isLoading = false
                    }
                    return
                }
                
                // Vérifier si le pseudonyme existe déjà
                if let existingUserId = try await firebaseService.getUserIdForPseudonym(pseudonym: pseudonym) {
                    // Le pseudonyme existe, on récupère le compte associé
                    await MainActor.run {
                        authService.login(pseudonym: pseudonym, userId: existingUserId)
                        isLoading = false
                    }
                } else {
                    // Le pseudonyme est disponible, on crée un nouveau compte
                    await MainActor.run {
                        authService.login(pseudonym: pseudonym)
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
