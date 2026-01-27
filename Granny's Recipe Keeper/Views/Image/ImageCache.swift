//
//  ImageCache.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 27 Operation, OperationQueue. Реализация кэширования изображений.
// ДЗ ТЕМА 30: Порождающие паттерны. Singleton.

import UIKit

// MARK: - ImageCache
// ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 27 Operation, OperationQueue: Реализация кэширования изображений
// Реализовано кэширование
// Двухуровневая система кэширования: в памяти (NSCache) и на диске (FileManager)

class ImageCache {
    // ПАТТЕРН SINGLETON: Единственный экземпляр кэша изображений
    static let shared = ImageCache()
    
    // Кэш в памяти с автоматической очисткой при нехватке памяти
    private let cache = NSCache<NSString, UIImage>()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        
        // Настройка кэша в памяти
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        
        // Создание директории для кэша на диске
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // Получение изображения: сначала из памяти, затем с диска
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
    
    // Сохранение изображения в кэш (память и диск)
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
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
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
