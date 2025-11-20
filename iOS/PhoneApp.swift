import SwiftUI

// MARK: - Main Tab View
struct PhoneView: View {
    var body: some View {
        TabView {
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star.fill") }
            
            RecentsView()
                .tabItem { Label("Recents", systemImage: "clock.fill") }
            
            ContactsView()
                .tabItem { Label("Contacts", systemImage: "person.circle.fill") }
            
            KeypadView()
                .tabItem { Label("Keypad", systemImage: "circle.grid.3x3.fill") }
            
            VoicemailView()
                .tabItem { Label("Voicemail", systemImage: "recordingtape") }
        }
        .accentColor(.blue)
    }
}

// MARK: - 1. Keypad View (Highly Accurate)
struct KeypadView: View {
    @State private var number = ""
    
    // Grid Layout: 3 Columns, specifically spaced
    let columns = Array(repeating: GridItem(.fixed(78), spacing: 24), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Number Display Area
            VStack(spacing: 8) {
                Text(number)
                    .font(.system(size: 40, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                
                Button("Add Number") { }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .opacity(number.isEmpty ? 0 : 1)
                    .frame(height: 20)
            }
            .padding(.bottom, 20)
            
            // The Keypad Grid
            LazyVGrid(columns: columns, spacing: 16) {
                // Row 1
                KeypadButton(main: "1", sub: "") { append("1") }
                KeypadButton(main: "2", sub: "A B C") { append("2") }
                KeypadButton(main: "3", sub: "D E F") { append("3") }
                
                // Row 2
                KeypadButton(main: "4", sub: "G H I") { append("4") }
                KeypadButton(main: "5", sub: "J K L") { append("5") }
                KeypadButton(main: "6", sub: "M N O") { append("6") }
                
                // Row 3
                KeypadButton(main: "7", sub: "P Q R S") { append("7") }
                KeypadButton(main: "8", sub: "T U V") { append("8") }
                KeypadButton(main: "9", sub: "W X Y Z") { append("9") }
                
                // Row 4
                KeypadButton(main: "*", sub: "", isSymbol: true) { append("*") }
                KeypadButton(main: "0", sub: "+") { append("0") }
                KeypadButton(main: "#", sub: "", isSymbol: true) { append("#") }
            }
            .padding(.bottom, 20)
            
            // Bottom Controls (Call / Delete)
            HStack {
                // Spacer to balance the delete button
                Color.clear
                    .frame(width: 78, height: 78)
                
                Spacer()
                
                // Call Button
                Button(action: {}) {
                    Circle()
                        .fill(Color.green) // iOS Green
                        .frame(width: 78, height: 78)
                        .overlay(
                            Image(systemName: "phone.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(IOSButtonStyle()) // Adds the dimming effect
                
                Spacer()
                
                // Backspace Button
                Button(action: {
                    if !number.isEmpty { number.removeLast() }
                }) {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color(uiColor: .systemGray3))
                        .frame(width: 78, height: 78)
                }
                .opacity(number.isEmpty ? 0 : 1)
                .disabled(number.isEmpty)
            }
            .padding(.horizontal, 45) // Aligns with the outer grid edges
            .padding(.bottom, 80) // Tab bar clearance
        }
    }
    
    func append(_ val: String) {
        if number.count < 15 { number += val }
    }
}

// Custom Button Style to replicate iOS Tap Dimming
struct IOSButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct KeypadButton: View {
    let main: String
    let sub: String
    var isSymbol: Bool = false
    let action: () -> Void
    
    // Exact iOS Colors
    let lightGray = Color(red: 229/255, green: 229/255, blue: 229/255)
    let darkGray = Color(red: 50/255, green: 50/255, blue: 50/255)
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? darkGray : lightGray)
                    .frame(width: 78, height: 78)
                
                VStack(spacing: 0) {
                    Text(main)
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(.primary)
                        .padding(.top, (sub.isEmpty && !isSymbol) ? 0 : (isSymbol ? 6 : 2))
                    
                    if !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5) // Spacing between letters
                            .foregroundStyle(.primary)
                            .padding(.bottom, 4)
                    }
                }
                // This offset corrects the visual center for numbers with letters
                .offset(y: sub.isEmpty ? 0 : -2)
            }
        }
        .buttonStyle(IOSButtonStyle())
    }
}

