//
//  Comment.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let userPseudonym: String
    let postId: String
    let text: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, 
         userId: String, 
         userPseudonym: String,
         postId: String, 
         text: String, 
         timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userPseudonym = userPseudonym
        self.postId = postId
        self.text = text
        self.timestamp = timestamp
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "userPseudonym": userPseudonym,
            "postId": postId,
            "text": text,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let userPseudonym = dictionary["userPseudonym"] as? String,
              let postId = dictionary["postId"] as? String,
              let text = dictionary["text"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.userPseudonym = userPseudonym
        self.postId = postId
        self.text = text
        self.timestamp = Date(timeIntervalSince1970: timestamp)
    }
}
