//
//  FeedView.swift
//  Discover
//
//  Created by Enzo Gallo on 05/12/2025.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var firebaseService: FirebaseService
    @ObservedObject var spotifyService: SpotifyService
    let onParticipate: () -> Void
    @State private var isLoading: Bool = false
    @State private var postLikeCounts: [String: Int] = [:]
    @State private var postCommentCounts: [String: Int] = [:]
    @State private var postLikedStates: [String: Bool] = [:]
    @State private var expandedPostId: String? = nil
    @State private var commentTexts: [String: String] = [:]
    @State private var hasPostedToday: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 1, green: 1, blue: 1)
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Header avec bouton Discover
                HStack {
                    Button(action: {}) {
                        Text("feed.discover".localized)
                            .font(.plusJakartaSansSemiBold(size: 17))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color(hex: "222222"))
                            .cornerRadius(22)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    if hasPostedToday {
                        // Countdown for daily reset
                        CountdownView()
                            .padding(.trailing, 16)
                    }
                }
                .padding(.top, 8)
                
                // Feed content
                if isLoading && firebaseService.posts.isEmpty {
                    Spacer()
                    ProgressView("feed.loading".localized)
                    Spacer()
                } else if firebaseService.posts.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("feed.no.posts".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(firebaseService.posts) { post in
                                NewPostCard(
                                    post: post,
                                    spotifyService: spotifyService,
                                    firebaseService: firebaseService,
                                    authService: authService,
                                    currentUserId: authService.currentUser?.id ?? "",
                                    likeCount: postLikeCounts[post.id] ?? 0,
                                    commentCount: postCommentCounts[post.id] ?? 0,
                                    isLiked: postLikedStates[post.id] ?? false,
                                    isExpanded: expandedPostId == post.id,
                                    isBlurred: !hasPostedToday && post.userId != (authService.currentUser?.id ?? ""),
                                    onParticipate: onParticipate,
                                    commentText: Binding(
                                        get: { commentTexts[post.id] ?? "" },
                                        set: { commentTexts[post.id] = $0 }
                                    ),
                                    onLike: {
                                        Task {
                                            await toggleLike(postId: post.id)
                                        }
                                    },
                                    onComment: { text in
                                        Task {
                                            await addComment(postId: post.id, text: text)
                                        }
                                    },
                                    onExpand: {
                                        withAnimation {
                                            expandedPostId = expandedPostId == post.id ? nil : post.id
                                        }
                                    }
                                )
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
        }
        .task {
            await loadPosts()
        }
        .refreshable {
            await loadPosts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFeed"))) { _ in
            Task {
                await loadPosts()
            }
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        
        do {
            try await firebaseService.fetchPosts()
            
            // Charger les counts et états pour tous les posts
            for post in firebaseService.posts {
                async let likeCount = firebaseService.getLikeCount(postId: post.id)
                async let commentCount = firebaseService.getCommentCount(postId: post.id)
                async let isLiked = authService.currentUser != nil ? firebaseService.isLiked(postId: post.id, userId: authService.currentUser!.id) : false
                
                let (count, comments, liked) = try await (likeCount, commentCount, isLiked)
                
                await MainActor.run {
                    postLikeCounts[post.id] = count
                    postCommentCounts[post.id] = comments
                    postLikedStates[post.id] = liked
                }
            }
            
            // Vérifier si l'utilisateur a posté aujourd'hui
            if let userId = authService.currentUser?.id {
                let postedToday = try await firebaseService.hasUserPostedToday(userId: userId)
                await MainActor.run {
                    self.hasPostedToday = postedToday
                }
            }
        } catch {
            print("Erreur lors du chargement: \(error)")
        }
        
        isLoading = false
    }
    
    private func toggleLike(postId: String) async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            let isLiked = try await firebaseService.toggleLike(postId: postId, userId: userId)
            let newCount = try await firebaseService.getLikeCount(postId: postId)
            
            await MainActor.run {
                postLikedStates[postId] = isLiked
                postLikeCounts[postId] = newCount
            }
        } catch {
            print("Erreur lors du like: \(error)")
        }
    }
    
    private func addComment(postId: String, text: String) async {
        guard let userId = authService.currentUser?.id,
              let pseudonym = authService.currentUser?.pseudonym,
              !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let comment = Comment(userId: userId, userPseudonym: pseudonym, postId: postId, text: text)
        
        do {
            try await firebaseService.addComment(comment)
            let newCount = try await firebaseService.getCommentCount(postId: postId)
            
            await MainActor.run {
                postCommentCounts[postId] = newCount
                commentTexts[postId] = ""
            }
        } catch {
            print("Erreur lors de l'ajout du commentaire: \(error)")
        }
    }
}

struct NewPostCard: View {
    let post: Post
    let spotifyService: SpotifyService
    let firebaseService: FirebaseService
    let authService: AuthService
    let currentUserId: String
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isExpanded: Bool
    let isBlurred: Bool
    let onParticipate: () -> Void
    @Binding var commentText: String
    let onLike: () -> Void
    let onComment: (String) -> Void
    let onExpand: () -> Void
    @State private var showOtherUserProfile = false
    @State private var showComments = false
    @State private var userProfilePictureURL: String? = nil
    
    @StateObject private var audioPreviewService = AudioPreviewService.shared
    
    @State private var fetchedPreviewURL: String? = nil
    @State private var isFetchingPreview = false
    
