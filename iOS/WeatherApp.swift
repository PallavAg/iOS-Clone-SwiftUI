import SwiftUI

// MARK: - Main View
struct WeatherView: View {
    var body: some View {
        ZStack {
            // 1. Dynamic Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "2E335A"), Color(hex: "1C1B33")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Main Scroll View
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Section
                    HeaderView()
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                    
                    // Hourly Section
                    HourlyForecastView()
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    // Daily Section (10-Day)
                    DailyForecastView()
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    // Details Grid (UV, Sunset, etc)
                    DetailsGridView()
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                    
                    // Bottom Toolbar Mock
                    HStack {
                        Image(systemName: "map")
                        Spacer()
                        Image(systemName: "list.bullet")
                    }
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark) // Forces white text/dark mode look
    }
}

// MARK: - Components

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Cupertino")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.white)
                .shadow(radius: 2)
            
            Text("75°")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(.white)
                .shadow(radius: 2)
            
            Text("Mostly Clear")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
            
            HStack(spacing: 8) {
                Text("H:82°")
                Text("L:68°")
            }
            .font(.title3.weight(.medium))
            .foregroundStyle(.white)
        }
    }
}

struct HourlyForecastView: View {
    let hours: [HourlyMock] = HourlyMock.generate()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 12)
                .padding(.leading, 15)
            
            Divider()
                .background(.white.opacity(0.2))
                .padding(.leading, 15)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 25) {
                    ForEach(hours) { hour in
                        VStack(spacing: 12) {
                            Text(hour.time)
                                .font(.system(size: 15, weight: .medium))
                            
                            Image(systemName: hour.icon)
                                .symbolRenderingMode(.multicolor)
                                .font(.title2)
                                .frame(height: 20)
                            
                            Text("\(hour.temp)°")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 12)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct DailyForecastView: View {
    let days: [DailyMock] = DailyMock.generate()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("10-Day Forecast", systemImage: "calendar")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(15)
            
            Divider().background(.white.opacity(0.2)).padding(.horizontal, 15)
            
            ForEach(days) { day in
                HStack {
                    // Day Name
                    Text(day.dayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 50, alignment: .leading)
                    
                    Spacer()
                    
                    // Icon
                    Image(systemName: day.icon)
                        .symbolRenderingMode(.multicolor)
                        .font(.title3)
                        .frame(width: 30)
                    
                    Spacer()
                    
                    // Low Temp
                    Text("\(day.low)°")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 40)
                    
                    // Temperature Bar
                    TemperatureBar(low: day.low, high: day.high, range: 55...90)
                        .frame(width: 100, height: 4)
                    
                    // High Temp
                    Text("\(day.high)°")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 15)
                
                if day.id != days.last?.id {
                    Divider().background(.white.opacity(0.2)).padding(.leading, 15)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct TemperatureBar: View {
    let low: Int
    let high: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color.black.opacity(0.2))
                
                // Colored Bar
                Capsule()
                    .fill(LinearGradient(colors: [.green, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: width(in: geo.size.width), height: 4)
                    .offset(x: offset(in: geo.size.width))
            }
        }
    }
    
    // Calculate relative width of the bar based on daily range vs weekly range
    func width(in totalWidth: CGFloat) -> CGFloat {
        let rangeSpan = CGFloat(range.upperBound - range.lowerBound)
        let daySpan = CGFloat(high - low)
        return (daySpan / rangeSpan) * totalWidth
    }
    
    // Calculate starting offset
    func offset(in totalWidth: CGFloat) -> CGFloat {
        let rangeSpan = CGFloat(range.upperBound - range.lowerBound)
        let startDiff = CGFloat(low - range.lowerBound)
        return (startDiff / rangeSpan) * totalWidth
    }
}

struct DetailsGridView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            DetailTile(icon: "sun.max.fill", title: "UV INDEX", value: "4", description: "Moderate")
            DetailTile(icon: "sunset.fill", title: "SUNSET", value: "8:14PM", description: "Sunrise: 6:15AM")
            DetailTile(icon: "wind", title: "WIND", value: "8 mph", description: "Gusts 12 mph")
            DetailTile(icon: "drop.fill", title: "RAINFALL", value: "0\"", description: "None expected")
        }
    }
}

struct DetailTile: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .padding(.top, 4)
            
            Spacer()
            
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding()
        .frame(height: 160, alignment: .leading)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

// MARK: - Mock Data Models

struct HourlyMock: Identifiable {
    let id = UUID()
    let time: String
    let icon: String
    let temp: Int
    
    static func generate() -> [HourlyMock] {
        return [
            HourlyMock(time: "Now", icon: "sun.max.fill", temp: 75),
            HourlyMock(time: "12PM", icon: "sun.max.fill", temp: 76),
            HourlyMock(time: "1PM", icon: "cloud.sun.fill", temp: 78),
            HourlyMock(time: "2PM", icon: "cloud.sun.fill", temp: 80),
            HourlyMock(time: "3PM", icon: "sun.max.fill", temp: 82),
            HourlyMock(time: "4PM", icon: "sun.max.fill", temp: 81),
            HourlyMock(time: "5PM", icon: "cloud.sun.fill", temp: 79),
            HourlyMock(time: "6PM", icon: "sun.haze.fill", temp: 76),
            HourlyMock(time: "7PM", icon: "moon.stars.fill", temp: 72)
        ]
    }
}

struct DailyMock: Identifiable {
    let id = UUID()
    let dayName: String
    let icon: String
    let low: Int
    let high: Int
    
    static func generate() -> [DailyMock] {
        return [
            DailyMock(dayName: "Today", icon: "sun.max.fill", low: 68, high: 82),
            DailyMock(dayName: "Wed", icon: "cloud.sun.fill", low: 66, high: 80),
            DailyMock(dayName: "Thu", icon: "sun.max.fill", low: 65, high: 83),
            DailyMock(dayName: "Fri", icon: "cloud.rain.fill", low: 62, high: 75),
            DailyMock(dayName: "Sat", icon: "cloud.fill", low: 60, high: 74),
            DailyMock(dayName: "Sun", icon: "sun.max.fill", low: 63, high: 78),
            DailyMock(dayName: "Mon", icon: "cloud.sun.fill", low: 65, high: 80)
        ]
    }
}

// Extension for hex colors (Optional, but helpful for matching backgrounds)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview
#Preview {
    WeatherView()
}
