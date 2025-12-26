//
//  AuthService.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation
import SwiftUI
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let userIdKey = "discover_user_id"
    private let pseudonymKey = "discover_pseudonym"
    
    init() {
        loadUser()
    }
    
    func loadUser() {
        if let userId = userDefaults.string(forKey: userIdKey),
           let pseudonym = userDefaults.string(forKey: pseudonymKey) {
            // Charger l'utilisateur de base (sans photo de profil pour l'instant)
            // La photo sera chargée depuis Firestore si nécessaire
            self.currentUser = User(id: userId, pseudonym: pseudonym)
            self.isAuthenticated = true
        }
    }
    
    // Charger l'utilisateur complet depuis Firestore (avec photo de profil)
    func loadUserFromFirestore(firebaseService: FirebaseService) async {
        guard let userId = userDefaults.string(forKey: userIdKey) else { return }
        
        do {
            if let user = try await firebaseService.getUserById(userId: userId) {
                await MainActor.run {
                    self.currentUser = user
                }
            }
        } catch {
            print("Erreur lors du chargement de l'utilisateur depuis Firestore: \(error)")
        }
    }
    
    func login(pseudonym: String, userId: String? = nil, profilePictureURL: String? = nil) {
        let finalUserId: String
        if let providedUserId = userId {
            // Utiliser l'userId fourni (récupération de compte)
            finalUserId = providedUserId
            userDefaults.set(finalUserId, forKey: userIdKey)
        } else if let existingUserId = userDefaults.string(forKey: userIdKey) {
            // Utiliser l'userId existant sur cet appareil
            finalUserId = existingUserId
        } else {
            // Créer un nouvel userId
            finalUserId = UUID().uuidString
            userDefaults.set(finalUserId, forKey: userIdKey)
        }
        
        userDefaults.set(pseudonym, forKey: pseudonymKey)
        
        self.currentUser = User(id: finalUserId, pseudonym: pseudonym, profilePictureURL: profilePictureURL)
        self.isAuthenticated = true
    }
    
    func updateLocalUser(pseudonym: String, profilePictureURL: String?) {
        userDefaults.set(pseudonym, forKey: pseudonymKey)
        
        if var updatedUser = currentUser {
            updatedUser = User(
                id: updatedUser.id,
                pseudonym: pseudonym,
                createdAt: updatedUser.createdAt,
                profilePictureURL: profilePictureURL ?? updatedUser.profilePictureURL,
                currentStreak: updatedUser.currentStreak,
                lastPostDate: updatedUser.lastPostDate,
                longestStreak: updatedUser.longestStreak
            )
            self.currentUser = updatedUser
        }
    }
    
    func logout() {
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: pseudonymKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
