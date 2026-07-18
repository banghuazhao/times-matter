//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import UIKit

/// Generates and caches still frames for video backgrounds (list rows / lightweight previews).
enum VideoThumbnailCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(for path: String) -> UIImage? {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)
        let time = CMTime(seconds: 0.3, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: key)
        return image
    }

    static func remove(for path: String) {
        cache.removeObject(forKey: path as NSString)
    }
}
