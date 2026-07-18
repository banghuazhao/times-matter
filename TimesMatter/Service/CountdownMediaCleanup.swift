//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation

enum CountdownMediaCleanup {
    @MainActor
    static func removeFiles(for countdown: Countdown) {
        @Dependency(\.backgroundImageManager) var backgroundImageManager
        @Dependency(\.videoBackgroundManager) var videoBackgroundManager

        if let path = countdown.backgroundImageName {
            try? backgroundImageManager.deleteCustomBackgroundImage(at: path)
        }
        if let path = countdown.backgroundVideoPath {
            try? videoBackgroundManager.deleteCustomBackgroundVideo(at: path)
        }
    }
}
