//
//  MusicItem.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation

struct MusicItem: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let coverArtURL: String
    let spotifyURL: String
    let isAlbum: Bool
    let spotifyID: String
    
    init(id: String, title: String, artist: String, coverArtURL: String, spotifyURL: String, isAlbum: Bool, spotifyID: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverArtURL = coverArtURL
        self.spotifyURL = spotifyURL
        self.isAlbum = isAlbum
        self.spotifyID = spotifyID
    }
}
