//
//  ClubiComponents.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/8/25.
//

import SwiftUI

// MARK: - Clubi Button Styles

/// Primary button style using Augusta Pine green
struct ClubiPrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClubiTypography.body(weight: .semibold))
            .foregroundColor(.pristineWhite)
            .padding(.vertical, ClubiSpacing.md)
            .padding(.horizontal, ClubiSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ClubiRadius.md)
                    .fill(
                        isDisabled ? Color.lightGray :
                        (configuration.isPressed ? Color.fairwayGreen : Color.augustaPine)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ClubiAnimation.quick, value: configuration.isPressed)
            .floatingShadow()
    }
}

/// Secondary button style with outline
struct ClubiSecondaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClubiTypography.body(weight: .medium))
            .foregroundColor(
                isDisabled ? Color.lightGray :
                (configuration.isPressed ? Color.fairwayGreen : Color.augustaPine)
            )
            .padding(.vertical, ClubiSpacing.md)
            .padding(.horizontal, ClubiSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ClubiRadius.md)
                    .fill(Color.pristineWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: ClubiRadius.md)
                            .stroke(
                                isDisabled ? Color.lightGray :
                                (configuration.isPressed ? Color.fairwayGreen : Color.augustaPine),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ClubiAnimation.quick, value: configuration.isPressed)
            .cardShadow()
    }
}

/// Tertiary button style (text only)
struct ClubiTertiaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClubiTypography.body(weight: .medium))
            .foregroundColor(
                isDisabled ? Color.lightGray :
                (configuration.isPressed ? Color.fairwayGreen : Color.grayFairway)
            )
            .padding(.vertical, ClubiSpacing.sm)
            .padding(.horizontal, ClubiSpacing.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(ClubiAnimation.quick, value: configuration.isPressed)
    }
}

/// Floating action button style
struct ClubiFloatingActionButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClubiTypography.headline(weight: .bold))
            .foregroundColor(.pristineWhite)
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(
                        isDisabled ? Color.lightGray :
                        (configuration.isPressed ? Color.augustaPine : Color.goldenTournament)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ClubiAnimation.bouncy, value: configuration.isPressed)
            .floatingShadow()
    }
}

/// Destructive button style
struct ClubiDestructiveButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClubiTypography.body(weight: .medium))
            .foregroundColor(.pristineWhite)
            .padding(.vertical, ClubiSpacing.md)
            .padding(.horizontal, ClubiSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ClubiRadius.md)
                    .fill(
                        isDisabled ? Color.lightGray :
                        (configuration.isPressed ? Color.errorRed.opacity(0.8) : Color.errorRed)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ClubiAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Clubi Card Components

/// Standard course card component
struct ClubiCourseCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ClubiSpacing.lg)
                .background(Color.pristineWhite)
                .cornerRadius(ClubiRadius.lg)
                .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Score display component
struct ClubiScoreDisplay: View {
    let score: Double
    let maxScore: Double
    let size: ScoreSize
    
    enum ScoreSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 48
            }
        }
        
        var maxScoreFontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    init(score: Double, maxScore: Double = 10.0, size: ScoreSize = .medium) {
        self.score = score
        self.maxScore = maxScore
        self.size = size
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: ClubiSpacing.xs) {
            Text(String(format: "%.1f", score))
                .font(ClubiTypography.scoreDisplay(size.fontSize))
                .foregroundColor(scoreColor)
            
            Text("/\(Int(maxScore))")
                .font(ClubiTypography.body(size.maxScoreFontSize, weight: .medium))
                .foregroundColor(.grayFairway)
                .offset(y: -4)
        }
    }
    
    private var scoreColor: Color {
        if score >= 9.0 {
            return .goldenTournament  // Exceptional
        } else if score >= 8.0 {
            return .freshGrass        // Excellent
        } else if score >= 7.0 {
            return .augustaPine       // Very Good
        } else if score >= 6.0 {
            return .fairwayGreen      // Good
        } else if score >= 4.0 {
            return .grayFairway       // OK
        } else {
            return .errorRed          // Poor
        }
    }
}

/// Progress bar component
struct ClubiProgressBar: View {
    let progress: Double
    let total: Double
    let color: Color
    
