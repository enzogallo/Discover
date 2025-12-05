//
//  FirebaseService.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let postsCollection = "posts"
    private let usersCollection = "users"
    
    @Published var posts: [Post] = []
    
    // Vérifier si l'utilisateur peut poster (limite 24h)
    func canUserPost(userId: String) async throws -> Bool {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let timestampValue = twentyFourHoursAgo.timeIntervalSince1970
        
        let query = db.collection(postsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThan: timestampValue)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.isEmpty
    }
    
    // Créer un post
    func createPost(_ post: Post) async throws {
        // Vérifier d'abord si l'utilisateur peut poster
        let canPost = try await canUserPost(userId: post.userId)
        
        guard canPost else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Vous avez déjà partagé un morceau dans les dernières 24 heures"])
        }
        
        // Vérifier l'unicité du pseudonyme si nécessaire
        try await verifyPseudonymUniqueness(pseudonym: post.userPseudonym, userId: post.userId)
        
        // Créer le post
        try await db.collection(postsCollection).document(post.id).setData(post.toDictionary())
    }
    
    // Vérifier l'unicité du pseudonyme
    private func verifyPseudonymUniqueness(pseudonym: String, userId: String) async throws {
        let query = db.collection(usersCollection)
            .whereField("pseudonym", isEqualTo: pseudonym)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if let existingUser = snapshot.documents.first,
           existingUser.documentID != userId {
            // Si le pseudonyme existe mais appartient à un autre utilisateur
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ce pseudonyme est déjà utilisé"])
        }
        
        // Enregistrer/mettre à jour l'utilisateur
        try await db.collection(usersCollection).document(userId).setData([
            "id": userId,
            "pseudonym": pseudonym,
            "createdAt": Timestamp(date: Date())
        ])
    }
    
    // Récupérer tous les posts (feed)
    func fetchPosts(limit: Int = 100) async throws {
        let query = db.collection(postsCollection)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        self.posts = snapshot.documents.compactMap { doc in
            Post(from: doc.data())
        }
    }
    
    // Récupérer les posts d'un utilisateur
    func fetchUserPosts(userId: String) async throws -> [Post] {
        let query = db.collection(postsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            Post(from: doc.data())
        }
    }
    
    // Vérifier l'unicité du pseudonyme lors de l'authentification
    func checkPseudonymAvailability(pseudonym: String) async throws -> Bool {
        let query = db.collection(usersCollection)
            .whereField("pseudonym", isEqualTo: pseudonym)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.isEmpty
    }
    
    // Récupérer l'userId associé à un pseudonyme (pour récupérer un compte)
    func getUserIdForPseudonym(pseudonym: String) async throws -> String? {
        let query = db.collection(usersCollection)
            .whereField("pseudonym", isEqualTo: pseudonym)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.first?.documentID
    }
}
