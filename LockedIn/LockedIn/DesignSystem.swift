//
//  DesignSystem.swift
//  LockedIn
//
//  Brutalist design system. Beauty through restraint.
//

import SwiftUI

// MARK: - Colors

enum AppColor {
    // Base palette
    static let background = Color.black
    static let surface = Color(white: 0.067)        // #111111
    static let border = Color(white: 0.133)         // #222222

    // Text hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.533)  // #888888
    static let textTertiary = Color(white: 0.4)     // #666666

    // Difficulty accent colors
    static let easy = Color(red: 0.133, green: 0.773, blue: 0.369)      // #22C55E
    static let medium = Color(red: 0.918, green: 0.702, blue: 0.031)    // #EAB308
    static let hard = Color(red: 0.976, green: 0.451, blue: 0.086)      // #F97316
    static let extreme = Color(red: 0.863, green: 0.149, blue: 0.149)   // #DC2626
}

// MARK: - Typography

enum AppFont {
    // The balance number - massive, commanding
    static let balance = Font.system(size: 120, weight: .bold, design: .monospaced)

    // Labels - understated, confident
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    // Monospace labels
    static func mono(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // Body text
    static let body = Font.system(size: 14, weight: .regular, design: .default)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Difficulty Color Extension

extension Difficulty {
    var color: Color {
        switch self {
        case .easy: AppColor.easy
        case .medium: AppColor.medium
        case .hard: AppColor.hard
        case .extreme: AppColor.extreme
        }
    }

    var barCount: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        case .extreme: 4
        }
    }
}
