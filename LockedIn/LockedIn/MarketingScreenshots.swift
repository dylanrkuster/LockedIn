//
//  MarketingScreenshots.swift
//  LockedIn
//
//  App Store marketing screenshots.
//
//  HOW TO USE:
//  1. Open this file in Xcode
//  2. Show Canvas (Editor → Canvas or Option+Command+Return)
//  3. Select "iPhone 15 Pro Max" as the preview device (bottom of canvas)
//  4. For each preview, right-click → "Create Image..." to export as PNG
//  5. Upload to App Store Connect in order (1-5)
//
//  Screenshots are designed for 6.7" display (1290 × 2796px)
//  App Store will auto-scale for 6.5" displays
//

import SwiftUI

// MARK: - Screenshot 1: Hero Dashboard

/// First impression. Shows the core experience: your screen time balance.
/// Answers: "What is this app?"
struct Screenshot1_Hero: View {
    private let accentColor = Difficulty.medium.color

    var body: some View {
        ScreenshotContainer(
            headline: "EARN SCREEN TIME\nBY EXERCISING",
            subheadline: "Every workout credits your balance",
            accentColor: accentColor
        ) {
            ZStack {
                // Radial glow behind balance
                RadialGradient(
                    colors: [accentColor.opacity(0.3), accentColor.opacity(0.1), Color.clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 200
                )
                .blur(radius: 40)
                .offset(y: -40)

                VStack(spacing: AppSpacing.lg) {
                    Spacer()

                    // Balance with corner brackets
                    ZStack {
                        // Corner brackets - sized to frame the full balance display
                        CornerBrackets(color: accentColor.opacity(0.6), length: 32, thickness: 2)
                            .frame(width: 340, height: 280)

                        // Balance display
                        BalanceDisplay(
                            balance: 87,
                            maxBalance: 180,
                            difficulty: .medium,
                            onDifficultyTap: nil
                        )
                    }

                    Spacer()

                    // Progress bar
                    ProgressBar(
                        current: 87,
                        max: 120,
                        accentColor: accentColor
                    )
                    .padding(.horizontal, AppSpacing.xxl)

                    Spacer()
                        .frame(height: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
}

// MARK: - Screenshot 2: Blocked Screen

/// The consequence. Shows what happens when you hit zero.
/// Answers: "Why should I care? What makes this different?"
struct Screenshot2_Blocked: View {
    private let accentColor = Difficulty.hard.color

    var body: some View {
        ScreenshotContainer(
            headline: "HIT ZERO?\nYOU'RE BLOCKED",
            subheadline: "Apps stay blocked until you move",
            accentColor: accentColor
        ) {
            ZStack {
                // Dramatic radial glow
                RadialGradient(
                    colors: [accentColor.opacity(0.4), accentColor.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 30,
                    endRadius: 250
                )
                .blur(radius: 50)
                .offset(y: -60)

                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // Lock icon with pulse rings
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .stroke(accentColor.opacity(0.15), lineWidth: 1)
                            .frame(width: 180, height: 180)

                        // Middle pulse ring
                        Circle()
                            .stroke(accentColor.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 130, height: 130)

                        // Inner pulse ring
                        Circle()
                            .stroke(accentColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 90, height: 90)

                        // Glow effect
                        Image(systemName: "lock.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(accentColor)
                            .blur(radius: 25)
                            .opacity(0.7)

                        // Solid icon
                        Image(systemName: "lock.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(accentColor)
                    }

                    Spacer()
                        .frame(height: AppSpacing.md)

                    // Title
                    Text("YOU'RE LOCKED OUT")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white)

                    // Subtitle
                    Text("It's time to lock in.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer()

                    // CTA Button with glow
                    ZStack {
                        // Button glow
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor)
                            .frame(height: 52)
                            .blur(radius: 20)
                            .opacity(0.5)

                        Text("GET ACTIVE")
                            .font(.system(size: 15, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, AppSpacing.xxl)

                    Spacer()
                        .frame(height: 60)
                }
            }
        }
    }
}

// MARK: - Screenshot 3: Difficulty Selection

/// The commitment levels. Visually striking, explains the core ratio.
/// Answers: "How does the earning work? Can I customize it?"
struct Screenshot3_Difficulty: View {
    private let accentColor = Difficulty.easy.color

    var body: some View {
        ScreenshotContainer(
            headline: "PICK YOUR\nDIFFICULTY",
            subheadline: "From easy to extreme",
            accentColor: accentColor
        ) {
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                    .frame(height: AppSpacing.md)

                // Difficulty cards
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Difficulty.allCases) { difficulty in
                        ScreenshotDifficultyCard(
                            difficulty: difficulty,
                            isSelected: difficulty == .easy
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
        }
    }
}

// MARK: - Screenshot 4: Activity History

/// The tracking mechanic. Shows earn/spend ledger.
/// Answers: "How do I track what I earn and spend?"
struct Screenshot4_Activity: View {
    private let accentColor = Difficulty.medium.color

    var body: some View {
        ScreenshotContainer(
            headline: "TRACK EVERY\nMINUTE",
            subheadline: "Earn from workouts, spend on apps",
            accentColor: accentColor
        ) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Activity section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("ACTIVITY")
                        .font(AppFont.label(11))
                        .tracking(3)
                        .foregroundStyle(AppColor.textSecondary)

                    VStack(spacing: AppSpacing.sm) {
                        ScreenshotActivityRow(
                            icon: "figure.run",
                            source: "Morning Run",
                            amount: 30,
                            balance: 87,
                            accentColor: accentColor
                        )
                        ScreenshotActivityRow(
                            icon: "iphone",
                            source: "Screen Time",
                            amount: -12,
                            balance: 57,
                            accentColor: accentColor
                        )
                        ScreenshotActivityRow(
                            icon: "figure.outdoor.cycle",
                            source: "Cycling",
                            amount: 45,
                            balance: 69,
                            accentColor: accentColor
                        )
                        ScreenshotActivityRow(
                            icon: "iphone",
                            source: "Screen Time",
                            amount: -8,
                            balance: 24,
                            accentColor: accentColor
                        )
                        ScreenshotActivityRow(
                            icon: "iphone",
                            source: "Screen Time",
                            amount: -15,
                            balance: 32,
                            accentColor: accentColor
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
        }
    }
}

// MARK: - Screenshot 5: Blocked Apps

/// The control. Shows user decides what's blocked.
/// Answers: "What apps can I block? Am I in control?"
struct Screenshot5_BlockedApps: View {
    private let accentColor = Difficulty.extreme.color

    var body: some View {
        ScreenshotContainer(
            headline: "BLOCK YOUR\nDISTRACTIONS",
            subheadline: "You choose what's off-limits",
            accentColor: accentColor
        ) {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                    .frame(height: AppSpacing.lg)

                // Mock app grid
                VStack(spacing: AppSpacing.lg) {
                    HStack {
                        Text("BLOCKED")
                            .font(AppFont.label(11))
                            .tracking(3)
                            .foregroundStyle(AppColor.textSecondary)

                        Spacer()

                        Text("EDIT")
                            .font(AppFont.label(10))
                            .tracking(2)
                            .foregroundStyle(accentColor)
                    }

                    // App icons grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.lg) {
                        MockAppIcon(symbol: "camera.fill", color: Color(red: 0.88, green: 0.19, blue: 0.42), name: "Instagram")
                        MockAppIcon(symbol: "play.rectangle.fill", color: .red, name: "YouTube")
                        MockAppIcon(symbol: "music.note", color: Color(red: 0.0, green: 0.0, blue: 0.0), name: "TikTok", hasGradient: true)
                        MockAppIcon(symbol: "xmark", color: Color(red: 0.1, green: 0.1, blue: 0.1), name: "X")
                        MockAppIcon(symbol: "gamecontroller.fill", color: .purple, name: "Games")
                        MockAppIcon(symbol: "envelope.fill", color: .blue, name: "Mail")
                        MockAppIcon(symbol: "safari.fill", color: Color(red: 0.0, green: 0.5, blue: 1.0), name: "Safari")
                        MockAppIcon(symbol: "plus", color: AppColor.border, name: "Add more", isAddButton: true)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
        }
    }
}

// MARK: - Supporting Components

/// Tactical corner brackets for targeting aesthetic
private struct CornerBrackets: View {
    let color: Color
    var length: CGFloat = 28
    var thickness: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Top left
                Path { path in
                    path.move(to: CGPoint(x: 0, y: length))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: length, y: 0))
                }
                .stroke(color, lineWidth: thickness)

                // Top right
                Path { path in
                    path.move(to: CGPoint(x: w - length, y: 0))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w, y: length))
                }
                .stroke(color, lineWidth: thickness)

                // Bottom right
                Path { path in
                    path.move(to: CGPoint(x: w, y: h - length))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: w - length, y: h))
                }
                .stroke(color, lineWidth: thickness)

                // Bottom left
                Path { path in
                    path.move(to: CGPoint(x: length, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h - length))
                }
                .stroke(color, lineWidth: thickness)
            }
        }
    }
}

/// Activity row with icon for marketing screenshot
private struct ScreenshotActivityRow: View {
    let icon: String
    let source: String
    let amount: Int
    let balance: Int
    let accentColor: Color

    private var isEarned: Bool { amount > 0 }
    private var amountColor: Color { isEarned ? accentColor : AppColor.textSecondary }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEarned ? accentColor.opacity(0.15) : AppColor.surface)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isEarned ? accentColor : AppColor.textTertiary)
            }

            // Source
            Text(source)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            // Amount
            Text(isEarned ? "+\(amount)" : "\(amount)")
                .font(AppFont.mono(15))
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColor.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ScreenshotDifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool

    private let totalBars = 4
    private let barWidth: CGFloat = 4
    private let barHeight: CGFloat = 18
    private let barSpacing: CGFloat = 3

    private var ratioExplanation: String {
        switch difficulty {
        case .easy: "1 MIN EXERCISE = 2 MIN SCREEN"
        case .medium: "1 MIN EXERCISE = 1 MIN SCREEN"
        case .hard: "2 MIN EXERCISE = 1 MIN SCREEN"
        case .extreme: "3 MIN EXERCISE = 1 MIN SCREEN"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Rank bars
            HStack(spacing: barSpacing) {
                ForEach(0..<totalBars, id: \.self) { index in
                    Rectangle()
                        .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                        .frame(width: barWidth, height: barHeight)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(difficulty.rawValue)
                    .font(AppFont.label(14))
                    .tracking(2)
                    .foregroundStyle(difficulty.color)

                Text(ratioExplanation)
                    .font(AppFont.mono(10))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(difficulty.color)
            }
        }
        .padding(AppSpacing.md)
        .background(
            ZStack {
                if isSelected {
                    // Glow behind selected card
                    RoundedRectangle(cornerRadius: 0)
                        .fill(difficulty.color.opacity(0.1))
                }
            }
        )
        .overlay(
            Rectangle()
                .stroke(isSelected ? difficulty.color : AppColor.border, lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct MockAppIcon: View {
    let symbol: String
    let color: Color
    let name: String
    var hasGradient: Bool = false
    var isAddButton: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if isAddButton {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColor.border, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 60, height: 60)
                } else if hasGradient {
                    // TikTok-style gradient
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.8, blue: 0.8), Color(red: 1.0, green: 0.0, blue: 0.5)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                        .frame(width: 60, height: 60)
                }

                Image(systemName: symbol)
                    .font(.system(size: isAddButton ? 20 : 26, weight: isAddButton ? .medium : .regular))
                    .foregroundStyle(isAddButton ? AppColor.textTertiary : .white)
            }

            Text(name)
                .font(AppFont.mono(9))
                .foregroundStyle(AppColor.textTertiary)
                .lineLimit(1)
        }
    }
}

