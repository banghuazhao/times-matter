//
// Created by Banghua Zhao on 12/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import UIKit

// MARK: - UIImage Resize Helper
extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let maxCurrentDimension = max(size.width, size.height)
        guard maxCurrentDimension > maxDimension else { return self }
        let scale = maxDimension / maxCurrentDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
