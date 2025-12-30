//
//  ImagePreloader.swift
//  Discover
//
//  Created by Enzo Gallo on 06/12/2025.
//

import Foundation
import UIKit

class ImagePreloader {
    static let shared = ImagePreloader()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Limite de 100 images en cache
    }
    
    /// Précharge une image depuis une URL
    func preloadImage(from urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        // Vérifier si l'image est déjà en cache
        if cache.object(forKey: urlString as NSString) != nil {
            return true
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return false }
            
            // Mettre en cache
            cache.setObject(image, forKey: urlString as NSString)
            return true
        } catch {
            print("Erreur lors du préchargement de l'image \(urlString): \(error)")
            return false
        }
    }
    
    /// Précharge plusieurs images en parallèle
    /// Retourne le nombre d'images chargées avec succès
    func preloadImages(from urlStrings: [String], maxConcurrent: Int = 3) async -> Int {
        var loadedCount = 0
        let urlsToLoad = Array(urlStrings.prefix(maxConcurrent))
        
        await withTaskGroup(of: Bool.self) { group in
            for urlString in urlsToLoad {
                group.addTask {
                    await self.preloadImage(from: urlString)
                }
            }
            
            for await success in group {
                if success {
                    loadedCount += 1
                }
            }
        }
        
        return loadedCount
    }
    
    /// Précharge les premières images critiques (pour le feed)
    func preloadCriticalImages(from posts: [Post], count: Int = 3) async {
        let imageURLs = Array(posts.prefix(count).map { $0.coverArtURL })
        _ = await preloadImages(from: imageURLs, maxConcurrent: min(count, 3))
    }
}

