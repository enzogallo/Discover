//
//  EditProfileView.swift
//  Discover
//
//  Created by Enzo Gallo on 26/12/2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    
    @State private var pseudonym: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var isLoading: Bool = false
    
    init(authService: AuthService, firebaseService: FirebaseService) {
        self.authService = authService
        self.firebaseService = firebaseService
        _pseudonym = State(initialValue: authService.currentUser?.pseudonym ?? "")
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.themePrimaryText)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text("edit.profile.title".localized)
                        .font(.plusJakartaSansBold(size: 18))
                        .foregroundColor(.themePrimaryText)
                    
                    Spacer()
                    
                    // Empty space for balance
                    Color.clear.frame(width: 40, height: 40)
                        .padding(.trailing, 16)
                }
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Picture Section
                        VStack(spacing: 16) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    if let profileImage = profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 140, height: 140)
                                            .clipShape(Circle())
                                    } else if let profileURL = authService.currentUser?.profilePictureURL,
                                              let data = Data(base64Encoded: profileURL.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                                              let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 140, height: 140)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 140, height: 140)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            )
                                    }
                                    
                                    // Camera Overlay
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(Color.discoverBlack)
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.white)
                                                )
                                                .offset(x: -5, y: -5)
                                        }
                                    }
                                }
                                .frame(width: 140, height: 140)
                            }
                            
                            Text("auth.profile.pic".localized)
                                .font(.plusJakartaSansSemiBold(size: 14))
                                .foregroundColor(.themePrimaryText.opacity(0.6))
                        }
                        .padding(.top, 40)
                        
                        // Pseudonym Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("auth.pseudonym".localized)
                                .font(.plusJakartaSansBold(size: 16))
                                .foregroundColor(.themePrimaryText)
                            
                            TextField("auth.pseudonym.placeholder".localized, text: $pseudonym)
                                .font(.plusJakartaSans(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.themePrimaryText.opacity(0.1), lineWidth: 1)
                                )
                                .cornerRadius(16)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, 24)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.plusJakartaSans(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !successMessage.isEmpty {
                            Text(successMessage)
                                .font(.plusJakartaSans(size: 14))
                                .foregroundColor(.green)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        // Save Button
                        Button(action: handleSave) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("edit.profile.save".localized)
                                    .font(.plusJakartaSansBold(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.themePrimaryText : Color.gray.opacity(0.3))
                        .cornerRadius(30)
                        .disabled(!isValid || isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedPhoto) { oldValue, newItem in
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
    
    private var isValid: Bool {
        pseudonym.count >= 3 && pseudonym.count <= 15
    }
    
    private func handleSave() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                var profilePictureURL: String? = nil
                if let profileImage = profileImage,
                   let imageData = profileImage.jpegData(compressionQuality: 0.6) {
                    profilePictureURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                }
                
                try await firebaseService.updateUserProfile(
                    userId: userId,
                    newPseudonym: pseudonym,
                    newProfilePictureURL: profilePictureURL
                )
                
                await MainActor.run {
                    authService.updateLocalUser(pseudonym: pseudonym, profilePictureURL: profilePictureURL)
                    successMessage = "edit.profile.success".localized
                    isLoading = false
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
