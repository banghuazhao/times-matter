//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class EventMusicPlayer {
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentFileName: String?

    func play(fileName: String?, volume: Double = 0.55) {
        guard let fileName,
              fileName != BackgroundMusicCatalog.none,
              !fileName.isEmpty,
              let url = BackgroundMusicCatalog.url(for: fileName)
        else {
            stop()
            return
        }

        let clamped = Float(max(0, min(1, volume)))

        if currentFileName == fileName, let player {
            player.volume = clamped
            if !isPlaying {
                player.play()
                isPlaying = true
            }
            return
        }

        stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = clamped
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
            currentFileName = fileName
            isPlaying = true
        } catch {
            print("Failed to play event music: \(error)")
            stop()
        }
    }

    func setVolume(_ volume: Double) {
        player?.volume = Float(max(0, min(1, volume)))
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentFileName = nil
    }
}