// MARK: - 2. Recents View (Accurate Navigation)
struct RecentsView: View {
    @State private var filter = 0 // 0 = All, 1 = Missed
    
    // Mock Data
    let recentCalls = [
        RecentItem(name: "Pallav Agarwal", label: "mobile", date: "12:42 PM", type: .missed),
        RecentItem(name: "Mom", label: "home", date: "Yesterday", type: .outgoing),
        RecentItem(name: "Craig Federighi", label: "work", date: "Friday", type: .incoming),
        RecentItem(name: "Tim Cook", label: "iPhone", date: "Friday", type: .incoming),
        RecentItem(name: "+1 (555) 123-4567", label: "Cupertino, CA", date: "Thursday", type: .missed)
    ]
    
    var filteredCalls: [RecentItem] {
        filter == 1 ? recentCalls.filter { $0.type == .missed } : recentCalls
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCalls) { call in
                    HStack(spacing: 12) {
                        // Call Type Icon
                        if call.type == .outgoing {
                            Image(systemName: "phone.arrow.up.right.fill")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .frame(width: 12)
                        } else {
                            Spacer().frame(width: 12)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(call.name)
                                .font(.headline)
                                .foregroundStyle(call.type == .missed ? .red : .primary)
                            
                            Text(call.label)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text(call.date)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            Button(action: {}) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Recents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: $filter) {
                        Text("All").tag(0)
                        Text("Missed").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {}
                }
            }
        }
    }
}

struct RecentItem: Identifiable {
    let id = UUID()
    let name: String
    let label: String
    let date: String
    let type: CallType
    enum CallType { case incoming, outgoing, missed }
}

// MARK: - 3. Contacts View
struct ContactsView: View {
    @State private var searchText = ""
    
    let contacts = ["Aaron", "Adam", "Brian", "Bob", "Charlie", "Craig Federighi", "David", "Emily", "Frank", "Greg", "Harry", "Ian", "John Appleseed", "Jony Ive", "Kate", "Larry", "Mike", "Nancy", "Oscar", "Pallav Agarwal", "Paul", "Quincy", "Rachel", "Steve Jobs", "Tim Cook", "Ursula", "Victor", "Wendy", "Xavier", "Yvonne", "Zach"]
    
    var groupedContacts: [String: [String]] {
        Dictionary(grouping: contacts, by: { String($0.prefix(1)) })
    }
    
    var sortedKeys: [String] {
        groupedContacts.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // My Card
                Section {
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(Text("JA").font(.title2).bold().foregroundStyle(.white))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("John Appleseed")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("My Card")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(sortedKeys, id: \.self) { key in
                    Section(header: Text(key).fontWeight(.bold)) {
                        ForEach(groupedContacts[key]!, id: \.self) { contact in
                            Text(contact)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Groups") {}
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
        }
    }
}

// MARK: - 4. Voicemail
struct VoicemailView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Spacer()
                
                Text("Call Voicemail")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .systemGray6))
                    )
                
                Spacer()
            }
            .navigationTitle("Voicemail")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Greeting") {}
                }
            }
        }
    }
}

// MARK: - 5. Favorites
struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<3) { _ in
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 35, height: 35)
                            .overlay(Text("TC").font(.caption).bold())
                        
                        VStack(alignment: .leading) {
                            Text("Tim Cook")
                                .fontWeight(.bold)
                            HStack {
                                Image(systemName: "iphone")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("mobile")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                            .font(.title2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
        }
    }
}

#Preview {
    PhoneView()
}
