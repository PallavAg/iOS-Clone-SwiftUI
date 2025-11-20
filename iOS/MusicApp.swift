import SwiftUI
import AVFoundation
import Combine

// MARK: - Models

struct Track: Identifiable, Codable, Hashable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let artworkUrl100: String
    let previewUrl: String?
    
    var id: Int { trackId }
    
    var artworkLarge: URL? {
        URL(string: artworkUrl100.replacingOccurrences(of: "100x100", with: "600x600"))
    }
    
    var artworkSmall: URL? {
        URL(string: artworkUrl100)
    }
}

struct ITunesResponse: Codable {
    let results: [Track]
}

// MARK: - Logic Manager

@MainActor
class MusicManager: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var showFullPlayer: Bool = false
    @Published var searchText: String = "The Weeknd"
    
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 29.0
    
    private var player: AVPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?
    
    init() {
        searchMusic()
    }
    
    func searchMusic() {
        let query = searchText.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=song&limit=25") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ITunesResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] response in
                self?.tracks = response.results
            })
            .store(in: &cancellables)
    }
    
    func play(_ track: Track) {
        // 1. If tapping the same song, just toggle playback and open player
        if currentTrack?.id == track.id {
            if !isPlaying { togglePlayPause() }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFullPlayer = true
            }
            return
        }
        
        guard let urlString = track.previewUrl, let url = URL(string: urlString) else { return }
        
        // 2. CRITICAL FIX: Remove the old observer from the OLD player instance *before* overwriting 'player'
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // 3. Setup New Player
        currentTrack = track
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
        
        // 4. Open Player UI
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showFullPlayer = true
        }
        
        // 5. Add New Observer
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // 6. Loop Playback
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func nextTrack() {
        guard let current = currentTrack, let index = tracks.firstIndex(where: { $0.id == current.id }) else { return }
        let nextIndex = (index + 1) % tracks.count
        play(tracks[nextIndex])
    }
    
    func previousTrack() {
        guard let current = currentTrack, let index = tracks.firstIndex(where: { $0.id == current.id }) else { return }
        let prevIndex = (index - 1 + tracks.count) % tracks.count
        play(tracks[prevIndex])
    }
}

// MARK: - Main View

struct MusicView: View {
    @StateObject private var manager = MusicManager()
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Tab View
            TabView {
                HomeView(manager: manager)
                    .tabItem { Label("Listen Now", systemImage: "play.circle.fill") }
                
                BrowseView(manager: manager)
                    .tabItem { Label("Browse", systemImage: "square.grid.2x2.fill") }
                
                Text("Radio")
                    .tabItem { Label("Radio", systemImage: "dot.radiowaves.left.and.right") }
                
                Text("Library")
                    .tabItem { Label("Library", systemImage: "square.stack.fill") }
                
                MusicSearchView(manager: manager)
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
            }
            .accentColor(.red)
            
            // 2. Mini Player
            if let track = manager.currentTrack, !manager.showFullPlayer {
                FloatingMiniPlayer(track: track, manager: manager, animation: animation)
                    .padding(.bottom, 55)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
            
            // 3. Full Player
            if let track = manager.currentTrack, manager.showFullPlayer {
                FullPlayerView(track: track, manager: manager, animation: animation)
                    .zIndex(2)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Floating Mini Player

struct FloatingMiniPlayer: View {
    let track: Track
    @ObservedObject var manager: MusicManager
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 15) {
            // Artwork
            AsyncImage(url: track.artworkSmall) { image in
                image.resizable()
            } placeholder: {
                Color(uiColor: .systemGray5)
            }
            .frame(width: 42, height: 42)
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .matchedGeometryEffect(id: "artwork", in: animation)
            
            // Title
            Text(track.trackName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .matchedGeometryEffect(id: "title", in: animation)
            
            Spacer()
            
            // Controls
            Button(action: manager.togglePlayPause) {
                Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            Button(action: manager.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 10)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                manager.showFullPlayer = true
            }
        }
    }
}

// MARK: - Full Player (Detailed)

struct FullPlayerView: View {
    let track: Track
    @ObservedObject var manager: MusicManager
    var animation: Namespace.ID
    
    @State private var dragOffset: CGSize = .zero
    @State private var volume: Double = 0.75
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                AsyncImage(url: track.artworkLarge) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 60)
                        .overlay(Color.black.opacity(0.7))
                } placeholder: {
                    Rectangle().fill(Color(uiColor: .darkGray))
                }
                
