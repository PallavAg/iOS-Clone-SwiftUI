import SwiftUI
import Combine

// MARK: - Main Tab View
struct ClockView: View {
    var body: some View {
        TabView {
            WorldClockView()
                .tabItem { Label("World Clock", systemImage: "globe") }
            AlarmView()
                .tabItem { Label("Alarm", systemImage: "alarm.fill") }
            StopwatchView()
                .tabItem { Label("Stopwatch", systemImage: "stopwatch.fill") }
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
        }
        .accentColor(.orange)
        .preferredColorScheme(.dark) // Clock app is always dark
    }
}

// MARK: - 1. World Clock View
struct WorldClockView: View {
    @State private var date = Date()
    
    // Timer to keep the clock ticking every minute
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            List {
                // Mock Data
                WorldClockRow(city: "New York", timeZoneOffset: 0, date: date)
                WorldClockRow(city: "Cupertino", timeZoneOffset: -3 * 3600, date: date)
                WorldClockRow(city: "London", timeZoneOffset: 5 * 3600, date: date)
                WorldClockRow(city: "Tokyo", timeZoneOffset: 13 * 3600, date: date)
                WorldClockRow(city: "Sydney", timeZoneOffset: 15 * 3600, date: date)
            }
            .listStyle(.plain)
            .navigationTitle("World Clock")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton().foregroundStyle(.orange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: { Image(systemName: "plus") }
                        .foregroundStyle(.orange)
                }
            }
            .onReceive(timer) { input in
                date = input
            }
        }
    }
}

struct WorldClockRow: View {
    let city: String
    let timeZoneOffset: TimeInterval
    let date: Date
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                // Calculate relative time text (Today/Tomorrow)
                let hoursDiff = Int(timeZoneOffset / 3600)
                let sign = hoursDiff >= 0 ? "+" : ""
                
                Text("Today, \(sign)\(hoursDiff)HRS")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.gray)
                
                Text(city)
                    .font(.system(size: 28, weight: .regular))
            }
            
            Spacer()
            
            Text(date.addingTimeInterval(timeZoneOffset).formatted(date: .omitted, time: .shortened))
                .font(.system(size: 54, weight: .thin))
                .monospacedDigit() // Prevents jitter
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 2. Alarm View
struct AlarmView: View {
    @State private var alarms = [
        AlarmModel(time: Date(), label: "Alarm", isEnabled: true),
        AlarmModel(time: Date().addingTimeInterval(3600), label: "Work", isEnabled: false),
        AlarmModel(time: Date().addingTimeInterval(7200), label: "Gym", isEnabled: true)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Sleep | Wake Up").font(.subheadline).fontWeight(.semibold).foregroundStyle(.orange)) {
                    HStack {
                        Text("No Alarm")
                            .foregroundStyle(.gray)
                        Spacer()
                        Button("SET UP") { }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                Section(header: Text("Other").font(.subheadline).fontWeight(.semibold)) {
                    ForEach($alarms) { $alarm in
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .firstTextBaseline, spacing: 0) {
                                    Text(alarm.time, format: .dateTime.hour().minute())
                                        .font(.system(size: 54, weight: .light))
                                }
                                .foregroundStyle(alarm.isEnabled ? .white : .gray)
                                
                                Text(alarm.label)
                                    .font(.subheadline)
                                    .foregroundStyle(alarm.isEnabled ? .white : .gray)
                            }
                            Spacer()
                            Toggle("", isOn: $alarm.isEnabled)
                                .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { alarms.remove(atOffsets: $0) }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Alarm")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton().foregroundStyle(.orange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: { Image(systemName: "plus") }
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

struct AlarmModel: Identifiable {
    let id = UUID()
    var time: Date
    var label: String
    var isEnabled: Bool
}

// MARK: - 3. Stopwatch View
struct StopwatchView: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var laps: [Lap] = []
    // The timer publisher
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Digital Clock
            Text(formatTime(elapsedTime))
                .font(.system(size: 88, weight: .thin))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Controls
            HStack {
                // Lap / Reset Button
                CircleButton(
                    title: isRunning ? "Lap" : "Reset",
                    textColor: .white,
                    backgroundColor: Color(white: 0.2)
                ) {
                    if isRunning {
                        // Record Lap
                        let newLap = Lap(count: laps.count + 1, time: elapsedTime)
                        laps.insert(newLap, at: 0)
                    } else {
                        // Reset
                        elapsedTime = 0
                        laps.removeAll()
                    }
                }
                
                Spacer()
                
                // Start / Stop Button
                CircleButton(
                    title: isRunning ? "Stop" : "Start",
                    textColor: isRunning ? .red : .green,
                    backgroundColor: isRunning ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
                ) {
                    isRunning.toggle()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            Divider()
                .background(Color.gray)
            
            // Laps List
            List {
                ForEach(laps) { lap in
                    HStack {
                        Text("Lap \(lap.count)")
                        Spacer()
                        Text(formatTime(lap.time))
                            .monospacedDigit()
                    }
                    .listRowBackground(Color.black)
                }
            }
            .listStyle(.plain)
            .frame(height: 300)
        }
        .padding()
        .onReceive(timer) { _ in
            if isRunning {
                elapsedTime += 0.01
            }
        }
    }
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct Lap: Identifiable {
    let id = UUID()
    let count: Int
    let time: TimeInterval
}

// MARK: - 4. Timer View
struct TimerView: View {
    // Time Selection
    @State private var selectedHours = 0
    @State private var selectedMinutes = 15
    @State private var selectedSeconds = 0
    
    // Timer State
    @State private var timerState: TimerState = .idle
    @State private var totalDuration: TimeInterval = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var endTime: Date?
    
    // Timer Publisher
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    enum TimerState {
        case idle
        case running
        case paused
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Main Display Area (Picker or Progress)
            ZStack {
                if timerState == .idle {
                    // 1. Time Picker
                    HStack(spacing: 0) {
                        timePickerComponent(selection: $selectedHours, range: 0...23, label: "hours")
                        timePickerComponent(selection: $selectedMinutes, range: 0...59, label: "min")
                        timePickerComponent(selection: $selectedSeconds, range: 0...59, label: "sec")
                    }
                    .padding(.horizontal)
                } else {
                    // 2. Progress Ring
                    ZStack {
                        // Background Track
                        Circle()
                            .stroke(Color.orange.opacity(0.15), lineWidth: 8)
                        
                        // Progress Track
                        Circle()
                            .trim(from: 0, to: CGFloat(timeRemaining / totalDuration))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: timeRemaining)
                        
                        // Digital Readout
                        VStack(spacing: 10) {
                            Text(formatDuration(timeRemaining))
                                .font(.system(size: 80, weight: .thin))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "bell.fill")
                                    .font(.subheadline)
                                Text(getEndTimeString())
                                    .font(.title3)
                                    .fontWeight(.regular)
                            }
                            .foregroundStyle(.gray)
                        }
                    }
                    .padding(40)
                }
            }
            .frame(maxHeight: .infinity)
            
            // MARK: - Options List (Label / Sound)
            // Only show reduced options when running to match iOS behavior
            VStack(spacing: 1) {
                NavigationLink(destination: Text("Label")) {
                    HStack {
                        Text("Label")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Timer")
                            .foregroundStyle(.gray)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill))
                }
                
                NavigationLink(destination: Text("Radar")) {
                    HStack {
                        Text("When Timer Ends")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Radar")
                            .foregroundStyle(.gray)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom, 40)
            .opacity(timerState == .idle ? 1.0 : 0.0) // Hide nicely when running if desired, or keep visible
            .frame(height: timerState == .idle ? nil : 0) // Collapse when running
            .clipped()
            
            // MARK: - Control Buttons
            HStack {
                // Left Button (Cancel)
                Button(action: cancelTimer) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 80, height: 80)
                        
                        // Double ring effect
                        Circle()
                            .stroke(Color.black, lineWidth: 0)
                            .frame(width: 76, height: 76)
                        
                        Text("Cancel")
                            .font(.title3)
                            .foregroundStyle(.white) // Active when running
                    }
                }
                .disabled(timerState == .idle)
                .opacity(timerState == .idle ? 0.6 : 1.0)
                
