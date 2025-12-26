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
    var currentStreak: Int
    var lastPostDate: Date?
    var longestStreak: Int

    
    init(id: String = UUID().uuidString, 
         pseudonym: String, 
         createdAt: Date = Date(), 
         profilePictureURL: String? = nil,
         currentStreak: Int = 0,
         lastPostDate: Date? = nil,
         longestStreak: Int = 0) {
        self.id = id
        self.pseudonym = pseudonym
        self.createdAt = createdAt
        self.profilePictureURL = profilePictureURL
        self.currentStreak = currentStreak
        self.lastPostDate = lastPostDate
        self.longestStreak = longestStreak
    }
    
    var activeStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastPostDate = lastPostDate else { return 0 }
        let lastPostDay = calendar.startOfDay(for: lastPostDate)
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if lastPostDay == today || lastPostDay == yesterday {
            return currentStreak
        } else {
            return 0
        }
    }
}
