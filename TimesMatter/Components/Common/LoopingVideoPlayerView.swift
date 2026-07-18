//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import SwiftUI

/// Plays the first few seconds of a video on a seamless mute loop (no controls).
struct LoopingVideoPlayerView: UIViewRepresentable {
    let path: String
    var loopSeconds: TimeInterval = 6

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        context.coordinator.attach(to: view, path: path, loopSeconds: loopSeconds)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        context.coordinator.update(path: path, loopSeconds: loopSeconds)
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        private var timeObserver: Any?
        private var endObserver: NSObjectProtocol?
        private var currentPath: String?
        private var loopSeconds: TimeInterval = 6
        private weak var container: PlayerContainerView?

        func attach(to view: PlayerContainerView, path: String, loopSeconds: TimeInterval) {
            container = view
            update(path: path, loopSeconds: loopSeconds)
        }

        func update(path: String, loopSeconds: TimeInterval) {
            self.loopSeconds = loopSeconds
            guard path != currentPath else {
                player?.play()
                return
            }
            teardown()
            currentPath = path
            guard FileManager.default.fileExists(atPath: path), let container else { return }

            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])

            let player = AVPlayer(url: URL(fileURLWithPath: path))
            player.isMuted = true
            player.actionAtItemEnd = .none

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            container.setPlayerLayer(layer)

            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.15, preferredTimescale: 600),
                queue: .main
            ) { [weak self, weak player] time in
                guard let self, let player else { return }
                if time.seconds.isFinite, time.seconds >= self.loopSeconds {
                    player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    player.play()
                }
            }

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }

            self.player = player
            playerLayer = layer
            player.play()
        }

        func teardown() {
            if let timeObserver, let player {
                player.removeTimeObserver(timeObserver)
            }
            timeObserver = nil
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = nil
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            player = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            currentPath = nil
        }
    }
}

final class PlayerContainerView: UIView {
    private var playerLayer: AVPlayerLayer?

    func setPlayerLayer(_ layer: AVPlayerLayer) {
        playerLayer?.removeFromSuperlayer()
        playerLayer = layer
        self.layer.addSublayer(layer)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
