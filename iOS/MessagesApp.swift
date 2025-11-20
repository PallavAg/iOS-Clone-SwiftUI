import SwiftUI
import Combine

// MARK: - Models

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool // True = Blue Bubble, False = Gray Bubble
    let date: Date
}

struct Conversation: Identifiable {
    let id = UUID()
    let contactName: String
    let avatarColor: Color
    var messages: [Message]
    var isUnread: Bool
    
    var lastMessage: String {
        messages.last?.content ?? ""
    }
    
    var lastDate: Date {
        messages.last?.date ?? Date()
    }
}

// MARK: - View Model (The Brain)

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var activeConversation: Conversation
    @Published var isTyping: Bool = false
    
    // We'll simulate a list for the inbox, but focus on one active chat
    @Published var inbox: [Conversation] = [
        Conversation(contactName: "Tim Cook", avatarColor: .gray, messages: [
            Message(content: "Good morning! Big announcements coming.", isUser: false, date: Date().addingTimeInterval(-86400))
        ], isUnread: false)
    ]
    
    init() {
        // The active AI chat
        self.activeConversation = Conversation(
            contactName: "Buddy Bard",
            avatarColor: .blue,
            messages: [
                Message(content: "Hey! I'm connected to Pollinations AI. Text me anything.", isUser: false, date: Date())
            ],
            isUnread: false
        )
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 1. Add User Message locally
        let userMsg = Message(content: text, isUser: true, date: Date())
        withAnimation {
            activeConversation.messages.append(userMsg)
        }
        
        // 2. Trigger AI
        isTyping = true
        
        Task {
            // 3. Call Pollinations API
            let aiResponseText = await fetchAIResponse(prompt: text)
            
            // 4. Add AI Message
            try? await Task.sleep(nanoseconds: 500_000_000) // Natural pause
            
            withAnimation {
                isTyping = false
                let aiMsg = Message(content: aiResponseText, isUser: false, date: Date())
                activeConversation.messages.append(aiMsg)
            }
        }
    }
    
    private func fetchAIResponse(prompt: String) async -> String {
        // Pollinations API: GET https://text.pollinations.ai/{prompt}?model=openai-fast
        guard let encodedPrompt = prompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://text.pollinations.ai/\(encodedPrompt)?model=openai-fast") else {
            return "Error: Invalid URL"
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let responseString = String(data: data, encoding: .utf8) {
                return responseString
            }
        } catch {
            print("API Error: \(error)")
        }
        return "Sorry, I couldn't connect to the network."
    }
}

// MARK: - Main Views

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // The Active AI Thread
                NavigationLink(destination: ChatDetailView(viewModel: viewModel)) {
                    InboxRow(conversation: viewModel.activeConversation)
                }
                
                // Mock Threads
                ForEach(viewModel.inbox) { convo in
                    InboxRow(conversation: convo)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") {}
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "square.and.pencil") }
                }
            }
        }
        .accentColor(.blue)
    }
}

struct InboxRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(conversation.avatarColor.gradient)
                .frame(width: 45, height: 45)
                .overlay(
                    Text(String(conversation.contactName.prefix(1)))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.contactName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDate(conversation.lastDate))
                        .font(.subheadline)
                        .foregroundStyle(conversation.isUnread ? .blue : .secondary)
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(conversation.isUnread ? .primary : .secondary)
                    .lineLimit(2)
                    .fontWeight(conversation.isUnread ? .bold : .regular)
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .numeric, time: .omitted)
        }
    }
}

// MARK: - Chat Detail View

struct ChatDetailView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        // Date Header Mock
                        Text("Today \(Date().formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                        
                        ForEach(viewModel.activeConversation.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                .onChange(of: viewModel.activeConversation.messages.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isTyping) { typing in
                    if typing { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }
            
            // Input Bar
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .bottom, spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(uiColor: .systemGray2))
                            .frame(height: 36)
                    }
                    .padding(.bottom, 5)
                    
                    // Text Field
                    ZStack(alignment: .trailing) {
                        TextField("iMessage", text: $inputText, axis: .vertical)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .strokeBorder(Color(uiColor: .systemGray4), lineWidth: 1)
                            )
                            .focused($isFocused)
                            .lineLimit(1...5)
                        
                        // Send Button inside the capsule area visually, or next to it?
                        // iOS 17 style: Send button is outside if there is text, or hidden
                    }
                    
                    if !inputText.isEmpty {
                        Button(action: {
                            viewModel.sendMessage(inputText)
                            inputText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                        }
                        .padding(.bottom, 3)
                        .transition(.scale)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground)) // Opaque background for bar
            }
        }
        .navigationTitle(viewModel.activeConversation.contactName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: Text("Contact Info")) {
                    Image(systemName: "person.circle")
                        .font(.title3)
                }
            }
        }
    }
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastId = viewModel.activeConversation.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Components

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundStyle(message.isUser ? .white : .primary)
                .background(
                    message.isUser ?
                    AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .top, endPoint: .bottom)) :
                        AnyShapeStyle(Color(uiColor: .systemGray5))
                )
                .clipShape(ChatBubbleShape(isUser: message.isUser))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
        .padding(.vertical, 2)
    }
}

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .opacity(0.5)
                        .scaleEffect(dotOffset == CGFloat(index) ? 1.2 : 0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemGray5))
            .clipShape(ChatBubbleShape(isUser: false))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                    dotOffset = 2
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// Custom Shape for the "Tail" effect
struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius: CGFloat = 18
        
        let path = UIBezierPath()
        
        if isUser {
            // Right Bubble
            path.move(to: CGPoint(x: width - 4, y: height))
            path.addCurve(to: CGPoint(x: width, y: height - 4),
                          controlPoint1: CGPoint(x: width - 2, y: height),
                          controlPoint2: CGPoint(x: width, y: height - 1))
            path.addLine(to: CGPoint(x: width, y: radius))
            path.addArc(withCenter: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: 0, endAngle: -.pi/2, clockwise: false)
            path.addLine(to: CGPoint(x: radius, y: 0))
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: -.pi/2, endAngle: .pi, clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: height - radius))
            path.addArc(withCenter: CGPoint(x: radius, y: height - radius), radius: radius, startAngle: .pi, endAngle: .pi/2, clockwise: false)
            path.addLine(to: CGPoint(x: width - 12, y: height))
            // Tail
            path.addQuadCurve(to: CGPoint(x: width - 4, y: height), controlPoint: CGPoint(x: width - 8, y: height))
        } else {
            // Left Bubble
            path.move(to: CGPoint(x: 4, y: height))
            path.addCurve(to: CGPoint(x: 0, y: height - 4),
                          controlPoint1: CGPoint(x: 2, y: height),
                          controlPoint2: CGPoint(x: 0, y: height - 1))
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: .pi, endAngle: -.pi/2, clockwise: true)
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(withCenter: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: -.pi/2, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: width, y: height - radius))
            path.addArc(withCenter: CGPoint(x: width - radius, y: height - radius), radius: radius, startAngle: 0, endAngle: .pi/2, clockwise: true)
            path.addLine(to: CGPoint(x: 12, y: height))
            // Tail
            path.addQuadCurve(to: CGPoint(x: 4, y: height), controlPoint: CGPoint(x: 8, y: height))
        }
        
        return Path(path.cgPath)
    }
}

#Preview {
    MessagesView()
}
