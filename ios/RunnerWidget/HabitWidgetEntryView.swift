
import SwiftUI
import WidgetKit

struct HabitWidgetEntryView : View {
    var entry: HabitWidgetTimelineProvider.Entry

    var body: some View {
        if entry.isConfigured {
            configuredView
        } else {
            emptyView
        }
    }
    
    var emptyView: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                if #available(iOS 17.0, *) {
                    // iOS 17+: Inform user to long-press to configure
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                    Text("Select Habit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Long press to edit widget")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                } else {
                    // iOS < 17: Tap to configure
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    Text("Add a Habit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "streakly://configure"))
    }
    
    
    var configuredView: some View {
        ZStack {
            // Background - fill entire widget
            Color(entry.isDarkMode ? UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0) : UIColor.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("HABITS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                    .padding(.bottom, 8)
                
                // Name
                Text(entry.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(entry.isDarkMode ? .white : .black)
                    .lineLimit(1)
                
                // Streak
                Text("\(entry.streak) day streak")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                    .padding(.top, 2)
                
                Spacer()
                
                HStack {
                    // Flame Icon (Bottom Left)
                    if let uiImage = UIImage(named: "AppIcon") { // Fallback/Placeholder
                         Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "flame.fill")
                            .resizable()
                            .frame(width: 18, height: 24)
                            .foregroundColor(Color(hex: entry.colorHex))
                    }
                    
                    Spacer()
                    
                    // Progress Ring Button (Bottom Right)
                    Button(intent: ToggleCompletionIntent(habitId: getHabitIdFromData())) {
                        ZStack {
                            SegmentedProgressRing(
                                dailyCompletions: entry.dailyCompletions,
                                remindersPerDay: max(1, entry.remindersPerDay),
                                color: Color(hex: entry.colorHex),
                                isDarkMode: entry.isDarkMode
                            )
                            .frame(width: 44, height: 44)
                            
                            if let base64 = entry.iconBase64,
                               let data = Data(base64Encoded: base64),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    
    func getHabitIdFromData() -> String {
        // Quick extraction
        return entry.habitData?["id"] as? String ?? ""
    }
}

// Helpers
struct SegmentedProgressRing: View {
    var dailyCompletions: Int
    var remindersPerDay: Int
    var color: Color
    var isDarkMode: Bool
    
    // Android parity constants
    let strokeWidth: CGFloat = 5
    let gapDegrees: Double = 6
    
    var body: some View {
        ZStack {
            // Background Ring
            if remindersPerDay <= 1 {
                Circle()
                    .stroke(
                        isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.1),
                        lineWidth: strokeWidth
                    )
            } else {
                // Background Segments
                ForEach(0..<remindersPerDay, id: \.self) { index in
                    SegmentArc(
                        startAngle: .degrees(startAngle(for: index) - 90),
                        endAngle: .degrees(endAngle(for: index) - 90)
                    )
                    .stroke(
                        isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.1),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                }
            }
            
            // Foreground Progress
            if remindersPerDay <= 1 {
                if dailyCompletions > 0 {
                    Circle()
                        .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                }
            } else {
                // Foreground Segments
                ForEach(0..<min(dailyCompletions, remindersPerDay), id: \.self) { index in
                    SegmentArc(
                        startAngle: .degrees(startAngle(for: index) - 90),
                        endAngle: .degrees(endAngle(for: index) - 90)
                    )
                    .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                }
            }
        }
    }
    
    func startAngle(for index: Int) -> Double {
        let sweep = 360.0 / Double(remindersPerDay)
        return Double(index) * sweep
    }
    
    func endAngle(for index: Int) -> Double {
        let sweep = 360.0 / Double(remindersPerDay)
        return (Double(index) * sweep) + sweep - gapDegrees
    }
}

struct SegmentArc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