                Spacer()
                
                // Right Button (Start / Pause / Resume)
                Button(action: toggleTimer) {
                    ZStack {
                        Circle()
                            .fill(rightButtonColor.opacity(0.25))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(Color.black, lineWidth: 0)
                            .frame(width: 76, height: 76)
                        
                        Text(rightButtonLabel)
                            .font(.title3)
                            .foregroundStyle(rightButtonColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
    }
    
    // MARK: - Subviews
    
    // Helper to create aligned pickers
    func timePickerComponent(selection: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Picker("", selection: selection) {
                    ForEach(range, id: \.self) { i in
                        Text("\(i)").tag(i)
                            .foregroundStyle(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: geo.size.width / 2 + 15, alignment: .trailing)
                .clipped()
                
                Text(label)
                    .font(.system(size: 17, weight: .medium))
                    .padding(.top, 3)
                    .frame(width: geo.size.width / 2 - 15, alignment: .leading)
                    .padding(.leading, 4)
            }
        }
    }
    
    // MARK: - Logic
    
    var rightButtonLabel: String {
        switch timerState {
            case .idle, .paused: return "Start"
            case .running: return "Pause"
        }
    }
    
    var rightButtonColor: Color {
        switch timerState {
            case .idle, .paused: return .green
            case .running: return .orange
        }
    }
    
    func toggleTimer() {
        switch timerState {
            case .idle:
                // Start fresh
                totalDuration = TimeInterval(selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds)
                guard totalDuration > 0 else { return }
                timeRemaining = totalDuration
                endTime = Date().addingTimeInterval(totalDuration)
                timerState = .running
                
            case .running:
                // Pause
                timerState = .paused
                // timeRemaining stays static here
                
            case .paused:
                // Resume
                endTime = Date().addingTimeInterval(timeRemaining)
                timerState = .running
        }
    }
    
    func cancelTimer() {
        timerState = .idle
        timeRemaining = 0
        endTime = nil
    }
    
    func updateTimer() {
        guard timerState == .running, let end = endTime else { return }
        
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            timerState = .idle
            // In a real app, trigger sound here
        } else {
            timeRemaining = remaining
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(ceil(duration))
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    func getEndTimeString() -> String {
        guard let end = endTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: end)
    }
}

// MARK: - Reusable Components

struct CircleButton: View {
    let title: String
    let textColor: Color
    let backgroundColor: Color
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 80, height: 80)
                
                // The "Double Ring" effect
                Circle()
                    .stroke(backgroundColor, lineWidth: 0)
                    .frame(width: 86, height: 86)
                
                Text(title)
                    .foregroundStyle(disabled ? .gray : textColor)
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}

#Preview {
    ClockView()
}
