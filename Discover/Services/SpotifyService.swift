//
//  SpotifyService.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import Foundation
import UIKit
import Combine
import AuthenticationServices

class SpotifyService: NSObject, ObservableObject {
    // Clé API Spotify - À remplacer par votre propre clé
    // Pour obtenir une clé gratuite : https://developer.spotify.com/dashboard
    private let clientId = "de995cfc5ebe4cd1beeee600b4edd2af"
    private let clientSecret = "657818271df24e438838085c11833082"
    private let redirectURI = "discover-app://spotify-login"
    
    @Published var isUserAuthenticated: Bool = false
    @Published var spotifyUserName: String?
    
    private var accessToken: String?
    private var userAccessToken: String?
    private var refreshToken: String?
    private var tokenExpirationDate: Date?
    
    private let userDefaults = UserDefaults.standard
    private let userAccessTokenKey = "spotify_user_access_token"
    private let refreshTokenKey = "spotify_user_refresh_token"
    private let tokenExpirationKey = "spotify_token_expiration"
    private let spotifyUserNameKey = "spotify_user_name"
    
    override init() {
        super.init()
        loadTokens()
    }
    
    private func loadTokens() {
        if let token = userDefaults.string(forKey: userAccessTokenKey),
           let expiration = userDefaults.object(forKey: tokenExpirationKey) as? Date {
            self.userAccessToken = token
            self.refreshToken = userDefaults.string(forKey: refreshTokenKey)
            self.tokenExpirationDate = expiration
            self.spotifyUserName = userDefaults.string(forKey: spotifyUserNameKey)
            self.isUserAuthenticated = true
        }
    }
    
    private func saveTokens(accessToken: String, refreshToken: String?, expiresIn: Int) {
        self.userAccessToken = accessToken
        if let refresh = refreshToken {
            self.refreshToken = refresh
            userDefaults.set(refresh, forKey: refreshTokenKey)
        }
        
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        self.tokenExpirationDate = expirationDate
        
        userDefaults.set(accessToken, forKey: userAccessTokenKey)
        userDefaults.set(expirationDate, forKey: tokenExpirationKey)
        
        self.isUserAuthenticated = true
    }
    
    func logout() {
        userAccessToken = nil
        refreshToken = nil
        tokenExpirationDate = nil
        spotifyUserName = nil
        isUserAuthenticated = false
        
        userDefaults.removeObject(forKey: userAccessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: tokenExpirationKey)
        userDefaults.removeObject(forKey: spotifyUserNameKey)
    }
    
    // MARK: - Authentication
    
