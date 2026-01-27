//
//  ImageLoadQueueManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 27 Operation, OperationQueue.
// ДЗ ТЕМА 30. Паттерн Singleton

import UIKit
import Foundation

class ImageLoadQueueManager {
    
    // ПАТТЕРН SINGLETON: Единственный экземпляр менеджера очереди загрузки изображений
    static let shared = ImageLoadQueueManager()
    
    // ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 27 Operation, OperationQueue: Создать очередь загрузки изображений с использованием OperationQueue
    // Менеджер очереди загрузки изображений, управляющий OperationQueue для загрузки изображений для ячеек таблицы/коллекции
    // OperationQueue автоматически управляет выполнением операций в фоновых потоках
    private let loadQueue: OperationQueue
    
    private var activeOperations: [String: ImageLoadOperation] = [:]
    
    private let synchronizationQueue = DispatchQueue(label: "com.grannys.imageLoadQueue", attributes: .concurrent)
    
    private init() {
        
        // Организована очередь загрузки
        // Создание OperationQueue для загрузки изображений
        loadQueue = OperationQueue()
        loadQueue.maxConcurrentOperationCount = 5
        loadQueue.name = "ImageLoadQueue"
        loadQueue.qualityOfService = .utility
    }
    
    // Загружает изображение по URL
    @discardableResult
    func loadImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) -> Operation? {
        
        // Реализовано кэширование
        // Проверка кэша перед созданием операции
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
            
            // Очередь сделана в отдельном классе
            // ImageLoadOperation - отдельный класс для загрузки одного изображения
            let operation = ImageLoadOperation(urlString: urlString) { [weak self] result in
                self?.synchronizationQueue.async(flags: .barrier) {
                    self?.activeOperations.removeValue(forKey: urlString)
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
            
            activeOperations[urlString] = operation
            
            // Организована очередь загрузки
            // Добавление операции в OperationQueue
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
            for operation in self.activeOperations.values {
                operation.cancel()
            }
            self.activeOperations.removeAll()
        }
    }
}