                VStack(spacing: 0) {
                    // Grabber
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Artwork
                    AsyncImage(url: track.artworkLarge) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                    .matchedGeometryEffect(id: "artwork", in: animation)
                    .frame(width: geo.size.width - 50, height: geo.size.width - 50)
                    .padding(.bottom, 40)
                    
                    // Info & Controls
                    VStack(spacing: 0) {
                        
                        // Title & Artist
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.trackName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .matchedGeometryEffect(id: "title", in: animation)
                                
                                Text(track.artistName)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                        
                        // Scrubber
                        VStack(spacing: 8) {
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: barGeo.size.width * (manager.currentTime / manager.duration), height: 4)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                        .offset(x: barGeo.size.width * (manager.currentTime / manager.duration) - 4)
                                }
                            }
                            .frame(height: 10)
                            
                            HStack {
                                Text(formatTime(manager.currentTime))
                                Spacer()
                                Text("-" + formatTime(manager.duration - manager.currentTime))
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        // Controls
                        HStack(spacing: 50) {
                            Button(action: manager.previousTrack) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                            
                            Button(action: manager.togglePlayPause) {
                                Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 55))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.white)
                            }
                            
                            Button(action: manager.nextTrack) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Volume
                        HStack(spacing: 15) {
                            Image(systemName: "speaker.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            CustomVolumeSlider(value: $volume)
                                .frame(height: 5)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                        
                        // Bottom Icons
                        HStack(spacing: 0) {
                            Button(action: {}) {
                                Image(systemName: "quote.bubble")
                                    .font(.title2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button(action: {}) {
                                Image(systemName: "airplayaudio")
                                    .font(.title2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button(action: {}) {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 20) // Adjusted padding
                    }
                    
                    Spacer().frame(height: 30)
                }
            }
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                manager.showFullPlayer = false
                            }
                        }
                        withAnimation { dragOffset = .zero }
                    }
            )
        }
    }
    
    func formatTime(_ time: Double) -> String {
        let seconds = Int(time) % 60
        let minutes = Int(time) / 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Custom Volume Slider

struct CustomVolumeSlider: View {
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 5)
                
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * value, height: 5)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let percent = min(max(gesture.location.x / geo.size.width, 0), 1)
                        value = percent
                    }
            )
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var manager: MusicManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Top Picks")
                            .font(.title2).bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(manager.tracks.prefix(5)) { track in
                                    Button(action: { manager.play(track) }) {
                                        VStack(alignment: .leading) {
                                            AsyncImage(url: track.artworkLarge) { img in
                                                img.resizable()
                                            } placeholder: {
                                                Color(uiColor: .secondarySystemBackground)
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            .frame(width: 240, height: 240)
                                            .cornerRadius(10)
                                            .shadow(radius: 3)
                                            
                                            Text(track.trackName)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                                .font(.headline)
                                            Text(track.artistName)
                                                .foregroundStyle(.secondary)
                                                .font(.subheadline)
                                        }
                                        .frame(width: 240)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider().padding(.leading, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Made For You")
                            .font(.title2).bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(manager.tracks.dropFirst(5).prefix(8)) { track in
                                    Button(action: { manager.play(track) }) {
                                        VStack(alignment: .leading) {
                                            AsyncImage(url: track.artworkLarge) { img in
                                                img.resizable()
                                            } placeholder: {
                                                Color(uiColor: .secondarySystemBackground)
                                            }
                                            .aspectRatio(1, contentMode: .fill)
                                            .frame(width: 160, height: 160)
                                            .cornerRadius(8)
                                            
                                            Text(track.trackName)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .frame(width: 160)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recently Played")
                            .font(.title2).bold()
                            .padding(.horizontal)
                        
                        ForEach(manager.tracks.suffix(8)) { track in
                            Button(action: { manager.play(track) }) {
                                HStack(spacing: 15) {
                                    AsyncImage(url: track.artworkSmall) { img in
                                        img.resizable()
                                    } placeholder: { Color.gray }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(4)
                                    
                                    VStack(alignment: .leading) {
                                        Text(track.trackName)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(track.artistName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading, 80)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .padding(.top)
            }
            .navigationTitle("Listen Now")
        }
    }
}

struct MusicSearchView: View {
    @ObservedObject var manager: MusicManager
    
    var body: some View {
        NavigationStack {
            List(manager.tracks) { track in
                Button(action: { manager.play(track) }) {
                    HStack(spacing: 12) {
                        AsyncImage(url: track.artworkSmall) { image in
                            image.resizable()
                        } placeholder: { Color.gray }
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.trackName)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(track.artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        if manager.currentTrack?.id == track.id {
                            Image(systemName: "waveform")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $manager.searchText)
            .onSubmit(of: .search) {
                manager.searchMusic()
            }
            .navigationTitle("Search")
        }
    }
}

struct BrowseView: View {
    @ObservedObject var manager: MusicManager
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Browse content...").padding()
                }
            }
            .navigationTitle("Browse")
        }
    }
}


#Preview {
    MusicView()
}
