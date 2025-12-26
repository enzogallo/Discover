//
//  DeezerService.swift
//  Discover
//
//  Created by Enzo Gallo on 26/12/2025.
//

import Foundation

class DeezerService {
    static let shared = DeezerService()
    
    private init() {}
    
    // Chercher un extrait audio via l'API Deezer
    func findPreview(artist: String, title: String) async -> String? {
        // Nettoyer les termes de recherche pour maximiser les chances (enlever "feat.", "(Radio Edit)", etc)
        let cleanArtist = sanitize(artist)
        let cleanTitle = sanitize(title)
        
        // Construire la requête
        let query = "\(cleanArtist) \(cleanTitle)"
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.deezer.com/search?q=\(encodedQuery)&limit=1") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]],
               let firstHit = dataArray.first,
               let previewURL = firstHit["preview"] as? String {
                
                print("✅ Deezer Bridge: Extrait trouvé pour '\(title)'")
                return previewURL
            }
        } catch {
            print("❌ Deezer Bridge Error: \(error)")
        }
        
        print("⚠️ Deezer Bridge: Aucun extrait trouvé pour '\(title)'")
        return nil
    }
    
    private func sanitize(_ text: String) -> String {
        // Enleve les parenthèses et ce qu'il y a dedans souvent inutile pour la recherche (ex: "(feat. X)")
        // Ce regex est basique mais couvre 80% des cas
        let textWithoutParentheses = text.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
        return textWithoutParentheses
    }
}
