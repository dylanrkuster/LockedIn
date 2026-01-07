//
//  LockedInWatchWidgetBundle.swift
//  LockedInWatchWidgetExtension
//
//  Widget bundle that registers watch complications with the system.
//

import SwiftUI
import WidgetKit

@main
struct LockedInWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        LockedInWatchWidget()
    }
}
