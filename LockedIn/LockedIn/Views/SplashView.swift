//
//  SplashView.swift
//  LockedIn
//
//  Displays the app icon briefly on launch before fading to main content.
//

import SwiftUI

struct SplashView<Content: View>: View {
    let content: Content

    @State private var isShowingSplash = true

    /// The current splash icon name (default white before onboarding, difficulty-based after)
    private var iconName: String {
        guard SharedState.hasCompletedOnboarding else {
            return "SplashIcon"
        }
        let difficulty = Difficulty(rawValue: SharedState.difficultyRaw) ?? .medium
        return "SplashIcon-\(difficulty.rawValue.capitalized)"
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Main content renders underneath (hidden) - preloads during splash
            content
                .opacity(isShowingSplash ? 0 : 1)

            // Splash overlay
            if isShowingSplash {
                splashContent
                    .transition(.opacity)
            }
        }
        .task {
            // Wait minimum 2 seconds
            try? await Task.sleep(for: .seconds(2))

            withAnimation(.easeOut(duration: 0.4)) {
                isShowingSplash = false
            }
        }
    }

    private var splashContent: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let uiImage = UIImage(named: iconName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 27))
            } else {
                #if DEBUG
                let _ = assertionFailure("Missing splash icon: \(iconName)")
                #endif
            }
        }
    }
}
