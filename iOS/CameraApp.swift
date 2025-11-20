import SwiftUI
import AVFoundation
import Photos
import Combine

// MARK: - Camera View Model
class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSaved = false
    @Published var recentImage: UIImage? = nil
    @Published var isRecording = false
    @Published var recordedDuration: TimeInterval = 0
    
    // State
    @Published var mode: CameraMode = .photo
    @Published var zoomFactor: CGFloat = 1.0
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var position: AVCaptureDevice.Position = .back
    
    // Outputs
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureMovieFileOutput()
    
    // Inputs
    var videoDeviceInput: AVCaptureDeviceInput?
    
    private let sessionQueue = DispatchQueue(label: "camera_session_queue")
    private var timer: Timer?
    
    enum CameraMode { case photo, video }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setup()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { status in
                    if status { self.setup() }
                }
            default:
                return
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
        PHPhotoLibrary.requestAuthorization { _ in }
    }
    
    func setup() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            // 1. Setup Video Input
            self.setupInput(for: self.position)
            
            // 2. Setup Audio Input
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }
            
            // 3. Setup Outputs
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    func setupInput(for position: AVCaptureDevice.Position) {
        // Remove existing video input
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Try to get the best camera available
        // .builtInTripleCamera (Pro models), .builtInDualCamera (Standard), or .builtInWideAngleCamera (Old/SE)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        
        guard let device = discoverySession.devices.first else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            }
        } catch {
            print("Error setting up input: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        guard !videoOutput.isRecording else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.recordedDuration = 0
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.recordedDuration += 1
            }
        }
    }
    
    func stopRecording() {
        guard videoOutput.isRecording else { return }
        videoOutput.stopRecording()
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func toggleCamera() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.position = (self.position == .back) ? .front : .back
            self.setupInput(for: self.position)
            self.session.commitConfiguration()
            
            // Reset zoom when switching cameras
            DispatchQueue.main.async { self.zoomFactor = 1.0 }
        }
    }
    
    func setZoom(factor: CGFloat) {
        // CRITICAL FIX: Ensure we only zoom the VIDEO device
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Safely clamp zoom to what the specific hardware supports
            // Some devices (iPhone SE) don't support < 1.0 zoom
            let minAvailable = device.minAvailableVideoZoomFactor
            let maxAvailable = min(device.maxAvailableVideoZoomFactor, 5.0) // Cap at 5x
            
            let safeFactor = max(minAvailable, min(factor, maxAvailable))
            
            device.videoZoomFactor = safeFactor
            device.unlockForConfiguration()
            
            DispatchQueue.main.async { self.zoomFactor = safeFactor }
        } catch {
            print("Zoom Error: \(error)")
        }
    }
    
    func toggleFlash() {
        flashMode = (flashMode == .off) ? .on : .off
    }
}

// MARK: - Delegates
extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { print(error); return }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        
        DispatchQueue.main.async {
            self.recentImage = image
            self.isSaved = true
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

extension CameraModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error { print(error); return }
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }
    }
}

// MARK: - Robust Preview View (UIView Subclass)
// This fixes the issue where the camera doesn't show up instantly.
class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // No updates needed, the layer is attached to the session directly
    }
}

// MARK: - Main UI
struct CameraView: View {
    @StateObject var camera = CameraModel()
    @State private var shutterAnimation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. Camera Preview
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            // 2. UI Overlay
            VStack(spacing: 0) {
                
                // Top Controls
                HStack {
                    if camera.isRecording {
                        Text(formatDuration(camera.recordedDuration))
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                    } else {
                        Button(action: camera.toggleFlash) {
                            Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(camera.flashMode == .on ? .yellow : .white)
                        }
                        Spacer()
                        // Mock Action Menu
                        Button(action: {}) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "livephoto")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                
                Spacer()
                
                // Zoom Controls (Hidden during video recording for simplicity)
                if !camera.isRecording {
                    HStack(spacing: 20) {
                        ZoomBubble(label: ".5", isSelected: camera.zoomFactor == 0.5) { camera.setZoom(factor: 0.5) }
                        ZoomBubble(label: "1x", isSelected: camera.zoomFactor == 1.0) { camera.setZoom(factor: 1.0) }
                        ZoomBubble(label: "2", isSelected: camera.zoomFactor == 2.0) { camera.setZoom(factor: 2.0) }
                        ZoomBubble(label: "5", isSelected: camera.zoomFactor == 5.0) { camera.setZoom(factor: 5.0) }
                    }
                    .padding(.bottom, 30)
                }
                
                // Bottom Bar
                ZStack(alignment: .bottom) {
                    // Background
                    Color.black
                        .ignoresSafeArea()
                        .frame(height: 150)
                    
                    VStack(spacing: 15) {
                        
                        // Mode Slider
                        HStack(spacing: 30) {
                            Button(action: { withAnimation { camera.mode = .video } }) {
                                Text("VIDEO")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(camera.mode == .video ? .yellow : .white)
                            }
                            Button(action: { withAnimation { camera.mode = .photo } }) {
                                Text("PHOTO")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(camera.mode == .photo ? .yellow : .white)
                            }
                        }
                        .padding(.top, 10)
                        .opacity(camera.isRecording ? 0 : 1)
                        
                        // Controls Row
                        HStack {
                            // Recent Photo
                            Button(action: {}) {
                                if let image = camera.recentImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 2))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 48, height: 48)
                                }
                            }
                            .opacity(camera.isRecording ? 0 : 1)
                            
                            Spacer()
                            
                            // Shutter
                            Button(action: {
                                if camera.mode == .photo {
                                    camera.capturePhoto()
                                    withAnimation(.linear(duration: 0.1)) { shutterAnimation = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation { shutterAnimation = false }
                                    }
                                } else {
                                    if camera.isRecording {
                                        camera.stopRecording()
                                    } else {
                                        camera.startRecording()
                                    }
                                }
                            }) {
                                ShutterButtonView(mode: camera.mode, isRecording: camera.isRecording, animate: shutterAnimation)
                            }
                            
                            Spacer()
                            
                            // Rotate Camera
                            Button(action: camera.toggleCamera) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 22, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                            .opacity(camera.isRecording ? 0 : 1)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
            
            // Flash animation
            if shutterAnimation && camera.mode == .photo {
                Color.black.opacity(0.8).ignoresSafeArea()
            }
        }
        .onAppear { camera.setup() }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Components

struct ZoomBubble: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 40, height: 40)
                
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .yellow : .white)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .overlay(
                Circle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}

struct ShutterButtonView: View {
    let mode: CameraModel.CameraMode
    let isRecording: Bool
    let animate: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white, lineWidth: 4)
                .frame(width: 80, height: 80)
            
            if mode == .photo {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .scaleEffect(animate ? 0.85 : 1.0)
            } else {
                if isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                        .frame(width: 35, height: 35)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
    }
}

#Preview {
    CameraView()
}
