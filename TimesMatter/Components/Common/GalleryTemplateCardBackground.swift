//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Background for gallery / suggestion cards — shows the template image when set, else solid color.
struct GalleryTemplateCardBackground: View {
    let template: GalleryTemplate

    var body: some View {
        ZStack {
            Color(hex: template.backgroundColor)

            if let name = template.backgroundImageName, !name.isEmpty {
                if let fileImage = UIImage(contentsOfFile: name) {
                    Image(uiImage: fileImage)
                        .resizable()
                        .scaledToFill()
                } else if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                }
            }

            // Keep emoji/title readable over photos.
            if template.backgroundImageName != nil {
                LinearGradient(
                    colors: [.black.opacity(0.45), .black.opacity(0.15)],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            }
        }
    }
}
