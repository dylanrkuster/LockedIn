//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Handles button taps on the shield screen.
//  Primary action: Open the LockedIn main app.
//

import ManagedSettings

/// Handles user interaction with shield buttons.
class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - Application Actions

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action: action, completionHandler: completionHandler)
    }

    // MARK: - Web Domain Actions

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action: action, completionHandler: completionHandler)
    }

    // MARK: - Category Actions

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action: action, completionHandler: completionHandler)
    }

    // MARK: - Private

    private func handleAction(
        action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // "Get Active" button pressed
            // .close dismisses the shield and returns to home screen
            completionHandler(.close)

        case .secondaryButtonPressed:
            // No secondary button configured
            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }
}
