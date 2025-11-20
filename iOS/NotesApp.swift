import SwiftUI
import Combine

// MARK: - Models

struct Note: Identifiable, Hashable, Codable {
    let id: UUID
    var content: String
    var lastModified: Date
    
    init(id: UUID = UUID(), content: String, lastModified: Date = Date()) {
        self.id = id
        self.content = content
        self.lastModified = lastModified
    }
    
    var title: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "New Note" }
        return trimmed.components(separatedBy: .newlines).first ?? "New Note"
    }
    
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)
        guard lines.count > 1 else { return "No additional text" }
        return lines.dropFirst().joined(separator: " ")
    }
}

// MARK: - Manager

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    
    init() {
        // Default Mock Data
        notes = [
            Note(content: "Project Ideas 💡\n1. Weather App Clone\n2. Calendar App Clone\n3. Notes App Fixes", lastModified: Date()),
            Note(content: "Shopping List\nMilk\nCoffee Beans\nEggs", lastModified: Date().addingTimeInterval(-86400))
        ]
    }
    
    func createNote() -> Note {
        let newNote = Note(content: "", lastModified: Date())
        // Insert at top
        notes.insert(newNote, at: 0)
        return newNote
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.lastModified = Date()
            notes[index] = updatedNote
        }
    }
}

// MARK: - 1. Folders View (Root)

struct NotesView: View {
    @StateObject private var manager = NotesManager()
    // Modern Navigation Path to handle pushes programmatically
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                Section {
                    // We use a value-based navigation link here
                    NavigationLink(value: "NotesList") {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                            Text("Notes")
                                .padding(.leading, 5)
                            Spacer()
                            Text("\(manager.notes.count)")
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("iCloud")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .offset(x: -18)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {}.foregroundStyle(.yellow)
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            // Define Destinations
            .navigationDestination(for: String.self) { value in
                if value == "NotesList" {
                    NotesListView(manager: manager, navPath: $navPath)
                }
            }
            .navigationDestination(for: Note.self) { note in
                NoteEditorView(note: note, manager: manager)
            }
        }
        .accentColor(.yellow)
    }
}

// MARK: - 2. Notes List View

struct NotesListView: View {
    @ObservedObject var manager: NotesManager
    @Binding var navPath: NavigationPath
    @State private var searchText = ""
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return manager.notes
        } else {
            return manager.notes.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredNotes) { note in
                // FIX: Set alignment to .leading so short notes don't center
                ZStack(alignment: .leading) {
                    NavigationLink(value: note) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    NoteRow(note: note)
                }
                // iOS Notes style insets
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 0))
                // Make the separator follow the text indentation
                .alignmentGuide(.listRowSeparatorLeading) { _ in 20 }
            }
            .onDelete(perform: manager.deleteNote)
        }
        .listStyle(.plain)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.yellow)
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Text("\(manager.notes.count) Notes")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                    
                    Button(action: {
                        let newNote = manager.createNote()
                        navPath.append(newNote)
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(.primary)
            
            HStack(spacing: 6) {
                Text(formatDate(note.lastModified))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                // Keep date from shrinking too much
                    .fixedSize()
                
                Text(note.preview)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        // FIX: Force the row to take up full width to prevent centering issues
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .numeric, time: .omitted)
        }
    }
}

// MARK: - 4. Editor View

struct NoteEditorView: View {
    @State var note: Note
    @ObservedObject var manager: NotesManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Sub-header for the date (mimicking iOS style below the large title)
            Text(formatDate(note.lastModified))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            
            TextEditor(text: $note.content)
                .font(.body)
                .padding(.horizontal)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .systemBackground))
                .focused($isFocused)
                .onChange(of: note.content) { _ in
                    manager.updateNote(note)
                }
        }
        // 1. Set the dynamic title
        .navigationTitle(note.title)
        // 2. Make it Large
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    isFocused = false
                }
                .fontWeight(.bold)
                .foregroundStyle(.yellow)
            }
            
            ToolbarItem(placement: .bottomBar) {
                HStack(spacing: 25) {
                    Image(systemName: "checklist")
                    Image(systemName: "camera")
                    Image(systemName: "pencil.tip.crop.circle")
                    Image(systemName: "square.and.arrow.up")
                    Spacer()
                    Image(systemName: "square.and.pencil")
                }
                .font(.title3)
                .foregroundStyle(.yellow)
            }
        }
        .onAppear {
            if note.content.isEmpty {
                isFocused = true
            }
        }
        .onDisappear {
            manager.updateNote(note)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .shortened)
    }
}

#Preview {
    NotesView()
}
