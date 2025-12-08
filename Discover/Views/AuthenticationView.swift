//
//  AuthenticationView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI
import PhotosUI

enum AuthViewState {
    case welcome
    case login
    case register
}

struct AuthenticationView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @State private var viewState: AuthViewState = .welcome
    @State private var pseudonym: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Header commun : Welcome To + Discover
                VStack(spacing: 16) {
                    Text("auth.welcome.to".localized)
                        .font(.plusJakartaSans(size: 20))
                        .foregroundColor(Color(hex: "222222"))
                    
                    Button(action: {}) {
                        Text("auth.discover".localized)
                            .font(.plusJakartaSansBold(size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color(hex: "222222"))
                            .cornerRadius(25)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Contenu selon l'état
                switch viewState {
                case .welcome:
                    welcomeView
                case .login:
                    loginView
                case .register:
                    registerView
                }
                
                Spacer()
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                    }
                }
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Button(action: {
                viewState = .login
            }) {
                Text("auth.login".localized)
                    .font(.plusJakartaSans(size: 18))
                    .foregroundColor(Color(hex: "222222"))
                    .underline()
            }
            
            Button(action: {
                viewState = .register
            }) {
                Text("auth.register".localized)
                    .font(.plusJakartaSans(size: 18))
                    .foregroundColor(Color(hex: "222222"))
                    .underline()
            }
        }
    }
    
    // MARK: - Login View
    private var loginView: some View {
        VStack(spacing: 24) {
            // Pseudo field
            VStack(alignment: .leading, spacing: 8) {
                Text("auth.pseudo".localized)
                    .font(.plusJakartaSans(size: 16))
                    .foregroundColor(Color(hex: "222222"))
                
                TextField("", text: $pseudonym)
                    .font(.plusJakartaSans(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.plusJakartaSans(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }
            
            Button(action: handleLogin) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("auth.login.button".localized)
                        .font(.plusJakartaSansSemiBold(size: 16))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isValidLogin ? Color(hex: "222222") : Color.gray)
            .cornerRadius(25)
            .disabled(!isValidLogin || isLoading)
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Register View
    private var registerView: some View {
        VStack(spacing: 24) {
            // Pseudo field
            VStack(alignment: .leading, spacing: 8) {
                Text("auth.pseudo".localized)
                    .font(.plusJakartaSans(size: 16))
                    .foregroundColor(Color(hex: "222222"))
                
                TextField("", text: $pseudonym)
                    .font(.plusJakartaSans(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            
            // Profile Picture
            VStack(alignment: .leading, spacing: 8) {
                Text("auth.profile.pic".localized)
                    .font(.plusJakartaSans(size: 16))
                    .foregroundColor(Color(hex: "222222"))
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 200, height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                        
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            Circle()
                                .stroke(Color.black, lineWidth: 1)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.plusJakartaSans(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }
            
            Button(action: handleRegister) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("auth.register.button".localized)
                        .font(.plusJakartaSansSemiBold(size: 16))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isValidRegister ? Color(hex: "222222") : Color.gray)
            .cornerRadius(25)
            .disabled(!isValidRegister || isLoading)
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Validation
    private var isValidLogin: Bool {
        !pseudonym.isEmpty
    }
    
    private var isValidRegister: Bool {
        pseudonym.count >= 3 && pseudonym.count <= 15
    }
    
    // MARK: - Handlers
    private func handleLogin() {
        guard isValidLogin else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Pour l'instant, on utilise le système existant sans vérification de mot de passe
                // TODO: Implémenter la vérification de mot de passe
                if let user = try await firebaseService.getUserByPseudonym(pseudonym: pseudonym) {
                    await MainActor.run {
                        authService.login(pseudonym: pseudonym, userId: user.id, profilePictureURL: user.profilePictureURL)
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "auth.error.user.not.found".localized
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
    
    private func handleRegister() {
        guard isValidRegister else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Vérifier si le pseudonyme existe déjà
                let isAvailable = try await firebaseService.checkPseudonymAvailability(pseudonym: pseudonym)
                
                guard isAvailable else {
                    await MainActor.run {
                        errorMessage = "auth.error.pseudonym.taken".localized
                        isLoading = false
                    }
                    return
                }
                
                // Convertir l'image en base64 si disponible
                var profilePictureURL: String? = nil
                if let profileImage = profileImage,
                   let imageData = profileImage.jpegData(compressionQuality: 0.7) {
                    profilePictureURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                }
                
                // Créer le compte
                let userId = UUID().uuidString
                
                // Créer l'utilisateur dans Firestore avec la photo de profil
                let user = User(id: userId, pseudonym: pseudonym, profilePictureURL: profilePictureURL)
                try await firebaseService.createUser(user)
                
                await MainActor.run {
                    authService.login(pseudonym: pseudonym, userId: userId, profilePictureURL: profilePictureURL)
                }
                
                await MainActor.run {
                    isLoading = false
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
