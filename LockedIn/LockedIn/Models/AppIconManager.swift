//
//  AppIconManager.swift
//  LockedIn
//
//  Manages alternate app icons based on difficulty level.
//

import UIKit

enum AppIconManager {
    private static let hasSetInitialIconKey = "hasSetInitialAppIcon"

    /// Updates the app icon to match the given difficulty.
    /// - Parameter difficulty: The difficulty level to set the icon for.
    /// - Note: iOS shows a system alert when the icon changes. This is expected behavior.
    static func updateIcon(for difficulty: Difficulty) {
        let newIconName = iconName(for: difficulty)

        // Ensure main thread for UIApplication access
        DispatchQueue.main.async {
            guard UIApplication.shared.alternateIconName != newIconName else { return }

            UIApplication.shared.setAlternateIconName(newIconName) { error in
                if let error {
                    print("Failed to set app icon: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Sets the initial app icon on first launch.
    /// Only sets the icon if it hasn't been set before.
    /// - Parameter difficulty: The initial difficulty level.
    static func setInitialIconIfNeeded(for difficulty: Difficulty) {
        let hasSetInitial = UserDefaults.standard.bool(forKey: hasSetInitialIconKey)
        guard !hasSetInitial else { return }

        updateIcon(for: difficulty)
        UserDefaults.standard.set(true, forKey: hasSetInitialIconKey)
    }

    static func iconName(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: "AppIcon-Easy"
        case .medium: "AppIcon-Medium"
        case .hard: "AppIcon-Hard"
        case .extreme: "AppIcon-Extreme"
        }
    }
}
