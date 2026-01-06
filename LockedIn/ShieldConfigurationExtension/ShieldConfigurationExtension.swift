//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Customizes the appearance of the shield shown when apps are blocked.
//  Matches the brutalist design aesthetic of LockedIn.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Provides custom shield configuration for blocked apps.
/// Called by the system when a shielded app is opened.
///
/// Note: Extensions have tight memory limits (~6MB). We intentionally avoid
/// caching UIImages across invocations since:
/// 1. Icon creation is cheap (system SF Symbol)
/// 2. Static caches persist and accumulate memory
/// 3. System may spawn multiple extension instances
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Application Shields

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    // MARK: - Web Domain Shields

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    // MARK: - Configuration Builder

    private func makeConfiguration() -> ShieldConfiguration {
        // Track shield display for analytics (main app will log the event on foreground)
        SharedState.shieldDisplayCount += 1

        // Get difficulty for color
        let difficulty = SharedState.difficultyRaw
        let difficultyColor = getDifficultyColor(difficulty)

        // Create lock icon with difficulty color (no caching - see class docs)
        let icon = createColoredIcon(
            systemName: "lock.fill",
            color: difficultyColor
        )

        // Brutalist design: stark, direct, no-nonsense
        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: icon,
            title: ShieldConfiguration.Label(
                text: "YOU'RE LOCKED OUT",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "It's time to lock in.",
                color: UIColor(white: 0.6, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "GET ACTIVE",
                color: .white
            ),
            primaryButtonBackgroundColor: difficultyColor,
            secondaryButtonLabel: nil // No secondary button - no escape hatch
        )
    }

    // MARK: - Helpers

    private func getDifficultyColor(_ difficulty: String) -> UIColor {
        switch difficulty {
        case "EASY":
            return UIColor(red: 0.133, green: 0.773, blue: 0.369, alpha: 1.0) // #22C55E
        case "MEDIUM":
            return UIColor(red: 0.918, green: 0.702, blue: 0.031, alpha: 1.0) // #EAB308
        case "HARD":
            return UIColor(red: 0.976, green: 0.451, blue: 0.086, alpha: 1.0) // #F97316
        case "EXTREME":
            return UIColor(red: 0.863, green: 0.149, blue: 0.149, alpha: 1.0) // #DC2626
        default:
            return UIColor(red: 0.918, green: 0.702, blue: 0.031, alpha: 1.0) // Medium default
        }
    }

    private func createColoredIcon(systemName: String, color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        return UIImage(systemName: systemName, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
