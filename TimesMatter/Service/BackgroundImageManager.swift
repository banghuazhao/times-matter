import Foundation
import UIKit
import Dependencies

enum BackgroundImageError: LocalizedError {
    case failedToLoadImage
    case failedToCreateDirectory
    case failedToSaveImage
    case failedToDeleteImage
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadImage:
            return "Failed to load image from photo picker"
        case .failedToCreateDirectory:
            return "Failed to create backgrounds directory"
        case .failedToSaveImage:
            return "Failed to save image to backgrounds directory"
        case .failedToDeleteImage:
            return "Failed to delete old image"
        }
    }
}

// MARK: - Background Image Manager Protocol
protocol BackgroundImageManaging {
    func saveCustomBackgroundImage(_ image: UIImage) throws -> String
    func deleteCustomBackgroundImage(at imagePath: String) throws
    func isCustomBackgroundImagePath(_ imagePath: String) -> Bool
    func getAllCustomBackgroundImagePaths() -> [String]
    func cleanupAllCustomBackgroundImages()
}

@Observable
class BackgroundImageManager: BackgroundImageManaging {
    
    // MARK: - Constants
    private enum Constants {
        static let backgroundsDirectoryName = "Backgrounds"
        static let customImagePrefix = "custom_bg_"
        static let imageExtension = "jpg"
        static let maxImageDimension: CGFloat = 1080
        static let jpegCompressionQuality: CGFloat = 0.95
    }
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    
    // MARK: - Computed Properties
    private var backgroundsDirectoryURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(Constants.backgroundsDirectoryName)
    }
    
    // MARK: - Public Methods
    
    /// Saves a custom background image and returns the file path
    /// - Parameter image: The UIImage to save
    /// - Returns: The file path of the saved image
    /// - Throws: BackgroundImageError if the operation fails
    func saveCustomBackgroundImage(_ image: UIImage) throws -> String {
        // Ensure backgrounds directory exists
        try createBackgroundsDirectoryIfNeeded()
        
        // Resize image if needed
        let resizedImage = image.resizedToFit(maxDimension: Constants.maxImageDimension)
        
        // Generate unique filename
        let filename = "\(Constants.customImagePrefix)\(UUID().uuidString).\(Constants.imageExtension)"
        let fileURL = backgroundsDirectoryURL.appendingPathComponent(filename)
        
        #if DEBUG
        print("Background image URL: \(fileURL)")
        #endif
        
        // Save image
        guard let jpegData = resizedImage.jpegData(compressionQuality: Constants.jpegCompressionQuality) else {
            throw BackgroundImageError.failedToSaveImage
        }
        
        do {
            try jpegData.write(to: fileURL)
            return fileURL.path
        } catch {
            throw BackgroundImageError.failedToSaveImage
        }
    }
    
    /// Deletes a custom background image file
    /// - Parameter imagePath: The path to the image file to delete
    /// - Throws: BackgroundImageError if the operation fails
    func deleteCustomBackgroundImage(at imagePath: String) throws {
        guard isCustomBackgroundImagePath(imagePath) else { return }
        
        do {
            try fileManager.removeItem(atPath: imagePath)
        } catch {
            throw BackgroundImageError.failedToDeleteImage
        }
    }
    
    /// Checks if a given path is a custom background image
    /// - Parameter imagePath: The path to check
    /// - Returns: True if it's a custom background image path
    func isCustomBackgroundImagePath(_ imagePath: String) -> Bool {
        return imagePath.contains(Constants.customImagePrefix)
    }
    
    /// Gets all custom background image paths
    /// - Returns: Array of file paths for custom background images
    func getAllCustomBackgroundImagePaths() -> [String] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: backgroundsDirectoryURL, includingPropertiesForKeys: nil)
            return fileURLs
                .filter { $0.lastPathComponent.hasPrefix(Constants.customImagePrefix) }
                .map { $0.path }
        } catch {
            return []
        }
    }
    
    /// Cleans up all custom background images
    func cleanupAllCustomBackgroundImages() {
        let imagePaths = getAllCustomBackgroundImagePaths()
        for path in imagePaths {
            try? deleteCustomBackgroundImage(at: path)
        }
    }
    
    // MARK: - Private Methods
    
    private func createBackgroundsDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: backgroundsDirectoryURL.path) else { return }
        
        do {
            try fileManager.createDirectory(at: backgroundsDirectoryURL, withIntermediateDirectories: true)
        } catch {
            throw BackgroundImageError.failedToCreateDirectory
        }
    }
}


// MARK: - DependencyKey for BackgroundImageManager
private enum BackgroundImageManagerKey: DependencyKey {
    static let liveValue: BackgroundImageManaging = BackgroundImageManager()
}

extension DependencyValues {
    var backgroundImageManager: BackgroundImageManaging {
        get { self[BackgroundImageManagerKey.self] }
        set { self[BackgroundImageManagerKey.self] = newValue }
    }
}
