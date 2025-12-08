//
//  Like.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct Like: Codable, Identifiable {
    let id: String
    let userId: String
    let postId: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, userId: String, postId: String, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.postId = postId
        self.timestamp = timestamp
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "postId": postId,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let postId = dictionary["postId"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.postId = postId
        self.timestamp = Date(timeIntervalSince1970: timestamp)
    }
}
