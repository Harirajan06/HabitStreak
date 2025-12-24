//
//  RunnerWidgetBundle.swift
//  RunnerWidget
//
//  Created by APPLE on 24/12/25.
//

import WidgetKit
import SwiftUI

@main
struct RunnerWidgetBundle: WidgetBundle {
    var body: some Widget {
        // List all widgets - iOS will automatically select the appropriate one based on OS version
        // Only the compatible widget will be available to the user
        if #available(iOS 17.0, *) {
            RunnerWidget17()
        }
        if #available(iOS 16.0, *) {
            RunnerWidget16()
        }
        RunnerWidgetLegacy()
        RunnerWidgetLiveActivity()
    }
}
