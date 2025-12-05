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
    
    init(id: String = UUID().uuidString, pseudonym: String, createdAt: Date = Date()) {
        self.id = id
        self.pseudonym = pseudonym
        self.createdAt = createdAt
    }
}
