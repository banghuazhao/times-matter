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

    func play(fileName: String?) {
        guard let fileName,
              fileName != BackgroundMusicCatalog.none,
              !fileName.isEmpty,
              let url = BackgroundMusicCatalog.url(for: fileName)
        else {
            stop()
            return
        }

        if currentFileName == fileName, isPlaying {
            return
        }

        stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.55
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
