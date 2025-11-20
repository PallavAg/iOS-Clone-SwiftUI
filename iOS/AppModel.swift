import SwiftUI

enum AppType: String, CaseIterable, Identifiable {
    case weather
    case calculator
    case notes
    case settings
    case clock
    case calendar
    case photos
    case messages
    case phone
    case safari
    case mail
    case music
    case appStore
    case camera
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .appStore: return "App Store"
        default: return rawValue.capitalized
        }
    }
    
    var iconName: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .calculator: return "function" // SF Symbol doesn't have a perfect calc, using function
        case .notes: return "note.text"
        case .settings: return "gear"
        case .clock: return "clock.fill"
        case .calendar: return "calendar"
        case .photos: return "photo.on.rectangle"
        case .messages: return "message.fill"
        case .phone: return "phone.fill"
        case .safari: return "safari.fill"
        case .mail: return "envelope.fill"
        case .music: return "music.note"
        case .appStore: return "bag.fill"
        case .camera: return "camera.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weather: return Color.blue.opacity(0.8)
        case .calculator: return Color.gray.opacity(0.3)
        case .notes: return Color.yellow.opacity(0.9)
        case .settings: return Color.gray.opacity(0.5)
        case .clock: return Color.black
        case .calendar: return Color.white
        case .photos: return Color.red.opacity(0.3)
        case .messages: return Color.green.opacity(0.9)
        case .phone: return Color.green.opacity(0.9)
        case .safari: return .blue
        case .mail: return .blue
        case .music: return .red
        case .appStore: return .blue
        case .camera: return Color.gray.opacity(0.5)
        }
    }
    
    var assetName: String? {
        switch self {
        case .weather: return "weather"
        case .calculator: return "calculator"
        case .notes: return "notes"
        case .settings: return "settings"
        case .clock: return "clock"
        case .calendar: return "calendar"
        case .photos: return "photos"
        case .messages: return "messages"
        case .phone: return "phone"
        case .safari: return "safari"
        case .mail: return "mail"
        case .music: return "music"
        case .appStore: return "appstore"
        case .camera: return "camera"
        default: return nil
        }
    }
    
    // For apps that need a custom background gradient or style
    var isGradient: Bool {
        switch self {
        case .weather, .messages, .phone, .safari, .mail, .music, .appStore:
            return true
        default:
            return false
        }
    }
}

struct AppIconView: View {
    let app: AppType
    let action: () -> Void
    var showLabel: Bool = true
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                // Use asset images if available, otherwise fallback to SF Symbols
                if let assetName = app.assetName {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 65, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                } else {
                    // Fallback to old implementation for apps without assets
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(app.color)
                            .frame(width: 70, height: 70)
                        
                        if app == .calendar {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(.red)
                                    .frame(height: 15)
                                Text(Date().formatted(.dateTime.day()))
                                    .font(.system(size: 26, weight: .light))
                                    .foregroundStyle(.primary)
                            }
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        } else {
                            Image(systemName: app.iconName)
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                if showLabel {
                    Text(app.displayName)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
