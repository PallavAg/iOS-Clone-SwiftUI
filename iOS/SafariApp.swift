import SwiftUI
import WebKit
import Combine

// MARK: - 1. Web ViewModel (The Brain)
class SafariViewModel: ObservableObject {
    // State to drive UI switching
    @Published var shouldShowBrowser: Bool = false
    
    @Published var urlString: String = "" // Text in the bar
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double = 0.0
    
    // The WebView instance must be held here to persist state
    let webView: WKWebView
    
    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        self.webView = WKWebView(frame: .zero, configuration: config)
    }
    
    func load(input: String) {
        guard !input.isEmpty else { return }
        
        // 1. Force the UI to switch to the browser immediately
        DispatchQueue.main.async {
            self.shouldShowBrowser = true
        }
        
        var urlComponents: URL?
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Smart URL Parsing
        if let url = URL(string: trimmed), trimmed.contains("://") {
            // Has protocol (https://...), use as is
            urlComponents = url
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            // Looks like domain (apple.com), add https
            urlComponents = URL(string: "https://" + trimmed)
        } else {
            // Search Query (pizza near me) -> Google
            let query = trimmed.replacingOccurrences(of: " ", with: "+")
            urlComponents = URL(string: "https://www.google.com/search?q=" + query)
        }
        
        // 3. Execute Load
        if let finalURL = urlComponents {
            self.urlString = finalURL.absoluteString // Optimistic update for UI
            let request = URLRequest(url: finalURL)
            webView.load(request)
        }
    }
    
    func closeBrowser() {
        shouldShowBrowser = false
        urlString = ""
        progress = 0
        webView.stopLoading()
        // Optional: Load "about:blank" to clear state
        webView.load(URLRequest(url: URL(string: "about:blank")!))
    }
    
    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }
    func stop() { webView.stopLoading() }
}

// MARK: - 2. Main Safari View
struct SafariView: View {
    @StateObject private var model = SafariViewModel()
    @State private var isEditingAddress = false
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .white).ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // --- TOP ADDRESS BAR ---
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        // 'aA' / Reader Icon
                        Image(systemName: "textformat.size")
                            .font(.system(size: 16))
                            .foregroundStyle(.black)
                        
                        Spacer()
                        
                        // URL Input / Display
                        if isEditingAddress {
                            TextField("Search or enter website", text: $inputText)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($isFocused)
                                .submitLabel(.go)
                                .onSubmit {
                                    commitSearch()
                                }
                        } else {
                            Button(action: {
                                // Pre-fill input with current URL
                                inputText = displayTitle
                                withAnimation { isEditingAddress = true }
                            }) {
                                HStack(spacing: 4) {
                                    if model.shouldShowBrowser {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.black)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Text(displayTitle)
                                        .font(.system(size: 17))
                                        .foregroundStyle(.black)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Reload / Stop Button
                        if model.isLoading {
                            Button(action: model.stop) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.black)
                            }
                        } else {
                            Button(action: model.reload) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    
                    // Progress Bar (Only show when loading)
                    if model.isLoading {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * model.progress, height: 2)
                                .animation(.linear, value: model.progress)
                        }
                        .frame(height: 2)
                    } else {
                        Divider()
                    }
                }
                .background(Color(uiColor: .systemBackground))
                .zIndex(2) // Keep bar on top
                
                // --- MAIN CONTENT AREA ---
                ZStack {
                    // Switch logic: If 'shouldShowBrowser' is true, show WebView. Else StartPage.
                    if model.shouldShowBrowser {
                        SafariWebViewRepresentable(viewModel: model)
                    } else {
                        StartPage(model: model)
                    }
                    
                    // Search Overlay (When typing in address bar)
                    if isEditingAddress {
                        Color(uiColor: .systemBackground)
                            .ignoresSafeArea()
                            .overlay(
                                VStack {
                                    List {
                                        Section(header: Text("Favorites")) {
                                            ForEach(FavoritesData.list) { item in
                                                Button(action: {
                                                    model.load(input: item.url)
                                                    endEditing()
                                                }) {
                                                    Label(item.name, systemImage: item.icon)
                                                }
                                            }
                                        }
                                    }
                                    .listStyle(.plain)
                                }
                                    .padding(.top, 0)
                            )
                            .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // --- BOTTOM TOOLBAR ---
                // Hide toolbar while editing address to give space to keyboard
                if !isEditingAddress {
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            // Back
                            Button(action: model.goBack) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 22, weight: .medium))
                                    .frame(width: 50, height: 40)
                            }
                            .disabled(!model.canGoBack)
                            .foregroundStyle(model.canGoBack ? .blue : .gray.opacity(0.3))
                            
                            Spacer()
                            
                            // Forward
                            Button(action: model.goForward) {
                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 22, weight: .medium))
                                    .frame(width: 50, height: 40)
                            }
                            .disabled(!model.canGoForward)
                            .foregroundStyle(model.canGoForward ? .blue : .gray.opacity(0.3))
                            
                            Spacer()
                            
                            // Share
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22, weight: .medium))
                                    .frame(width: 50, height: 40)
                            }
                            .foregroundStyle(.blue)
                            
                            Spacer()
                            
                            // Bookmarks
                            Button(action: {}) {
                                Image(systemName: "book")
                                    .font(.system(size: 22, weight: .medium))
                                    .frame(width: 50, height: 40)
                            }
                            .foregroundStyle(.blue)
                            
                            Spacer()
                            
                            // Tabs
                            Button(action: {}) {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 22, weight: .medium))
                                    .frame(width: 50, height: 40)
                            }
                            .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 8)
                        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
                    }
                }
            }
        }
        // Ensure keyboard focuses when "Search" is tapped
        .onChange(of: isEditingAddress) { newValue in
            if newValue {
                isFocused = true
            } else {
                isFocused = false
            }
        }
        // white mode
        .colorScheme(.light)
    }
    
    // --- Logic Helpers ---
    
    func commitSearch() {
        model.load(input: inputText)
        endEditing()
    }
    
    func endEditing() {
        isFocused = false
        withAnimation {
            isEditingAddress = false
        }
    }
    
    var displayTitle: String {
        if !model.shouldShowBrowser { return "Search or enter website name" }
        
        // Clean up URL for pretty display
        return model.urlString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
            .split(separator: "/").first.map(String.init) ?? model.urlString
    }
}