    // Computed property pour savoir si CE post joue
    private var isPlayingThisPost: Bool {
        return audioPreviewService.isPlaying && 
               (audioPreviewService.currentPreviewURL == fetchedPreviewURL)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Carte du post avec album art comme fond
            GeometryReader { geometry in
                let cardWidth = geometry.size.width
                
                ZStack(alignment: .topLeading) {
                    // Album art comme fond
                    Button(action: {
                        spotifyService.openInSpotify(spotifyURL: post.spotifyURL)
                    }) {
                        AsyncImage(url: URL(string: post.coverArtURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 40))
                                )
                        }
                        .frame(width: cardWidth, height: 500)
                        .clipped()
                        .blur(radius: isBlurred ? 40 : 0)
                        .overlay(
                            Group {
                                if isBlurred {
                                    Color.black.opacity(0.2)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Overlay Speaker Icon (Instagram style)
                    // Placé en bas à gauche de l'image (dans le ZStack)
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: toggleAudio) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 36, height: 36)
                                    
                                    if isFetchingPreview {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isPlayingThisPost ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.bottom, 16)
                            Spacer()
                        }
                    }
                
                // Dégradé sombre en haut pour la lisibilité du texte
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    
                    Spacer()
                }
                
                // Contenu par-dessus l'image
                VStack(alignment: .leading, spacing: 0) {
                    // Header avec utilisateur et infos musique
                    HStack(alignment: .center) {
                        // Photo de profil et infos utilisateur
                        HStack(spacing: 12) {
                            // Photo de profil avec bordure orange-jaune
                            Button(action: {
                                if post.userId != currentUserId {
                                    showOtherUserProfile = true
                                }
                            }) {
                                Group {
                                    if let profileURL = userProfilePictureURL, let url = URL(string: profileURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .cornerRadius(25)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.gray)
                                                        .font(.system(size: 25))
                                                )
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .cornerRadius(25)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 25))
                                            )
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.orange, Color.yellow],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: {
                                    if post.userId != currentUserId {
                                        showOtherUserProfile = true
                                    }
                                }) {
                                    Text(post.userPseudonym)
                                        .font(.plusJakartaSansBold(size: 18))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(formatTimeAgo(post.timestamp))
                                    .font(.plusJakartaSans(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        Spacer()
                        
                        // Infos musique alignées avec le centre de la photo de profil
                        Text("\(post.artistName) - \(post.musicTitle)")
                            .font(.plusJakartaSansSemiBold(size: 13))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .blur(radius: isBlurred ? 10 : 0)
                .allowsHitTesting(!isBlurred)
                
                // Boutons likes et commentaires sur le côté droit
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Spacer()
                        
                        // Bouton commentaires
                        Button(action: {
                            showComments = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                Text("\(commentCount)")
                                    .font(.plusJakartaSansMedium(size: 12))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(25)
                        }
                        
                        // Bouton likes
                        Button(action: onLike) {
                            VStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                Text(formatCount(likeCount))
                                    .font(.plusJakartaSansMedium(size: 12))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50)
                            .padding(.vertical, 16)
                            .background(
                                isLiked 
                                    ? AnyShapeStyle(Color.red.opacity(0.8)) 
                                    : AnyShapeStyle(Color.white.opacity(0.25))
                            )
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.trailing, 16)
                    .blur(radius: isBlurred ? 10 : 0)
                    .allowsHitTesting(!isBlurred)
                }
                
                // Overlay "Participe pour voir"
                if isBlurred {
                    Button(action: onParticipate) {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    
                                    Text("feed.reveal.cta".localized)
                                        .font(.plusJakartaSansBold(size: 16))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 30)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(25)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                }
                .frame(width: cardWidth, height: 500)
                .clipped()
                .cornerRadius(40)
            }
            .frame(height: 500)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .task {
            // Charger la photo de profil de l'utilisateur du post
            await loadUserProfilePicture()
        }
        .sheet(isPresented: $showOtherUserProfile) {
            OtherUserProfileView(
                userId: post.userId,
                userPseudonym: post.userPseudonym,
                authService: authService,
                firebaseService: firebaseService
            )
        }
        .sheet(isPresented: $showComments) {
            CommentsView(
                postId: post.id,
                firebaseService: firebaseService,
                authService: authService
            )
        }
    }
    
    private func toggleAudio() {
        // Impact feedback immédiat
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // 1. Si ça joue déjà CE post -> Stop
        if isPlayingThisPost {
            audioPreviewService.stopPreview()
            return
        }
        
        // 2. Si ça joue un autre post -> Le service le coupera automatiquement au prochain play, 
        // ou on peut forcer le stop si on veut être sûr.
        // audioPreviewService.playPreview coupe le précédent.
        
        // 3. Avons-nous déjà l'URL ?
        if let cached = fetchedPreviewURL {
            audioPreviewService.playPreview(url: cached)
            return
        }
        
        // 4. Sinon, on va chercher
        isFetchingPreview = true
        Task {
            let foundURL = await DeezerService.shared.findPreview(artist: post.artistName, title: post.musicTitle)
            
            await MainActor.run {
                isFetchingPreview = false
                if let url = foundURL {
                    fetchedPreviewURL = url
                    // On lance seulement si l'utilisateur n'a pas annulé entre temps ? 
                    // Pour un simple toggle, on part du principe qu'il veut écouter.
                    audioPreviewService.playPreview(url: url)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func loadUserProfilePicture() async {
        // Pour l'instant, on garde nil car on n'a pas encore de système d'upload
        // Plus tard, on chargera depuis Firebase
        userProfilePictureURL = nil
    }
    
    // Helper pour formater le temps
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Helper pour formater les compteurs
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(count)"
    }
}
