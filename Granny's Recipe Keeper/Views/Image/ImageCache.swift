//
//  ImageCache.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

enum ImageLoadError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidData
    case decodingFailed
    case cancelled
    case fileSystemError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid image data received"
        case .decodingFailed:
            return "Failed to decode image"
        case .cancelled:
            return "Image load was cancelled"
        case .fileSystemError:
            return "File system error while caching"
        }
    }
}

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        print("📦 ImageCache initialized with memory warning handler")
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received - clearing image cache in memory")
        clearMemoryCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func image(for urlString: String) -> UIImage? {
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }
        
        if let diskImage = loadFromDisk(urlString: urlString) {
            cache.setObject(diskImage, forKey: urlString as NSString)
            return diskImage
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.saveToDisk(image: image, urlString: urlString)
        }
    }
    
    private func loadFromDisk(urlString: String) -> UIImage? {
        let fileName = urlString.md5
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveToDisk(image: UIImage, urlString: String) {
        let fileName = urlString.md5
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        try? data.write(to: fileURL)
    }
    
    func clearMemoryCache() {
        cache.removeAllObjects()
        print("🗑️ Memory cache cleared")
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        do {
            try fileManager.removeItem(at: cacheDirectory)
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            print("🗑️ Full cache cleared (memory + disk)")
        } catch {
            print("❌ Error clearing disk cache: \(error.localizedDescription)")
        }
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
}

import CryptoKit

extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
