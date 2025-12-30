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
    let onProfileTap: () -> Void
    @State private var isLoading: Bool = false
    @State private var postLikeCounts: [String: Int] = [:]
    @State private var postCommentCounts: [String: Int] = [:]
    @State private var postLikedStates: [String: Bool] = [:]
    @State private var expandedPostId: String? = nil
    @State private var commentTexts: [String: String] = [:]
    @State private var hasPostedToday: Bool = false
    @State private var selectedFeed: FeedType = .forYou
    @State private var followingIds: [String] = []
    
    enum FeedType {
        case friends
        case forYou
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Header avec bouton Discover
                HStack {
                    Button(action: {}) {
                        Text("feed.discover".localized)
                            .font(.plusJakartaSansBold(size: 19))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    Color.discoverBlack
                                    // Gradient subtil pour plus de profondeur
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            )
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    if let user = authService.currentUser, user.activeStreak > 0 {
                        StreakView(streakCount: user.activeStreak, showLabel: false)
                            .padding(.trailing, 8)
                    }

                    
                    if hasPostedToday {
                        // Countdown for daily reset
                        CountdownView()
                            .padding(.trailing, 16)
                    }

                }
                .padding(.top, 8)
                
                // Sélecteur d'onglets
                HStack(spacing: 12) {
                    // Onglet "Amis"
                    Button(action: {
                        withAnimation {
                            selectedFeed = .friends
                        }
                    }) {
                        CleanButton(
                            text: "feed.friends".localized,
                            backgroundColor: selectedFeed == .friends ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3),
                            textColor: selectedFeed == .friends ? .white : .themePrimaryText,
                            borderGradient: selectedFeed == .friends ? 
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                    }
                    
                    // Onglet "Explorer"
                    Button(action: {
                        withAnimation {
                            selectedFeed = .forYou
                        }
                    }) {
                        CleanButton(
                            text: "feed.for.you".localized,
                            backgroundColor: selectedFeed == .forYou ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3),
                            textColor: selectedFeed == .forYou ? .white : .themePrimaryText,
                            borderGradient: selectedFeed == .forYou ? 
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Feed content
                if isLoading && firebaseService.posts.isEmpty {
                    Spacer()
                    LoadingSpinner(message: "feed.loading".localized)
                    Spacer()
                } else if filteredPosts.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(selectedFeed == .friends ? "feed.no.friends.posts".localized : "feed.no.posts".localized)
                            .font(.plusJakartaSans(size: 15))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPosts) { post in
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
                                        _Concurrency.Task {
                                            await toggleLike(postId: post.id)
                                        }
                                    },
                                    onComment: { text in
                                        _Concurrency.Task {
                                            await addComment(postId: post.id, text: text)
                                        }
                                    },
                                    onExpand: {
                                        withAnimation {
                                            expandedPostId = expandedPostId == post.id ? nil : post.id
                                        }
                                    },
                                    onProfileTap: onProfileTap
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
            _Concurrency.Task {
                await loadPosts()
            }
        }
    }
    
    // Posts filtrés selon l'onglet sélectionné
    private var filteredPosts: [Post] {
        switch selectedFeed {
        case .friends:
            // Inclure les posts des utilisateurs suivis + les posts de l'utilisateur actuel
            let currentUserId = authService.currentUser?.id ?? ""
            return firebaseService.posts.filter { post in
                followingIds.contains(post.userId) || post.userId == currentUserId
            }
        case .forYou:
            // Tous les posts
            return firebaseService.posts
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        
        do {
            try await firebaseService.fetchPosts()
            
            // Charger les IDs des utilisateurs suivis
            if let userId = authService.currentUser?.id {
                let following = try await firebaseService.getFollowingIds(userId: userId)
                await MainActor.run {
                    self.followingIds = following
                }
            }
            
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
                
                // Rafraîchir l'utilisateur pour avoir sa streak à jour
                await authService.loadUserFromFirestore(firebaseService: firebaseService)
                
                await MainActor.run {
                    self.hasPostedToday = postedToday
                }
            }
            
            // Précharger les premières images critiques (3-5 premières)
            let postsToPreload = firebaseService.posts.prefix(5)
            await ImagePreloader.shared.preloadCriticalImages(from: Array(postsToPreload), count: 3)

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
    let onProfileTap: () -> Void
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
                    if !isBlurred {
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
                                } else {
                                    onProfileTap()
                                }
                            }) {
                                Group {
                                    if let profileURL = userProfilePictureURL {
                                        if profileURL.hasPrefix("data:image"),
                                           let data = Data(base64Encoded: profileURL.replacingOccurrences(of: "data:image/jpeg;base64,", with: "").replacingOccurrences(of: "data:image/png;base64,", with: "")),
                                           let image = UIImage(data: data) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if let url = URL(string: profileURL) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                            }
                                        } else {
                                            defaultProfileIcon
                                        }
                                    } else {
                                        defaultProfileIcon
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
                                    } else {
                                        onProfileTap()
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

                        // Bouton Spotify Queue
                        if spotifyService.isUserAuthenticated {
                            Button(action: {
                                _Concurrency.Task {
                                    await addToQueue()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("spotify.add.to.queue".localized)
                                        .font(.plusJakartaSansMedium(size: 10))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 50)
                                .padding(.vertical, 14)
                                .background(Color.init(red: 29/255, green: 185/255, blue: 84/255).opacity(0.8))
                                .cornerRadius(25)
                            }
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

                // Message "Ajouté à la file d'attente"
                if showAddedToQueueMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                Text("spotify.added.to.queue".localized)
                                    .font(.plusJakartaSansBold(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.init(red: 29/255, green: 185/255, blue: 84/255))
                            .cornerRadius(25)
                            .shadow(radius: 10)
                            Spacer()
                        }
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Message d'erreur
                if let error = errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(error)
                                    .font(.plusJakartaSansBold(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(25)
                            .shadow(radius: 10)
                            Spacer()
                        }
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    @State private var showAddedToQueueMessage = false
    @State private var errorMessage: String? = nil

    private var defaultProfileIcon: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .cornerRadius(25)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 25))
            )
    }

    private func addToQueue() async {
        do {
            try await spotifyService.addToQueue(spotifyID: post.spotifyID, isAlbum: post.isAlbum)
            
            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            await MainActor.run {
                withAnimation {
                    showAddedToQueueMessage = true
                    errorMessage = nil
                }
                
                // Masquer le message après 2 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showAddedToQueueMessage = false
                    }
                }
            }
        } catch {
            print("Erreur lors de l'ajout à la file d'attente: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
            await MainActor.run {
                withAnimation {
                    errorMessage = error.localizedDescription
                }
                
                // Masquer l'erreur après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        errorMessage = nil
                    }
                }
            }
        }
    }

    private func toggleAudio() {
        guard !isBlurred else { return }
        
        // Impact feedback immédiat
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // 1. Si ça joue déjà CE post -> Stop
        if isPlayingThisPost {
            audioPreviewService.stopPreview()
            return
        }
        
        // 2. Si ça joue un autre post -> Le service le coupera automatiquement au prochain play
        
        // 3. Avons-nous déjà l'URL ?
        if let cached = fetchedPreviewURL {
            audioPreviewService.playPreview(url: cached)
            return
        }
        
        // 4. Sinon, on va chercher
        isFetchingPreview = true
        _Concurrency.Task {
            let foundURL = await DeezerService.shared.findPreview(artist: post.artistName, title: post.musicTitle)
            
            await MainActor.run {
                isFetchingPreview = false
                if let url = foundURL {
                    fetchedPreviewURL = url
                    audioPreviewService.playPreview(url: url)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func loadUserProfilePicture() async {
        do {
            if let user = try await firebaseService.getUserById(userId: post.userId) {
                await MainActor.run {
                    self.userProfilePictureURL = user.profilePictureURL
                }
            }
        } catch {
            print("Erreur lors du chargement de la photo de profil: \(error)")
        }
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
