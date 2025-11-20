import SwiftUI

struct SystemDesign {
    static let wallpaperGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.4, green: 0.2, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    struct Colors {
        static let dockBackground = Color.white.opacity(0.2)
        static let folderBackground = Color.white.opacity(0.2)
        static let systemGray6 = Color(uiColor: .systemGray6)
    }
}
