//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct BackgroundMusicTrack: Identifiable, Hashable {
    var id: String { fileName }
    var fileName: String
    var displayName: String
    var category: String
}

enum BackgroundMusicCatalog {
    static let none = "None"

    static let tracks: [BackgroundMusicTrack] = [
        .init(fileName: "calm_The_Lake.mp3", displayName: "The Lake", category: String(localized: "Calm")),
        .init(fileName: "calm_Whispers.mp3", displayName: "Whispers", category: String(localized: "Calm")),
        .init(fileName: "calm_Redemption_Int.mp3", displayName: "Redemption", category: String(localized: "Calm")),
        .init(fileName: "forest_birds.mp3", displayName: "Forest Birds", category: String(localized: "Forest")),
        .init(fileName: "forest_creek.mp3", displayName: "Creek", category: String(localized: "Forest")),
        .init(fileName: "forest_fire.mp3", displayName: "Campfire", category: String(localized: "Forest")),
        .init(fileName: "forest_waterfall.mp3", displayName: "Waterfall", category: String(localized: "Forest")),
        .init(fileName: "forest_wind.mp3", displayName: "Wind", category: String(localized: "Forest")),
        .init(fileName: "rain_light.mp3", displayName: "Light Rain", category: String(localized: "Rain")),
        .init(fileName: "rain_ocean.mp3", displayName: "Ocean", category: String(localized: "Rain")),
        .init(fileName: "rain_on_window.mp3", displayName: "Rain on Window", category: String(localized: "Rain")),
        .init(fileName: "rain_on_leaves.mp3", displayName: "Rain on Leaves", category: String(localized: "Rain")),
        .init(fileName: "meditation_piano.mp3", displayName: "Piano", category: String(localized: "Meditation")),
        .init(fileName: "meditation_flute.mp3", displayName: "Flute", category: String(localized: "Meditation")),
        .init(fileName: "meditation_bowl.mp3", displayName: "Singing Bowl", category: String(localized: "Meditation")),
        .init(fileName: "meditation_wind_chimes.mp3", displayName: "Wind Chimes", category: String(localized: "Meditation")),
    ]

    static var categories: [String] {
        Array(Set(tracks.map(\.category))).sorted()
    }

    static func url(for fileName: String) -> URL? {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? "mp3" : ext)
            ?? Bundle.main.url(forResource: fileName, withExtension: nil)
    }

    static func displayName(for fileName: String?) -> String {
        guard let fileName, fileName != none, !fileName.isEmpty else {
            return String(localized: "None")
        }
        return tracks.first(where: { $0.fileName == fileName })?.displayName
            ?? (fileName as NSString).deletingPathExtension.replacingOccurrences(of: "_", with: " ")
    }
}
