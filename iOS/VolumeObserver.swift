import SwiftUI
import MediaPlayer
import Combine

class VolumeObserver: ObservableObject {
    @Published var volume: Float = 0.0
    private var audioSession: AVAudioSession?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setActive(true)
            
            // Observe outputVolume
            audioSession?.publisher(for: \.outputVolume)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newVolume in
                    self?.volume = newVolume
                }
                .store(in: &cancellables)
            
            // Initial value
            volume = audioSession?.outputVolume ?? 0.0
            
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
}

// Hidden volume view to intercept system volume UI if needed (optional, but good for hiding the HUD)
struct HiddenVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.alpha = 0.0001 // Hide it but keep it active
        return view
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
