//
//  ImageLoadQueueManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import Foundation

class ImageLoadQueueManager {
    
    static let shared = ImageLoadQueueManager()
    
    private let loadQueue: OperationQueue
    
    private var activeOperations: [String: ImageLoadOperation] = [:]
    
    private let synchronizationQueue = DispatchQueue(label: "com.grannys.imageLoadQueue", attributes: .concurrent)
    
    private init() {
        loadQueue = OperationQueue()
        loadQueue.maxConcurrentOperationCount = 5
        loadQueue.name = "ImageLoadQueue"
        loadQueue.qualityOfService = .utility
        
        // Подписка на уведомление о нехватке памяти
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        print("🔄 ImageLoadQueueManager initialized")
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received - suspending image load queue")
        loadQueue.isSuspended = true
        
        // Отменяем все активные операции для освобождения памяти
        cancelAllLoads()
        
        // Возобновляем очередь через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            print("▶️ Resuming image load queue")
            self?.loadQueue.isSuspended = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Загружает изображение по URL
    @discardableResult
    func loadImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) -> Operation? {
        
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            DispatchQueue.main.async {
                completion(.success(cachedImage))
            }
            return nil
        }
        
        return synchronizationQueue.sync {
            if let existingOperation = activeOperations[urlString] {
                return existingOperation
            }
            
            let operation = ImageLoadOperation(urlString: urlString) { [weak self] result in
                self?.synchronizationQueue.async(flags: .barrier) {
                    self?.activeOperations.removeValue(forKey: urlString)
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
            
            activeOperations[urlString] = operation
            
            loadQueue.addOperation(operation)
            
            return operation
        }
    }
    
    func cancelLoad(urlString: String) {
        synchronizationQueue.async(flags: .barrier) {
            if let operation = self.activeOperations[urlString] {
                operation.cancel()
                self.activeOperations.removeValue(forKey: urlString)
            }
        }
    }
    
    func cancelAllLoads() {
        synchronizationQueue.async(flags: .barrier) {
            let count = self.activeOperations.count
            print("🚫 Cancelling \(count) active image load operations")
            
            for operation in self.activeOperations.values {
                operation.cancel()
            }
            self.activeOperations.removeAll()
        }
    }
    
    // Получение статистики очереди
    func getQueueStatistics() -> (activeOperations: Int, queuedOperations: Int) {
        return synchronizationQueue.sync {
            return (activeOperations.count, loadQueue.operationCount)
        }
    }
}
