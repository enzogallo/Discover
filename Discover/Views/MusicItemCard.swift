//
//  MusicItemCard.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct MusicItemCard: View {
    let item: MusicItem
    let canPost: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.coverArtURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.plusJakartaSansSemiBold(size: 17))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.artist)
                    .font(.plusJakartaSans(size: 15))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(1)
                
                Text(item.isAlbum ? "common.album".localized : "common.track".localized)
                    .font(.plusJakartaSans(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if canPost {
                Button(action: onSelect) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(white: 0.95))
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 22))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
