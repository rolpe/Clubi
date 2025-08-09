//
//  DesignSystem.swift
//  Clubi
//
//  Created by Ron Lipkin on 8/8/25.
//

import SwiftUI

// MARK: - Clubi Design System
// "Modern Golf" - Fresh, vibrant golf experience

extension Color {
    
    // MARK: - Primary Colors
    /// Dark green - for primary elements and headers
    static let augustaPine = Color(red: 0.039, green: 0.639, blue: 0.188) // #0A3C30 (Dark Green)
    
    /// Vibrant green - for secondary elements and accents
    static let fairwayGreen = Color(red: 0.000, green: 0.749, blue: 0.200) // #00BF33 (Dark Pastel Green)
    
    /// Bright amber - for special highlights and scores
    static let goldenTournament = Color(red: 1.000, green: 0.749, blue: 0.000) // #FFBF00 (Amber)
    
    // MARK: - Supporting Colors
    /// Bright green - for highest scores (9.0-10.0)
    static let freshGrass = Color(red: 0.000, green: 0.800, blue: 0.000) // #00CC00 (Bright Green)
    
    /// Medium green - for good scores (7.0-8.9)
    static let mediumGreen = Color(red: 0.200, green: 0.600, blue: 0.200) // #339933 (Medium Green)
    
    /// Dark green - for average scores (5.0-6.9)
    static let darkGreen = Color(red: 0.039, green: 0.439, blue: 0.188) // #0A7030 (Dark Green)
    
    /// Info state - aquamarine
    static let sunsetOrange = Color(red: 0.596, green: 0.984, blue: 0.796) // #98FBCB (Aquamarine)
    
    /// Primary accent - non photo blue
    static let redFlag = Color(red: 0.522, green: 0.820, blue: 0.859) // #85D1DB (Non Photo Blue)
    
    // MARK: - Neutral Palette
    /// Background - very light aquamarine tint
    static let morningMist = Color(red: 0.980, green: 0.995, blue: 0.992) // #FAFEFB (Very light aquamarine background)
    
    /// Surface - pristine white
    static let pristineWhite = Color.white // #FFFFFF
    
    /// Primary text - dark green
    static let charcoal = Color(red: 0.039, green: 0.639, blue: 0.188) // #0A3C30 (Same as augustaPine for consistency)
    
    /// Secondary text - medium green
    static let grayFairway = Color(red: 0.200, green: 0.500, blue: 0.300) // #33804D (Medium green tone)
    
    /// Tertiary text - light green
    static let lightGray = Color(red: 0.400, green: 0.600, blue: 0.500) // #669980 (Light green)
    
    /// Border - very subtle green
    static let subtleLines = Color(red: 0.900, green: 0.950, blue: 0.930) // #E6F2ED (Very subtle green)
    
    // MARK: - Error Color
    /// Error state - warm coral
    static let errorRed = Color(red: 0.900, green: 0.200, blue: 0.200) // #E63333 (Warm coral for actual errors)
}

// MARK: - Typography System
struct ClubiTypography {
    
    // MARK: - Font Styles
    /// Display text for course names and large scores
    static func display(_ size: CGFloat = 28, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// Headlines for section headers
    static func headline(_ size: CGFloat = 22, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// Body text for main content
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// Caption text for metadata
    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// Large numbers for scores
    static func scoreDisplay(_ size: CGFloat = 48, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Spacing System
struct ClubiSpacing {
    
    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4
    
    /// Small spacing (8pt)
    static let sm: CGFloat = 8
    
    /// Medium spacing (16pt)
    static let md: CGFloat = 16
    
    /// Large spacing (24pt)
    static let lg: CGFloat = 24
    
    /// Extra large spacing (32pt)
    static let xl: CGFloat = 32
    
    /// Extra extra large spacing (48pt)
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius System
struct ClubiRadius {
    
    /// Small radius for buttons and pills
    static let sm: CGFloat = 8
    
    /// Medium radius for cards
    static let md: CGFloat = 12
    
    /// Large radius for prominent cards
    static let lg: CGFloat = 16
    
    /// Extra large radius for special elements
    static let xl: CGFloat = 24
}

// MARK: - Shadow System
struct ClubiShadow {
    
    /// Subtle shadow for elevated cards
    static let card = Shadow(
        color: Color.augustaPine.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )
    
    /// Medium shadow for floating elements
    static let floating = Shadow(
        color: Color.augustaPine.opacity(0.12),
        radius: 16,
        x: 0,
        y: 4
    )
    
    /// Strong shadow for modals
    static let modal = Shadow(
        color: Color.augustaPine.opacity(0.16),
        radius: 24,
        x: 0,
        y: 8
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Animation System
struct ClubiAnimation {
    
    /// Quick animation for micro-interactions
    static let quick = Animation.easeInOut(duration: 0.2)
    
    /// Standard animation for most UI transitions
    static let standard = Animation.easeInOut(duration: 0.3)
    
    /// Smooth animation for page transitions
    static let smooth = Animation.easeInOut(duration: 0.4)
    
    /// Spring animation for bouncy effects
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// Gentle spring for subtle movements
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Component Extensions
extension View {
    
    /// Apply card-style shadow
    func cardShadow() -> some View {
        self.shadow(
            color: ClubiShadow.card.color,
            radius: ClubiShadow.card.radius,
            x: ClubiShadow.card.x,
            y: ClubiShadow.card.y
        )
    }
    
    /// Apply floating shadow
    func floatingShadow() -> some View {
        self.shadow(
            color: ClubiShadow.floating.color,
            radius: ClubiShadow.floating.radius,
            x: ClubiShadow.floating.x,
            y: ClubiShadow.floating.y
        )
    }
    
    /// Apply modal shadow
    func modalShadow() -> some View {
        self.shadow(
            color: ClubiShadow.modal.color,
            radius: ClubiShadow.modal.radius,
            x: ClubiShadow.modal.x,
            y: ClubiShadow.modal.y
        )
    }
}

// MARK: - Preview Helper
#Preview {
    VStack(spacing: ClubiSpacing.lg) {
        
        // Color Palette Preview
        HStack(spacing: ClubiSpacing.sm) {
            Circle()
                .fill(Color.augustaPine)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.fairwayGreen)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.goldenTournament)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.freshGrass)
                .frame(width: 40, height: 40)
        }
        
        // Typography Preview
        VStack(alignment: .leading, spacing: ClubiSpacing.sm) {
            Text("Pebble Beach Golf Links")
                .font(ClubiTypography.display())
                .foregroundColor(.charcoal)
            
            Text("Championship Course")
                .font(ClubiTypography.headline())
                .foregroundColor(.augustaPine)
            
            Text("Experience the legendary 18th hole with stunning ocean views.")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
            
            Text("Reviewed 3 days ago")
                .font(ClubiTypography.caption())
                .foregroundColor(.lightGray)
        }
        
        // Score Display Preview
        HStack {
            Text("8.5")
                .font(ClubiTypography.scoreDisplay())
                .foregroundColor(.goldenTournament)
            
            Text("/10")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        
        // Card Preview
        VStack(alignment: .leading, spacing: ClubiSpacing.md) {
            Text("Augusta National")
                .font(ClubiTypography.headline())
                .foregroundColor(.charcoal)
            
            Text("The most exclusive golf course in America")
                .font(ClubiTypography.body())
                .foregroundColor(.grayFairway)
        }
        .padding(ClubiSpacing.lg)
        .background(Color.pristineWhite)
        .cornerRadius(ClubiRadius.lg)
        .cardShadow()
    }
    .padding(ClubiSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.morningMist)
}