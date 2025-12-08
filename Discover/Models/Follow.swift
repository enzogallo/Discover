//
//  Follow.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct Follow: Codable, Identifiable {
    let id: String
    let followerId: String
    let followingId: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, followerId: String, followingId: String, timestamp: Date = Date()) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.timestamp = timestamp
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "followerId": followerId,
            "followingId": followingId,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let followerId = dictionary["followerId"] as? String,
              let followingId = dictionary["followingId"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.timestamp = Date(timeIntervalSince1970: timestamp)
    }
}
