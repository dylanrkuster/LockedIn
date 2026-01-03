//
//  LockedInApp.swift
//  LockedIn
//

import SwiftUI

@main
struct LockedInApp: App {
    @State private var bankState = BankState.mock

    var body: some Scene {
        WindowGroup {
            DashboardView(bankState: bankState)
        }
    }
}
