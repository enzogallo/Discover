//
//  CommentsView.swift
//  Discover
//
//  Created by Enzo Gallo on 06/12/2025.
//

import SwiftUI

struct CommentsView: View {
    let postId: String
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var comments: [Comment] = []
    @State private var isLoading: Bool = false
    @State private var newCommentText: String = ""
    @State private var isPosting: Bool = false
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("profile.discover".localized)
                            .font(.plusJakartaSansSemiBold(size: 17))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.discoverBlack)
                            .cornerRadius(22)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    Text("comments.title".localized)
                        .font(.plusJakartaSansSemiBold(size: 17))
                        .foregroundColor(.themePrimaryText)
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                
                // Liste des commentaires
                if isLoading && comments.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("comments.no.comments".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                // Champ de saisie de commentaire en bas
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // Photo de profil utilisateur actuel
                        if let currentUser = authService.currentUser {
                            Group {
                                if let profileURL = currentUser.profilePictureURL, let url = URL(string: profileURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 12))
                                            )
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 12))
                                        )
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        }
                        
                        TextField("feed.add.comment".localized, text: $newCommentText)
                            .font(.plusJakartaSans(size: 15))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.themeSurface)
                            .cornerRadius(20)
                            .onSubmit {
                                postComment()
                            }
                        
                        if !newCommentText.isEmpty {
                            Button(action: {
                                postComment()
                            }) {
                                Text("feed.post".localized)
                                    .font(.plusJakartaSansSemiBold(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .disabled(isPosting)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.themeBackground)
                }
            }
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        isLoading = true
        
        do {
            let fetchedComments = try await firebaseService.fetchComments(postId: postId)
            await MainActor.run {
                comments = fetchedComments
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("Erreur lors du chargement des commentaires: \(error)")
            }
        }
    }
    
    private func postComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty,
              let userId = authService.currentUser?.id,
              let pseudonym = authService.currentUser?.pseudonym else { return }
        
        isPosting = true
        
        Task {
            let comment = Comment(userId: userId, userPseudonym: pseudonym, postId: postId, text: newCommentText.trimmingCharacters(in: .whitespaces))
            
            do {
                try await firebaseService.addComment(comment)
                await MainActor.run {
                    newCommentText = ""
                    isPosting = false
                }
                await loadComments()
            } catch {
                await MainActor.run {
                    isPosting = false
                    print("Erreur lors de l'ajout du commentaire: \(error)")
                }
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Photo de profil
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Pseudonyme et timestamp
                HStack(spacing: 8) {
                    Text(comment.userPseudonym)
                        .font(.plusJakartaSansSemiBold(size: 14))
                        .foregroundColor(.themePrimaryText)
                    
                    Text(formatTimeAgo(comment.timestamp))
                        .font(.plusJakartaSans(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                // Texte du commentaire
                Text(comment.text)
                    .font(.plusJakartaSans(size: 15))
                    .foregroundColor(.themePrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date, to: Date())
        
        if let hours = components.hour, hours > 0 {
            if hours == 1 {
                return "common.hour.ago".localized(with: hours)
            } else {
                return "common.hours.ago".localized(with: hours)
            }
        } else if let minutes = components.minute, minutes > 0 {
            if minutes == 1 {
                return "common.minute.ago".localized(with: minutes)
            } else {
                return "common.minutes.ago".localized(with: minutes)
            }
        } else {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}