// MARK: - Screenshot Container

private struct ScreenshotContainer<Content: View>: View {
    let headline: String
    let subheadline: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep black background
                Color.black
                    .ignoresSafeArea()

                // Primary accent glow from top
                RadialGradient(
                    colors: [accentColor.opacity(0.25), accentColor.opacity(0.08), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: geo.size.height * 0.5
                )
                .ignoresSafeArea()

                // Subtle vignette for depth
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    center: .center,
                    startRadius: geo.size.width * 0.4,
                    endRadius: geo.size.width
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Marketing header area
                    VStack(spacing: 12) {
                        Spacer()

                        Text(headline)
                            .font(.system(size: 34, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 0)

                        Text(subheadline)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                            .frame(height: 20)
                    }
                    .frame(height: geo.size.height * 0.26)
                    .frame(maxWidth: .infinity)

                    // Accent-colored divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, accentColor.opacity(0.5), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, AppSpacing.xl)

                    // App content area
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

// MARK: - Previews (in optimal App Store order)

#Preview("1. Dashboard") {
    Screenshot1_Hero()
        .previewDevice("iPhone 15 Pro Max")
}

#Preview("2. Blocked") {
    Screenshot2_Blocked()
        .previewDevice("iPhone 15 Pro Max")
}

#Preview("3. Difficulty") {
    Screenshot3_Difficulty()
        .previewDevice("iPhone 15 Pro Max")
}

#Preview("4. Activity") {
    Screenshot4_Activity()
        .previewDevice("iPhone 15 Pro Max")
}

#Preview("5. Apps") {
    Screenshot5_BlockedApps()
        .previewDevice("iPhone 15 Pro Max")
}