    func login() {
        let scopes = "user-modify-playback-state user-read-private"
        let authURLString = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(clientId)&scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
        
        guard let authURL = URL(string: authURLString) else { return }
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "discover-app") { [weak self] callbackURL, error in
            guard error == nil, let callbackURL = callbackURL else { return }
            
            if let code = URLComponents(string: callbackURL.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
                Task {
                    try? await self?.exchangeCodeForToken(code: code)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let access = json["access_token"] as? String,
           let refresh = json["refresh_token"] as? String,
           let expires = json["expires_in"] as? Int {
            
            await MainActor.run {
                saveTokens(accessToken: access, refreshToken: refresh, expiresIn: expires)
                Task {
                    await fetchUserProfile()
                }
            }
        }
    }
    
    private func refreshAccessToken() async throws -> String {
        guard let refresh = refreshToken else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Pas de refresh token"])
        }
        
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=refresh_token&refresh_token=\(refresh)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur refresh"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let access = json["access_token"] as? String,
           let expires = json["expires_in"] as? Int {
            
            let newRefresh = json["refresh_token"] as? String
            await MainActor.run {
                saveTokens(accessToken: access, refreshToken: newRefresh, expiresIn: expires)
            }
            return access
        }
        
        throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Parsing error"])
    }
    
    private func getValidUserToken() async throws -> String {
        if let expiration = tokenExpirationDate, expiration > Date().addingTimeInterval(60), let token = userAccessToken {
            return token
        }
        return try await refreshAccessToken()
    }
    
    private func fetchUserProfile() async {
        do {
            let token = try await getValidUserToken()
            guard let url = URL(string: "https://api.spotify.com/v1/me") else { return }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["display_name"] as? String {
                await MainActor.run {
                    self.spotifyUserName = name
                    userDefaults.set(name, forKey: spotifyUserNameKey)
                }
            }
        } catch {
            print("Erreur fetch profile: \(error)")
        }
    }
    
    // MARK: - Music Logic
    
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
    
    // MARK: - Queue API
    
    func addToQueue(spotifyID: String, isAlbum: Bool) async throws {
        print("Spotify: addToQueue called for \(isAlbum ? "album" : "track") with ID: \(spotifyID)")
        
        if spotifyID.isEmpty {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Spotify ID is empty"])
        }
        
        let token = try await getValidUserToken()
        
        var trackURIs: [String] = []
        
        if isAlbum {
            trackURIs = try await getAlbumTracks(albumID: spotifyID)
        } else {
            trackURIs = ["spotify:track:\(spotifyID)"]
        }
        
        guard let firstTrack = trackURIs.first else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No tracks found for this album"])
        }
        
        print("Spotify: Adding track to queue: \(firstTrack)")
        
        // Ensure the URI is URL encoded
        guard let encodedURI = firstTrack.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/me/player/queue?uri=\(encodedURI)") else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Queue URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Spotify"])
        }
        
        print("Spotify: Queue Status: \(httpResponse.statusCode)")
        
        if !(200...204).contains(httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("Spotify: Queue Error Body: \(errorBody)")
            
            if httpResponse.statusCode == 404 {
                throw NSError(domain: "SpotifyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "spotify.error.no.device".localized])
            }
            
            if httpResponse.statusCode == 403 {
                // Determine the reason for 403
                if errorBody.contains("user may not be registered") || errorBody.contains("not_registered") {
                    throw NSError(domain: "SpotifyService", code: 403, userInfo: [NSLocalizedDescriptionKey: "spotify.error.user.not.registered".localized])
                } else {
                    throw NSError(domain: "SpotifyService", code: 403, userInfo: [NSLocalizedDescriptionKey: "spotify.error.premium.required".localized])
                }
            }
            
            throw NSError(domain: "SpotifyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Spotify API Error: \(httpResponse.statusCode)"])
        }
    }
    
    private func getAlbumTracks(albumID: String) async throws -> [String] {
        print("Spotify: Fetching tracks for album ID: \(albumID)")
        
        // Use application token (client credentials) for public metadata
        // this avoids 403 errors if the current user is not registered in the Spotify Developer Dashboard (Development mode)
        let token = try await getAccessToken()
        
        guard let url = URL(string: "https://api.spotify.com/v1/albums/\(albumID)/tracks?limit=1") else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Album tracks URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SpotifyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response for album tracks"])
        }
        
        print("Spotify: Album Tracks Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("Spotify: Album Tracks Error: \(errorBody)")
            throw NSError(domain: "SpotifyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Spotify API Error \(httpResponse.statusCode) while fetching album tracks"])
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = json["items"] as? [[String: Any]] {
            let uris = items.compactMap { $0["uri"] as? String }
            if uris.isEmpty {
                print("Spotify: Album tracks list is empty for album \(albumID)")
            } else {
                print("Spotify: Found \(uris.count) tracks for album \(albumID)")
            }
            return uris
        }
        
        print("Spotify: Failed to parse album tracks JSON for album \(albumID)")
        return []
    }
    
    func openInSpotify(spotifyURL: String) {
        var spotifySchemeURL: String?
        
        if spotifyURL.contains("open.spotify.com/album/") {
            if let albumID = spotifyURL.components(separatedBy: "album/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:album:\(albumID)"
            }
        } else if spotifyURL.contains("open.spotify.com/track/") {
            if let trackID = spotifyURL.components(separatedBy: "track/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:track:\(trackID)"
            }
        } else if spotifyURL.contains("open.spotify.com/artist/") {
            if let artistID = spotifyURL.components(separatedBy: "artist/").last?.components(separatedBy: "?").first {
                spotifySchemeURL = "spotify:artist:\(artistID)"
            }
        }
        
        if let schemeURL = spotifySchemeURL, let url = URL(string: schemeURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if !success {
                        if let webURL = URL(string: spotifyURL) {
                            UIApplication.shared.open(webURL)
                        }
                    }
                })
                return
            }
        }
        
        if let url = URL(string: spotifyURL) {
            UIApplication.shared.open(url)
        }
    }
}

extension SpotifyService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

