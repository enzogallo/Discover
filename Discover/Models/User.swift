//
//  User.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let pseudonym: String
    let createdAt: Date
    var profilePictureURL: String?
    
    init(id: String = UUID().uuidString, pseudonym: String, createdAt: Date = Date(), profilePictureURL: String? = nil) {
        self.id = id
        self.pseudonym = pseudonym
        self.createdAt = createdAt
        self.profilePictureURL = profilePictureURL
    }
}
