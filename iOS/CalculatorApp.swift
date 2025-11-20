import SwiftUI

struct CalculatorView: View {
    // MARK: - State
    @State private var displayValue = "0"
    @State private var storedValue: Double = 0
    @State private var currentOperation: CalcButton? = nil
    @State private var isTyping = false
    @State private var activeOperationButton: CalcButton? = nil // To track which button is highlighted white
    
    // Layout constants
    let spacing: CGFloat = 12
    
    let buttons: [[CalcButton]] = [
        [.clear, .negative, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equal]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: spacing) {
                Spacer()
                
                // MARK: - Display
                HStack {
                    Spacer()
                    Text(displayValue)
                        .font(.system(size: 90, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4) // Shrink text if number is too long
                        .padding(.horizontal, 20)
                        .gesture(DragGesture().onEnded { value in
                            // hidden feature: swipe to delete last digit
                            if value.translation.width > 10 || value.translation.width < -10 {
                                backspace()
                            }
                        })
                }
                
                // MARK: - Buttons
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(
                                button: button,
                                isActive: activeOperationButton == button,
                                acText: displayValue == "0" && !isTyping ? "AC" : "C",
                                action: { handlePress(button) }
                            )
                        }
                    }
                }
            }
            .padding(.bottom, spacing)
        }
    }
    
    // MARK: - Logic
    
    func handlePress(_ button: CalcButton) {
        switch button {
            case .clear:
                if displayValue != "0" || isTyping {
                    // Action: C (Clear current entry)
                    displayValue = "0"
                    isTyping = false
                    // Active operation remains highlighted if we just cleared the second number
                    if activeOperationButton != nil {
                        // Do nothing to stored value
                    } else {
                        activeOperationButton = nil
                        currentOperation = nil
                        storedValue = 0
                    }
                } else {
                    // Action: AC (All Clear)
                    displayValue = "0"
                    isTyping = false
                    currentOperation = nil
                    storedValue = 0
                    activeOperationButton = nil
                }
                
            case .negative:
                if let value = Double(cleanString(displayValue)) {
                    displayValue = formatNumber(value * -1)
                }
                
            case .percent:
                if let value = Double(cleanString(displayValue)) {
                    displayValue = formatNumber(value / 100)
                }
                
            case .add, .subtract, .multiply, .divide:
                // If we were typing, calculate the previous result first (chained operations)
                if isTyping, let operation = currentOperation {
                    let currentValue = Double(cleanString(displayValue)) ?? 0
                    let result = performOperation(operation, val1: storedValue, val2: currentValue)
                    storedValue = result
                    displayValue = formatNumber(result)
                } else {
                    storedValue = Double(cleanString(displayValue)) ?? 0
                }
                
                currentOperation = button
                activeOperationButton = button // Highlight the button white
                isTyping = false
                
            case .equal:
                guard let operation = currentOperation else { return }
                let currentValue = Double(cleanString(displayValue)) ?? 0
                let result = performOperation(operation, val1: storedValue, val2: currentValue)
                
                displayValue = formatNumber(result)
                storedValue = result // Allow for repeated equals if needed (simplified logic here)
                currentOperation = nil
                activeOperationButton = nil
                isTyping = false
                
            case .decimal:
                if !isTyping {
                    displayValue = "0."
                    isTyping = true
                } else if !displayValue.contains(".") {
                    displayValue += "."
                }
                activeOperationButton = nil // Unhighlight operator if we start typing
                
            default: // Numbers
                let number = button.title
                if isTyping {
                    // Prevent massive numbers
                    if displayValue.count < 9 {
                        displayValue += number
                    }
                } else {
                    displayValue = number
                    isTyping = true
                }
                activeOperationButton = nil // Unhighlight operator once we type a number
        }
    }
    
    func performOperation(_ op: CalcButton, val1: Double, val2: Double) -> Double {
        switch op {
            case .add: return val1 + val2
            case .subtract: return val1 - val2
            case .multiply: return val1 * val2
            case .divide: return val2 != 0 ? val1 / val2 : 0
            default: return val2
        }
    }
    
    func backspace() {
        guard isTyping && displayValue.count > 1 else {
            displayValue = "0"
            isTyping = false
            return
        }
        displayValue.removeLast()
    }
    
    // Helper to remove commas before calculations
    func cleanString(_ str: String) -> String {
        return str.replacingOccurrences(of: ",", with: "")
    }
    
    // Helper to format numbers with commas
    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Components

struct CalculatorButtonView: View {
    let button: CalcButton
    let isActive: Bool // Is this operation currently selected?
    let acText: String // "AC" or "C"
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // Geometry setup
            let totalSpacing: CGFloat = 12 * 5
            let width = (UIScreen.main.bounds.width - totalSpacing) / 4
            let height = width
            
            ZStack {
                if button == .zero {
                    // Stadium Shape for Zero
                    HStack {
                        Text("0")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.leading, width / 2 - 10) // Visual alignment with "1"
                        Spacer()
                    }
                    .frame(width: width * 2 + 12, height: height)
                    .background(Color(uiColor: .darkGray)) // Specific hex: #333333
                    .clipShape(Capsule())
                } else {
                    // Standard Circle Button
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: width, height: height)
                        .overlay {
                            Text(button == .clear ? acText : button.title)
                                .font(.system(size: button.fontSize, weight: .medium))
                                .foregroundStyle(foregroundColor)
                            // Slight visual offset for operators
                                .padding(.bottom, button.isOperation ? 4 : 0)
                        }
                }
            }
        }
    }
    
    var backgroundColor: Color {
        if isActive { return .white }
        return button.backgroundColor
    }
    
    var foregroundColor: Color {
        if isActive { return .orange }
        return button.foregroundColor
    }
}

// MARK: - Models

enum CalcButton: Hashable {
    case one, two, three, four, five, six, seven, eight, nine, zero
    case add, subtract, multiply, divide
    case equal, clear, decimal, percent, negative
    
    var title: String {
        switch self {
            case .one: return "1"
            case .two: return "2"
            case .three: return "3"
            case .four: return "4"
            case .five: return "5"
            case .six: return "6"
            case .seven: return "7"
            case .eight: return "8"
            case .nine: return "9"
            case .zero: return "0"
            case .add: return "+"
            case .subtract: return "−"
            case .multiply: return "×"
            case .divide: return "÷"
            case .equal: return "="
            case .clear: return "AC"
            case .decimal: return "."
            case .percent: return "%"
            case .negative: return "+/-"
        }
    }
    
    var isOperation: Bool {
        return [.add, .subtract, .multiply, .divide, .equal].contains(self)
    }
    
    var fontSize: CGFloat {
        switch self {
            case .add, .subtract, .multiply, .divide, .equal: return 40
            case .clear, .negative, .percent: return 30
            default: return 36
        }
    }
    
    var backgroundColor: Color {
        switch self {
            case .add, .subtract, .multiply, .divide, .equal:
                return .orange
            case .clear, .negative, .percent:
                return Color(uiColor: .lightGray) // Hex: #A5A5A5
            default:
                return Color(uiColor: .darkGray) // Hex: #333333
        }
    }
    
    var foregroundColor: Color {
        switch self {
            case .clear, .negative, .percent:
                return .black
            default:
                return .white
        }
    }
}

#Preview {
    CalculatorView()
}
