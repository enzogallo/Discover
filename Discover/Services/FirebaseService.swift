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
    
    // Vérifier si l'utilisateur a posté aujourd'hui (depuis minuit local)
    func hasUserPostedToday(userId: String) async throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let timestampValue = startOfDay.timeIntervalSince1970
        
        let query = db.collection(postsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: timestampValue)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    // Vérifier si l'utilisateur peut poster (limite une fois par jour calendaire)
    func canUserPost(userId: String) async throws -> Bool {
        return try await !hasUserPostedToday(userId: userId)
    }
    
    // Créer un post
    func createPost(_ post: Post) async throws {
        // Vérifier d'abord si l'utilisateur peut poster
        let canPost = try await canUserPost(userId: post.userId)
        
        guard canPost else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "share.error.already.shared".localized])
        }
        
        // Vérifier l'unicité du pseudonyme si nécessaire
        try await verifyPseudonymUniqueness(pseudonym: post.userPseudonym, userId: post.userId)
        
        // Créer le post
        try await db.collection(postsCollection).document(post.id).setData(post.toDictionary())
        
        // Mettre à jour la streak de l'utilisateur
        try await updateUserStreak(userId: post.userId)
    }
    
    private func updateUserStreak(userId: String) async throws {
        guard var user = try await getUserById(userId: userId) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastPostDate = user.lastPostDate {
            let lastPostDay = calendar.startOfDay(for: lastPostDate)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            if lastPostDay == yesterday {
                // Streak continue
                user.currentStreak += 1
            } else if lastPostDay < yesterday {
                // Streak brisée
                user.currentStreak = 1
            } else if lastPostDay == today {
                // Déjà posté aujourd'hui, la streak a déjà été incrémentée ou est à jour
                // On ne fait rien pour ne pas incrémenter plusieurs fois par jour
                return 
            }
        } else {
            // Première fois qu'on poste
            user.currentStreak = 1
        }
        
        user.lastPostDate = Date()
        if user.currentStreak > user.longestStreak {
            user.longestStreak = user.currentStreak
        }
        
        try await createUser(user)
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
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "auth.error.pseudonym.taken".localized])
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
    
    // Mettre à jour le profil utilisateur
    func updateUserProfile(userId: String, newPseudonym: String, newProfilePictureURL: String?) async throws {
        // Si le pseudo a changé, vérifier son unicité
        let currentUser = try await getUserById(userId: userId)
        if let currentPseudo = currentUser?.pseudonym, currentPseudo != newPseudonym {
            let isAvailable = try await checkPseudonymAvailability(pseudonym: newPseudonym)
            if !isAvailable {
                throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "auth.error.pseudonym.taken".localized])
            }
        }
        
        var updateData: [String: Any] = [
            "pseudonym": newPseudonym
        ]
        
        if let profilePictureURL = newProfilePictureURL {
            updateData["profilePictureURL"] = profilePictureURL
        }
        
        try await db.collection(usersCollection).document(userId).updateData(updateData)
    }
    
    // Récupérer l'userId associé à un pseudonyme (pour récupérer un compte)
    func getUserIdForPseudonym(pseudonym: String) async throws -> String? {
        let query = db.collection(usersCollection)
            .whereField("pseudonym", isEqualTo: pseudonym)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.first?.documentID
    }
    
    // Récupérer un utilisateur par son pseudonyme
    func getUserByPseudonym(pseudonym: String) async throws -> User? {
        let query = db.collection(usersCollection)
            .whereField("pseudonym", isEqualTo: pseudonym)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        
        let data = doc.data()
        let userId = doc.documentID
        let pseudonym = data["pseudonym"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let profilePictureURL = data["profilePictureURL"] as? String
        
        let currentStreak = data["currentStreak"] as? Int ?? 0
        let lastPostDate = (data["lastPostDate"] as? Timestamp)?.dateValue()
        let longestStreak = data["longestStreak"] as? Int ?? 0
        
        return User(
            id: userId, 
            pseudonym: pseudonym, 
            createdAt: createdAt, 
            profilePictureURL: profilePictureURL,
            currentStreak: currentStreak,
            lastPostDate: lastPostDate,
            longestStreak: longestStreak
        )

    }
    
    // Récupérer un utilisateur par son ID
    func getUserById(userId: String) async throws -> User? {
        let doc = try await db.collection(usersCollection).document(userId).getDocument()
        
        guard doc.exists, let data = doc.data() else { return nil }
        
        let pseudonym = data["pseudonym"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let profilePictureURL = data["profilePictureURL"] as? String
        
        let currentStreak = data["currentStreak"] as? Int ?? 0
        let lastPostDate = (data["lastPostDate"] as? Timestamp)?.dateValue()
        let longestStreak = data["longestStreak"] as? Int ?? 0
        
        return User(
            id: userId, 
            pseudonym: pseudonym, 
            createdAt: createdAt, 
            profilePictureURL: profilePictureURL,
            currentStreak: currentStreak,
            lastPostDate: lastPostDate,
            longestStreak: longestStreak
        )

    }
    
    // Créer un utilisateur
    func createUser(_ user: User) async throws {
        var userDict: [String: Any] = [
            "pseudonym": user.pseudonym,
            "createdAt": Timestamp(date: user.createdAt),
            "currentStreak": user.currentStreak,
            "longestStreak": user.longestStreak
        ]
        
        if let profilePictureURL = user.profilePictureURL {
            userDict["profilePictureURL"] = profilePictureURL
        }
        
        if let lastPostDate = user.lastPostDate {
            userDict["lastPostDate"] = Timestamp(date: lastPostDate)
        }

        
        try await db.collection(usersCollection).document(user.id).setData(userDict)
    }
    
    // MARK: - Likes
    private let likesCollection = "likes"
    
    func toggleLike(postId: String, userId: String) async throws -> Bool {
        let query = db.collection(likesCollection)
            .whereField("postId", isEqualTo: postId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if let existingLike = snapshot.documents.first {
            try await db.collection(likesCollection).document(existingLike.documentID).delete()
            return false
        } else {
            let like = Like(userId: userId, postId: postId)
            try await db.collection(likesCollection).document(like.id).setData(like.toDictionary())
            return true
        }
    }
    
    func getLikeCount(postId: String) async throws -> Int {
        let query = db.collection(likesCollection)
            .whereField("postId", isEqualTo: postId)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.count
    }
    
    func isLiked(postId: String, userId: String) async throws -> Bool {
        let query = db.collection(likesCollection)
            .whereField("postId", isEqualTo: postId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Comments
    private let commentsCollection = "comments"
    
    func addComment(_ comment: Comment) async throws {
        try await db.collection(commentsCollection).document(comment.id).setData(comment.toDictionary())
    }
    
    func fetchComments(postId: String) async throws -> [Comment] {
        let query = db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
            .order(by: "timestamp", descending: false)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            Comment(from: doc.data())
        }
    }
    
    func getCommentCount(postId: String) async throws -> Int {
        let query = db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.count
    }
    
    // MARK: - Follows
    private let followsCollection = "follows"
    
    func followUser(followerId: String, followingId: String) async throws {
        let query = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if snapshot.documents.isEmpty {
            let follow = Follow(followerId: followerId, followingId: followingId)
            try await db.collection(followsCollection).document(follow.id).setData(follow.toDictionary())
        }
    }
    
    func unfollowUser(followerId: String, followingId: String) async throws {
        let query = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if let followDoc = snapshot.documents.first {
            try await db.collection(followsCollection).document(followDoc.documentID).delete()
        }
    }
    
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        let query = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    func getFollowerCount(userId: String) async throws -> Int {
        let query = db.collection(followsCollection)
            .whereField("followingId", isEqualTo: userId)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.count
    }
    
    func getFollowingCount(userId: String) async throws -> Int {
        let query = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: userId)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.count
    }
    
    // MARK: - Delete User Data
    func deleteUserData(userId: String) async throws {
        // Supprimer tous les posts de l'utilisateur
        let postsQuery = db.collection(postsCollection)
            .whereField("userId", isEqualTo: userId)
        
        let postsSnapshot = try await postsQuery.getDocuments()
        for postDoc in postsSnapshot.documents {
            let postId = postDoc.documentID
            
            // Supprimer les likes associés
            let likesQuery = db.collection(likesCollection)
                .whereField("postId", isEqualTo: postId)
            let likesSnapshot = try await likesQuery.getDocuments()
            for likeDoc in likesSnapshot.documents {
                try await db.collection(likesCollection).document(likeDoc.documentID).delete()
            }
            
            // Supprimer les commentaires associés
            let commentsQuery = db.collection(commentsCollection)
                .whereField("postId", isEqualTo: postId)
            let commentsSnapshot = try await commentsQuery.getDocuments()
            for commentDoc in commentsSnapshot.documents {
                try await db.collection(commentsCollection).document(commentDoc.documentID).delete()
            }
            
            // Supprimer le post
            try await db.collection(postsCollection).document(postId).delete()
        }
        
        // Supprimer les follows
        let followsQuery = db.collection(followsCollection)
            .whereField("followerId", isEqualTo: userId)
        let followsSnapshot = try await followsQuery.getDocuments()
        for followDoc in followsSnapshot.documents {
            try await db.collection(followsCollection).document(followDoc.documentID).delete()
        }
        
        let followingQuery = db.collection(followsCollection)
            .whereField("followingId", isEqualTo: userId)
        let followingSnapshot = try await followingQuery.getDocuments()
        for followDoc in followingSnapshot.documents {
            try await db.collection(followsCollection).document(followDoc.documentID).delete()
        }
        
        // Supprimer les likes de l'utilisateur
        let userLikesQuery = db.collection(likesCollection)
            .whereField("userId", isEqualTo: userId)
        let userLikesSnapshot = try await userLikesQuery.getDocuments()
        for likeDoc in userLikesSnapshot.documents {
            try await db.collection(likesCollection).document(likeDoc.documentID).delete()
        }
        
        // Supprimer les commentaires de l'utilisateur
        let userCommentsQuery = db.collection(commentsCollection)
            .whereField("userId", isEqualTo: userId)
        let userCommentsSnapshot = try await userCommentsQuery.getDocuments()
        for commentDoc in userCommentsSnapshot.documents {
            try await db.collection(commentsCollection).document(commentDoc.documentID).delete()
        }
        
        // Supprimer l'utilisateur
        try await db.collection(usersCollection).document(userId).delete()
    }
    
    // Supprimer un post
    func deletePost(postId: String, userId: String) async throws {
        // Vérifier que le post appartient bien à l'utilisateur
        let postDoc = try await db.collection(postsCollection).document(postId).getDocument()
        guard let postData = postDoc.data(),
              let postUserId = postData["userId"] as? String,
              postUserId == userId else {
            throw NSError(domain: "FirebaseService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        // Supprimer les likes du post
        let likesQuery = db.collection(likesCollection).whereField("postId", isEqualTo: postId)
        let likesSnapshot = try await likesQuery.getDocuments()
        for likeDoc in likesSnapshot.documents {
            try await db.collection(likesCollection).document(likeDoc.documentID).delete()
        }
        
        // Supprimer les commentaires du post
        let commentsQuery = db.collection(commentsCollection).whereField("postId", isEqualTo: postId)
        let commentsSnapshot = try await commentsQuery.getDocuments()
        for commentDoc in commentsSnapshot.documents {
            try await db.collection(commentsCollection).document(commentDoc.documentID).delete()
        }
        
        // Supprimer le post
        try await db.collection(postsCollection).document(postId).delete()
        
        // Retirer le post de la liste locale
        posts.removeAll { $0.id == postId }
    }
}
