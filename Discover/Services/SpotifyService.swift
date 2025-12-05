//
//  SpotifyService.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation
import UIKit
import Combine

class SpotifyService: ObservableObject {
    // Clé API Spotify - À remplacer par votre propre clé
    // Pour obtenir une clé gratuite : https://developer.spotify.com/dashboard
    private let clientId = "de995cfc5ebe4cd1beeee600b4edd2af"
    private let clientSecret = "657818271df24e438838085c11833082"
    private var accessToken: String?
    
    // Fonction pour obtenir un token d'accès (Client Credentials Flow)
    private func getAccessToken() async throws -> String {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur lors de l'obtention du token"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            self.accessToken = token
            return token
        }
        
        throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token non trouvé dans la réponse"])
    }
    
    // Recherche de musique
    func searchMusic(query: String) async throws -> [MusicItem] {
        let token = try await getAccessToken()
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track,album&limit=20") else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur lors de la recherche"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Réponse invalide"])
        }
        
        var results: [MusicItem] = []
        
        // Traiter les albums EN PREMIER (prioriser les albums)
        if let albums = json["albums"] as? [String: Any],
           let items = albums["items"] as? [[String: Any]] {
            for item in items {
                if let id = item["id"] as? String,
                   let name = item["name"] as? String,
                   let artists = item["artists"] as? [[String: Any]],
                   let firstArtist = artists.first,
                   let artistName = firstArtist["name"] as? String,
                   let images = item["images"] as? [[String: Any]],
                   let firstImage = images.first,
                   let imageURL = firstImage["url"] as? String,
                   let externalURLs = item["external_urls"] as? [String: Any],
                   let spotifyURL = externalURLs["spotify"] as? String {
                    
                    let musicItem = MusicItem(
                        id: id,
                        title: name,
                        artist: artistName,
                        coverArtURL: imageURL,
                        spotifyURL: spotifyURL,
                        isAlbum: true,
                        spotifyID: id
                    )
                    results.append(musicItem)
                }
            }
        }
        
        // Traiter les tracks APRÈS (singles/morceaux)
        if let tracks = json["tracks"] as? [String: Any],
           let items = tracks["items"] as? [[String: Any]] {
            for item in items {
                if let id = item["id"] as? String,
                   let name = item["name"] as? String,
                   let artists = item["artists"] as? [[String: Any]],
                   let firstArtist = artists.first,
                   let artistName = firstArtist["name"] as? String,
                   let album = item["album"] as? [String: Any],
                   let images = album["images"] as? [[String: Any]],
                   let firstImage = images.first,
                   let imageURL = firstImage["url"] as? String,
                   let externalURLs = item["external_urls"] as? [String: Any],
                   let spotifyURL = externalURLs["spotify"] as? String {
                    
                    let musicItem = MusicItem(
                        id: id,
                        title: name,
                        artist: artistName,
                        coverArtURL: imageURL,
                        spotifyURL: spotifyURL,
                        isAlbum: false,
                        spotifyID: id
                    )
                    results.append(musicItem)
                }
            }
        }
        
        return results
    }
    
    // Ouvrir dans Spotify
    func openInSpotify(spotifyURL: String) {
        // Convertir l'URL web Spotify en URL scheme
        // Format web: https://open.spotify.com/album/ID ou https://open.spotify.com/track/ID
        // Format scheme: spotify:album:ID ou spotify:track:ID
        
        var spotifySchemeURL: String?
        
        if spotifyURL.contains("open.spotify.com/album/") {
            // C'est un album
            if let albumID = spotifyURL.components(separatedBy: "album/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:album:\(albumID)"
            }
        } else if spotifyURL.contains("open.spotify.com/track/") {
            // C'est un morceau
            if let trackID = spotifyURL.components(separatedBy: "track/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:track:\(trackID)"
            }
        } else if spotifyURL.contains("open.spotify.com/artist/") {
            // C'est un artiste
            if let artistID = spotifyURL.components(separatedBy: "artist/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:artist:\(artistID)"
            }
        }
        
        // Essayer d'abord avec l'URL scheme de Spotify
        if let schemeURL = spotifySchemeURL, let url = URL(string: schemeURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if !success {
                        // Si l'URL scheme échoue, ouvrir dans le navigateur
                        if let webURL = URL(string: spotifyURL) {
                            UIApplication.shared.open(webURL)
                        }
                    }
                })
                return
            }
        }
        
        // Sinon, ouvrir dans le navigateur (ou l'app Spotify via l'URL web)
        if let url = URL(string: spotifyURL) {
            UIApplication.shared.open(url)
        }
    }
}
