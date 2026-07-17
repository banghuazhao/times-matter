//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AudioToolbox
import Foundation

enum ButtonSound {
    static func playIfEnabled() {
        let enabled = UserDefaults.standard.object(forKey: "buttonSoundEnabled") as? Bool ?? true
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104) // subtle tap
    }
}
