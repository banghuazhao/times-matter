//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Lightweight still frame for list rows (avoids spawning AVPlayers per cell).
struct VideoThumbnailView: View {
    let path: String
    var fallbackColor: Color = .secondary.opacity(0.2)

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackColor
            }
        }
        .task(id: path) {
            image = await Task.detached(priority: .utility) {
                VideoThumbnailCache.image(for: path)
            }.value
        }
    }
}
