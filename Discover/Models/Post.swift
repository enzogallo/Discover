//
//  Post.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let userPseudonym: String
    let userId: String
    let timestamp: Date
    let musicTitle: String
    let artistName: String
    let spotifyID: String
    let coverArtURL: String
    let spotifyURL: String
    let isAlbum: Bool
    
    init(id: String = UUID().uuidString, 
         userPseudonym: String, 
         userId: String,
         timestamp: Date = Date(),
         musicTitle: String,
         artistName: String,
         spotifyID: String,
         coverArtURL: String,
         spotifyURL: String,
         isAlbum: Bool) {
        self.id = id
        self.userPseudonym = userPseudonym
        self.userId = userId
        self.timestamp = timestamp
        self.musicTitle = musicTitle
        self.artistName = artistName
        self.spotifyID = spotifyID
        self.coverArtURL = coverArtURL
        self.spotifyURL = spotifyURL
        self.isAlbum = isAlbum
    }
    
    // Conversion pour Firebase
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userPseudonym": userPseudonym,
            "userId": userId,
            "timestamp": timestamp.timeIntervalSince1970,
            "musicTitle": musicTitle,
            "artistName": artistName,
            "spotifyID": spotifyID,
            "coverArtURL": coverArtURL,
            "spotifyURL": spotifyURL,
            "isAlbum": isAlbum
        ]
    }
    
    // Initialisation depuis Firebase
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userPseudonym = dictionary["userPseudonym"] as? String,
              let userId = dictionary["userId"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval,
              let musicTitle = dictionary["musicTitle"] as? String,
              let artistName = dictionary["artistName"] as? String,
              let spotifyID = dictionary["spotifyID"] as? String,
              let coverArtURL = dictionary["coverArtURL"] as? String,
              let spotifyURL = dictionary["spotifyURL"] as? String,
              let isAlbum = dictionary["isAlbum"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.userPseudonym = userPseudonym
        self.userId = userId
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.musicTitle = musicTitle
        self.artistName = artistName
        self.spotifyID = spotifyID
        self.coverArtURL = coverArtURL
        self.spotifyURL = spotifyURL
        self.isAlbum = isAlbum
    }
}


