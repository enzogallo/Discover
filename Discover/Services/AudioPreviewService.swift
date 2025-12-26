//
//  AudioPreviewService.swift
//  Discover
//
//  Created by Enzo Gallo on 26/12/2025.
//

import Foundation
import AVFoundation
import Combine

class AudioPreviewService: ObservableObject {
    static let shared = AudioPreviewService()
    
    private var player: AVPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentPreviewURL: String?
    
    private init() {
        // Configuration de la session audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur de configuration audio: \(error)")
        }
    }
    
    func playPreview(url: String) {
        print("🎵 AudioPreviewService: Demande de lecture pour \(url)")
        guard let validURL = URL(string: url) else { 
            print("❌ AudioPreviewService: URL invalide")
            return 
        }
        
        // Si c'est déjà en train de jouer ce son, on ne fait rien
        if isPlaying && currentPreviewURL == url {
            print("⚠️ AudioPreviewService: Dékà en lecture")
            return
        }
        
        // Arrêter le précédent
        stopPreview()
        
        let playerItem = AVPlayerItem(url: validURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Observer la fin de la lecture
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(playerDidFinishPlaying),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: playerItem)
        
        player?.play()
        isPlaying = true
        currentPreviewURL = url
        print("▶️ AudioPreviewService: Lecture lancée")
    }
    
    func stopPreview() {
        player?.pause()
        player = nil
        isPlaying = false
        currentPreviewURL = nil
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        DispatchQueue.main.async {
            self.stopPreview()
        }
    }
}
