//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import UniformTypeIdentifiers

protocol VideoBackgroundManaging {
    func saveCustomBackgroundVideo(from sourceURL: URL) throws -> String
    func deleteCustomBackgroundVideo(at path: String) throws
    func isCustomBackgroundVideoPath(_ path: String) -> Bool
}

@Observable
final class VideoBackgroundManager: VideoBackgroundManaging {
    private enum Constants {
        static let directoryName = "BackgroundVideos"
        static let prefix = "custom_bg_video_"
    }

    private let fileManager = FileManager.default

    private var directoryURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(Constants.directoryName)
    }

    func saveCustomBackgroundVideo(from sourceURL: URL) throws -> String {
        try createDirectoryIfNeeded()
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let filename = "\(Constants.prefix)\(UUID().uuidString).\(ext)"
        let destination = directoryURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        try fileManager.copyItem(at: sourceURL, to: destination)
        return destination.path
    }

    func deleteCustomBackgroundVideo(at path: String) throws {
        guard isCustomBackgroundVideoPath(path) else { return }
        try fileManager.removeItem(atPath: path)
    }

    func isCustomBackgroundVideoPath(_ path: String) -> Bool {
        path.contains(Constants.prefix)
    }

    private func createDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}

private enum VideoBackgroundManagerKey: DependencyKey {
    static let liveValue: VideoBackgroundManaging = VideoBackgroundManager()
}

extension DependencyValues {
    var videoBackgroundManager: VideoBackgroundManaging {
        get { self[VideoBackgroundManagerKey.self] }
        set { self[VideoBackgroundManagerKey.self] = newValue }
    }
}