// MARK: - 3. Start Page (Favorites)
struct StartPage: View {
    @ObservedObject var model: SafariViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Color.clear.frame(height: 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(FavoritesData.list) { item in
                            Button(action: {
                                model.load(input: item.url)
                            }) {
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                        .frame(width: 62, height: 62)
                                        .overlay(
                                            Image(systemName: item.icon)
                                                .font(.title2)
                                                .foregroundStyle(item.color)
                                        )
                                    
                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
                
                // Privacy Report Mock
                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy Report")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("0")
                                .font(.system(size: 32, weight: .medium))
                            Text("Trackers Prevented")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "shield.checkerboard")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 4. WebView Implementation
struct SafariWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: SafariViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView
        webView.navigationDelegate = context.coordinator
        
        // Observe properties for UI updates
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No Op: Changes are driven by ViewModel's `load` function
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SafariWebViewRepresentable
        
        init(_ parent: SafariWebViewRepresentable) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            DispatchQueue.main.async {
                if keyPath == "estimatedProgress" {
                    self.parent.viewModel.progress = self.parent.viewModel.webView.estimatedProgress
                } else if keyPath == "url" {
                    if let url = self.parent.viewModel.webView.url {
                        self.parent.viewModel.urlString = url.absoluteString
                    }
                }
                self.parent.viewModel.canGoBack = self.parent.viewModel.webView.canGoBack
                self.parent.viewModel.canGoForward = self.parent.viewModel.webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.viewModel.isLoading = true }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.viewModel.isLoading = false }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.viewModel.isLoading = false }
        }
    }
}

// MARK: - Data Models
struct FavoriteItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let url: String
}

struct FavoritesData {
    static let list = [
        FavoriteItem(name: "Apple", icon: "apple.logo", color: .gray, url: "apple.com"),
        FavoriteItem(name: "Google", icon: "globe", color: .blue, url: "google.com"),
        FavoriteItem(name: "Bing", icon: "magnifyingglass", color: .teal, url: "bing.com"),
        FavoriteItem(name: "Wikipedia", icon: "book.fill", color: .black, url: "wikipedia.org"),
        FavoriteItem(name: "ESPN", icon: "sportscourt.fill", color: .red, url: "espn.com"),
        FavoriteItem(name: "Reddit", icon: "face.smiling.inverse", color: .orange, url: "reddit.com"),
        FavoriteItem(name: "X", icon: "bird.fill", color: .black, url: "x.com"),
        FavoriteItem(name: "Weather", icon: "cloud.sun.fill", color: .blue, url: "weather.com")
    ]
}

#Preview {
    SafariView()
}
