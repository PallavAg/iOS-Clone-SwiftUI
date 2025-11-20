import SwiftUI

struct SettingsView: View {
    // Global Connectivity State
    @State private var airplaneMode = false
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = true
    @State private var cellularData = true
    @State private var personalHotspot = false
    
    // UI State
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Header / Search
                Section {
                    NavigationLink(destination: AppleIDView()) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(Color(uiColor: .systemGray4))
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("John Appleseed")
                                    .font(.title2)
                                    .fontWeight(.regular)
                                Text("Apple ID, iCloud+, Media & Purchases")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: Text("Family")) {
                        HStack(spacing: 15) {
                            HStack(spacing: -8) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                        .overlay(Image(systemName: "person.fill").font(.caption2).foregroundStyle(.gray))
                                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                                }
                            }
                            Text("Family")
                        }
                    }
                }
                
                // MARK: - Connectivity Section
                Section {
                    // Airplane Mode Logic
                    Toggle(isOn: $airplaneMode) {
                        SettingsIcon(icon: "airplane", color: .orange, title: "Airplane Mode")
                    }
                    .onChange(of: airplaneMode) { isActive in
                        if isActive {
                            withAnimation {
                                wifiEnabled = false
                                bluetoothEnabled = false
                                cellularData = false
                                personalHotspot = false
                            }
                        } else {
                            // Restore defaults when turning off
                            wifiEnabled = true
                            bluetoothEnabled = true
                            cellularData = true
                        }
                    }
                    
                    // Wi-Fi
                    NavigationLink(destination: WifiView(isEnabled: $wifiEnabled, airplaneMode: airplaneMode)) {
                        HStack {
                            SettingsIcon(icon: "wifi", color: .blue, title: "Wi-Fi")
                            Spacer()
                            Text(getStatusText(enabled: wifiEnabled, active: "Home Network"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Bluetooth
                    NavigationLink(destination: BluetoothView(isEnabled: $bluetoothEnabled, airplaneMode: airplaneMode)) {
                        HStack {
                            SettingsIcon(icon: "dot.radiowaves.left.and.right", color: .blue, title: "Bluetooth")
                            Spacer()
                            Text(getStatusText(enabled: bluetoothEnabled, active: "On"))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Cellular
                    NavigationLink(destination: Text("Cellular Settings")) {
                        HStack {
                            SettingsIcon(icon: "antenna.radiowaves.left.and.right", color: .green, title: "Cellular")
                            Spacer()
                            if airplaneMode { Text("Off").foregroundStyle(.secondary) }
                        }
                    }
                    
                    // Hotspot
                    NavigationLink(destination: Text("Hotspot Settings")) {
                        HStack {
                            SettingsIcon(icon: "personalhotspot", color: .green, title: "Personal Hotspot")
                            Spacer()
                            Text(airplaneMode ? "Off" : "Off").foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Notifications Section
                Section {
                    NavigationLink(destination: Text("Notifications")) {
                        SettingsIcon(icon: "bell.badge.fill", color: .red, title: "Notifications")
                    }
                    NavigationLink(destination: SoundsView()) {
                        SettingsIcon(icon: "speaker.wave.2.fill", color: .pink, title: "Sounds & Haptics")
                    }
                    NavigationLink(destination: Text("Focus")) {
                        SettingsIcon(icon: "moon.fill", color: .indigo, title: "Focus")
                    }
                    NavigationLink(destination: Text("Screen Time")) {
                        SettingsIcon(icon: "hourglass", color: .indigo, title: "Screen Time")
                    }
                }
                
                // MARK: - General Section
                Section {
                    NavigationLink(destination: GeneralView()) {
                        SettingsIcon(icon: "gear", color: .gray, title: "General")
                    }
                    NavigationLink(destination: Text("Control Center")) {
                        SettingsIcon(icon: "switch.2", color: .gray, title: "Control Center")
                    }
                    NavigationLink(destination: DisplayView()) {
                        SettingsIcon(icon: "textformat.size", color: .blue, title: "Display & Brightness")
                    }
                    NavigationLink(destination: Text("Home Screen")) {
                        SettingsIcon(icon: "apps.iphone", color: .indigo, title: "Home Screen & App Library")
                    }
                    NavigationLink(destination: Text("Accessibility")) {
                        SettingsIcon(icon: "accessibility", color: .blue, title: "Accessibility")
                    }
                    NavigationLink(destination: Text("Wallpaper")) {
                        SettingsIcon(icon: "photo.on.rectangle", color: .cyan, title: "Wallpaper")
                    }
                    NavigationLink(destination: Text("StandBy")) {
                        SettingsIcon(icon: "clock.fill", color: .black, title: "StandBy")
                    }
                    NavigationLink(destination: BatteryView()) {
                        SettingsIcon(icon: "battery.100", color: .green, title: "Battery")
                    }
                    NavigationLink(destination: Text("Privacy")) {
                        SettingsIcon(icon: "hand.raised.fill", color: .blue, title: "Privacy & Security")
                    }
                }
                
                // MARK: - Stores
                Section {
                    NavigationLink(destination: Text("App Store")) {
                        SettingsIcon(icon: "apple.logo", color: .blue, title: "App Store")
                    }
                    NavigationLink(destination: Text("Wallet")) {
                        SettingsIcon(icon: "creditcard.fill", color: .black, title: "Wallet & Apple Pay")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
    
    func getStatusText(enabled: Bool, active: String) -> String {
        if airplaneMode { return "Off" }
        if !enabled { return "Off" }
        return active
    }
}

// MARK: - 2. Helper Components

struct SettingsIcon: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 15)
                .padding(6)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
                .font(.body)
        }
    }
}

// MARK: - 3. Connectivity Detail Views

struct WifiView: View {
    @Binding var isEnabled: Bool
    let airplaneMode: Bool
    @State private var currentNetwork: String? = "Home Network"
    
    let networks = ["Starbucks WiFi", "Office 5G", "xfinitywifi", "Linksys-0482"]
    
    var body: some View {
        List {
            Section {
                Toggle("Wi-Fi", isOn: $isEnabled)
                    .disabled(airplaneMode)
            }
            
            if airplaneMode {
                Section {
                    Text("Wi-Fi needs to be enabled in Control Center or Settings to connect to Wi-Fi networks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            } else if isEnabled {
                // Current Network
                if let current = currentNetwork {
                    Section(header: Text("Current Network")) {
                        HStack {
                            Text(current)
                                .foregroundStyle(.blue)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                // Available Networks
                Section(header: Text("Networks")) {
                    ForEach(networks, id: \.self) { network in
                        Button(action: {
                            withAnimation { currentNetwork = network }
                        }) {
                            HStack {
                                Text(network)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "wifi")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                Section {
                    NavigationLink("Ask to Join Networks") { }
                    NavigationLink("Auto-Join Hotspot") { }
                }
            }
        }
        .navigationTitle("Wi-Fi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BluetoothView: View {
    @Binding var isEnabled: Bool
    let airplaneMode: Bool
    
    var body: some View {
        List {
            Section {
                Toggle("Bluetooth", isOn: $isEnabled)
                    .disabled(airplaneMode)
            }
            
            if isEnabled && !airplaneMode {
                Section(header: Text("My Devices")) {
                    DeviceRow(name: "AirPods Pro", status: "Connected")
                    DeviceRow(name: "Apple Watch", status: "Connected")
                    DeviceRow(name: "Tesla Model 3", status: "Not Connected")
                    DeviceRow(name: "MX Master 3S", status: "Not Connected")
                }
            } else {
                Section {
                    Text("AirDrop, AirPlay, Find My, and location services use Bluetooth.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeviceRow: View {
    let name: String
    let status: String
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(status).foregroundStyle(.secondary)
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
                .padding(.leading, 8)
        }
    }
}

// MARK: - 4. General Detail Views

struct GeneralView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("About", destination: AboutView())
                NavigationLink("Software Update", destination: SoftwareUpdateView())
            }
            Section {
                NavigationLink("AirDrop", destination: Text("AirDrop"))
                NavigationLink("AirPlay & Handoff", destination: Text("AirPlay"))
                NavigationLink("Picture in Picture", destination: Text("PiP"))
            }
            Section {
                NavigationLink("iPhone Storage", destination: StorageView())
                NavigationLink("Background App Refresh", destination: Text("Refresh"))
            }
            Section {
                NavigationLink("Date & Time", destination: Text("Time"))
                NavigationLink("Keyboard", destination: Text("Keyboard"))
                NavigationLink("Fonts", destination: Text("Fonts"))
                NavigationLink("Language & Region", destination: Text("Region"))
            }
            Section {
                NavigationLink("Transfer or Reset iPhone", destination: Text("Reset"))
            }
            Section {
                NavigationLink("Shut Down", destination: Text("Bye"))
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                InfoRow(label: "Name", value: "John's iPhone")
            }
            Section {
                InfoRow(label: "iOS Version", value: "17.2.1")
                InfoRow(label: "Model Name", value: "iPhone 15 Pro")
                InfoRow(label: "Model Number", value: "A2848")
                InfoRow(label: "Serial Number", value: "H4X0R1337")
            }
            Section {
                HStack { Text("Coverage"); Spacer(); Text("Expired").foregroundStyle(.secondary); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) }
            }
            Section {
                InfoRow(label: "Songs", value: "1,024")
                InfoRow(label: "Videos", value: "45")
                InfoRow(label: "Photos", value: "12,049")
                InfoRow(label: "Applications", value: "92")
                InfoRow(label: "Available", value: "120 GB")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

struct SoftwareUpdateView: View {
    @State private var loading = true
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            if loading {
                VStack(spacing: 15) {
                    ProgressView()
                    Text("Checking for Update...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else {
                VStack(spacing: 20) {
                    Spacer().frame(height: 40)
                    Image(systemName: "cube.box.fill") // Abstract icon for OS
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.gray)
                    
                    VStack(spacing: 5) {
                        Text("iOS 17.2.1")
                            .font(.title3).bold()
                        Text("iOS is up to date")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Software Update")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { loading = false }
            }
        }
    }
}

struct StorageView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("iPhone")
                            .font(.headline)
                        Spacer()
                        Text("128 GB Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Custom Storage Bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            Rectangle().fill(Color.red).frame(width: geo.size.width * 0.4)
                            Rectangle().fill(Color.yellow).frame(width: geo.size.width * 0.15)
                            Rectangle().fill(Color.gray).frame(width: geo.size.width * 0.15)
                            Rectangle().fill(Color(uiColor: .systemGray5))
                        }
                    }
                    .frame(height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    HStack(spacing: 15) {
                        LegendItem(color: .red, label: "Apps")
                        LegendItem(color: .yellow, label: "Photos")
                        LegendItem(color: .gray, label: "System")
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Recommendations")) {
                HStack {
                    Text("Review Large Attachments")
                    Spacer()
                    Text("3.2 GB").foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            
            Section(header: Text("Last Used")) {
                StorageAppRow(name: "Photos", size: "12.4 GB", icon: "photo.fill", color: .blue)
                StorageAppRow(name: "Messages", size: "5.1 GB", icon: "message.fill", color: .green)
                StorageAppRow(name: "Instagram", size: "2.2 GB", icon: "camera.fill", color: .purple)
            }
        }
        .navigationTitle("iPhone Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct StorageAppRow: View {
    let name: String
    let size: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(8)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            
            VStack(alignment: .leading) {
                Text(name)
                Text("Last used: Yesterday").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(size).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
    }
}

// MARK: - 5. Display & Battery

struct DisplayView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var brightness: Double = 0.7
    @State private var trueTone = true
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                HStack(spacing: 20) {
                    // Light Option
                    VStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(uiColor: .systemGray6))
                            .frame(height: 60)
                            .overlay(Image(systemName: "sun.max.fill").font(.largeTitle).foregroundStyle(.black))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDarkMode ? Color.clear : Color.blue, lineWidth: 2))
                            .onTapGesture { isDarkMode = false }
                        
                        Text("Light").font(.caption)
                        Image(systemName: !isDarkMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(!isDarkMode ? .blue : .gray)
                    }
                    
                    // Dark Option
                    VStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black)
                            .frame(height: 60)
                            .overlay(Image(systemName: "moon.fill").font(.largeTitle).foregroundStyle(.white))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDarkMode ? Color.blue : Color.clear, lineWidth: 2))
                            .onTapGesture { isDarkMode = true }
                        
                        Text("Dark").font(.caption)
                        Image(systemName: isDarkMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isDarkMode ? .blue : .gray)
                    }
                }
                .padding(.vertical, 8)
                
                Toggle("Automatic", isOn: .constant(true))
            }
            
            Section(header: Text("Brightness")) {
                HStack {
                    Image(systemName: "sun.min.fill").foregroundStyle(.secondary)
                    Slider(value: $brightness)
                    Image(systemName: "sun.max.fill").foregroundStyle(.secondary)
                }
                Toggle("True Tone", isOn: $trueTone)
            }
            
            Section {
                NavigationLink("Auto-Lock") {
                    List {
                        HStack { Text("30 Seconds"); Spacer() }
                        HStack { Text("1 Minute"); Spacer(); Image(systemName: "checkmark").foregroundStyle(.blue) }
                        HStack { Text("Never"); Spacer() }
                    }.navigationTitle("Auto-Lock")
                }
                NavigationLink("Raise to Wake") { }
            }
            
            Section {
                NavigationLink("Text Size") { }
                NavigationLink("Bold Text") { }
            }
        }
        .navigationTitle("Display & Brightness")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BatteryView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Battery Percentage")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
                HStack {
                    Text("Low Power Mode")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }
            }
            
            Section(header: Text("Health")) {
                HStack {
                    Text("Battery Health & Charging")
                    Spacer()
                    Text("98%")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            
            Section(header: Text("Last 24 Hours")) {
                VStack(alignment: .leading, spacing: 10) {
                    // Visual Mock of a Chart
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<12) { i in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i == 8 ? Color.blue : (i > 8 ? Color(uiColor: .systemGray4) : Color.green))
                                    .frame(height: CGFloat.random(in: 20...80))
                            }
                        }
                    }
                    .frame(height: 120)
                    
                    HStack {
                        Text("12 AM").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("6 AM").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("12 PM").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("6 PM").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
            }
            
            Section(header: Text("Activity By App")) {
                StorageAppRow(name: "Instagram", size: "34%", icon: "camera.fill", color: .purple)
                StorageAppRow(name: "TikTok", size: "22%", icon: "music.note", color: .black)
                StorageAppRow(name: "Messages", size: "12%", icon: "message.fill", color: .green)
                StorageAppRow(name: "Safari", size: "8%", icon: "safari", color: .blue)
            }
        }
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SoundsView: View {
    @State private var volume: Double = 0.5
    @State private var silentMode = false
    
    var body: some View {
        List {
            Section {
                Toggle("Silent Mode", isOn: $silentMode)
            }
            
            Section(header: Text("Ringer and Alerts")) {
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: $volume)
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                }
                Toggle("Change with Buttons", isOn: .constant(true))
            }
            
            Section {
                NavigationLink("Ringtone") {
                    List {
                        HStack { Text("Reflection"); Spacer(); Image(systemName: "checkmark").foregroundStyle(.blue) }
                        Text("Apex")
                        Text("Beacon")
                    }
                    .navigationTitle("Ringtone")
                }
                NavigationLink("Text Tone") {
                    List {
                        HStack { Text("Note"); Spacer(); Image(systemName: "checkmark").foregroundStyle(.blue) }
                        Text("Popcorn")
                    }.navigationTitle("Text Tone")
                }
            }
        }
        .navigationTitle("Sounds & Haptics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppleIDView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(Color(uiColor: .systemGray4))
                        .frame(width: 80, height: 80)
                    
                    Text("John Appleseed")
                        .font(.title)
                    Text("john.appleseed@icloud.com")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }
            
            Section {
                NavigationLink("Name, Phone Numbers, Email") {}
                NavigationLink("Password & Security") {}
                NavigationLink("Payment & Shipping") {}
                NavigationLink("Subscriptions") {}
            }
            
            Section {
                NavigationLink { } label: {
                    HStack {
                        SettingsIcon(icon: "icloud.fill", color: .blue, title: "iCloud")
                        Spacer()
                        Text("200 GB").foregroundStyle(.secondary)
                    }
                }
                SettingsIcon(icon: "film.fill", color: .pink, title: "Media & Purchases")
                SettingsIcon(icon: "mappin.and.ellipse", color: .green, title: "Find My")
                SettingsIcon(icon: "person.2.fill", color: .gray, title: "Family Sharing")
            }
            
            Section {
                Text("iPhone 15 Pro")
                Text("MacBook Pro 14\"")
                Text("John's iPad Air")
            }
            
            Section {
                Text("Sign Out")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Apple ID")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview
#Preview {
    SettingsView()
}