    init(progress: Double, total: Double, color: Color = .augustaPine) {
        self.progress = progress
        self.total = total
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.subtleLines)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (progress / total))
                    .animation(ClubiAnimation.smooth, value: progress)
            }
        }
        .frame(height: 6)
        .cornerRadius(3)
    }
}

/// Tag/pill component
struct ClubiTag: View {
    let text: String
    let color: Color
    let backgroundColor: Color?
    
    init(_ text: String, color: Color = .augustaPine, backgroundColor: Color? = nil) {
        self.text = text
        self.color = color
        self.backgroundColor = backgroundColor ?? color.opacity(0.1)
    }
    
    var body: some View {
        Text(text)
            .font(ClubiTypography.caption(weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, ClubiSpacing.md)
            .padding(.vertical, ClubiSpacing.xs)
            .background(
                Capsule()
                    .fill(backgroundColor ?? color.opacity(0.1))
            )
    }
}

// MARK: - Button Style Extensions
extension View {
    
    func clubiPrimaryButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(ClubiPrimaryButtonStyle(isDisabled: isDisabled))
    }
    
    func clubiSecondaryButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(ClubiSecondaryButtonStyle(isDisabled: isDisabled))
    }
    
    func clubiTertiaryButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(ClubiTertiaryButtonStyle(isDisabled: isDisabled))
    }
    
    func clubiFloatingActionButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(ClubiFloatingActionButtonStyle(isDisabled: isDisabled))
    }
    
    func clubiDestructiveButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(ClubiDestructiveButtonStyle(isDisabled: isDisabled))
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: ClubiSpacing.lg) {
            
            Group {
                Text("Clubi Design System")
                    .font(ClubiTypography.display())
                    .foregroundColor(.charcoal)
                
                Text("Button Styles")
                    .font(ClubiTypography.headline())
                    .foregroundColor(.augustaPine)
                
                VStack(spacing: ClubiSpacing.md) {
                    Button("Primary Button") {}
                        .clubiPrimaryButton()
                    
                    Button("Secondary Button") {}
                        .clubiSecondaryButton()
                    
                    Button("Tertiary Button") {}
                        .clubiTertiaryButton()
                    
                    Button("Destructive") {}
                        .clubiDestructiveButton()
                    
                    Button("+") {}
                        .clubiFloatingActionButton()
                }
            }
            
            Group {
                Text("Components")
                    .font(ClubiTypography.headline())
                    .foregroundColor(.augustaPine)
                
                // Score displays
                HStack(spacing: ClubiSpacing.lg) {
                    ClubiScoreDisplay(score: 8.5, size: .small)
                    ClubiScoreDisplay(score: 7.2, size: .medium)
                    ClubiScoreDisplay(score: 9.1, size: .large)
                }
                
                // Progress bar
                ClubiProgressBar(progress: 3, total: 4)
                    .frame(height: 6)
                
                // Tags
                HStack {
                    ClubiTag("Championship")
                    ClubiTag("Public", color: .freshGrass)
                    ClubiTag("Reviewed", color: .goldenTournament)
                }
                
                // Course card example
                ClubiCourseCard(action: {}) {
                    VStack(alignment: .leading, spacing: ClubiSpacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: ClubiSpacing.xs) {
                                Text("Pebble Beach Golf Links")
                                    .font(ClubiTypography.headline())
                                    .foregroundColor(.charcoal)
                                
                                Text("Pebble Beach, CA")
                                    .font(ClubiTypography.body())
                                    .foregroundColor(.grayFairway)
                            }
                            
                            Spacer()
                            
                            ClubiScoreDisplay(score: 8.5, size: .medium)
                        }
                        
                        ClubiProgressBar(progress: 8.5, total: 10)
                            .frame(height: 4)
                        
                        HStack {
                            ClubiTag("Ocean Views")
                            ClubiTag("Championship", color: .goldenTournament)
                            Spacer()
                            Text("3 days ago")
                                .font(ClubiTypography.caption())
                                .foregroundColor(.lightGray)
                        }
                    }
                }
            }
        }
        .padding(ClubiSpacing.xl)
    }
    .background(Color.morningMist)
}