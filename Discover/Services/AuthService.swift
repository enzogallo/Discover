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
            self.currentUser = User(id: userId, pseudonym: pseudonym)
            self.isAuthenticated = true
        }
    }
    
    func login(pseudonym: String, userId: String? = nil) {
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
        
        self.currentUser = User(id: finalUserId, pseudonym: pseudonym)
        self.isAuthenticated = true
    }
    
    func logout() {
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: pseudonymKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
