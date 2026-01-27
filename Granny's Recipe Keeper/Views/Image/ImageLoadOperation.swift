//
//  ImageLoadOperation.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 27 Operation, OperationQueue.
// ДЗ ТЕМА 32: ПОВЕДЕНЧЕСКИЕ ПАТТЕРНЫ - Command.

import UIKit
import Foundation

// MARK: - ImageLoadOperation
// ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 27 Operation, OperationQueue: Создать очередь загрузки изображений с использованием OperationQueue
// Организована очередь загрузки - 50 баллов
// Очередь сделана в отдельном классе - 20 баллов
// Реализовано кэширование - 30 баллов

// ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 32: ПОВЕДЕНЧЕСКИЕ ПАТТЕРНЫ
// ПАТТЕРН : COMMAND (КОМАНДА). Инкапсулирует запрос как объект, позволяя параметризовать клиентов с разными запросами, ставить запросы в очередь, логировать их и поддерживать отмену операций. ImageLoadOperation инкапсулирует команду загрузки изображения
// - Запрос (загрузка изображения) представлен как объект Operation
// - Команды могут быть поставлены в очередь (через OperationQueue)
// - Команды могут быть отменены (cancel())
// - Изоляция кода выполнения запроса от кода, который инициирует запрос

// Операция для загрузки одного изображения
class ImageLoadOperation: Operation {
    private let urlString: String
    private var completion: ((Result<UIImage, Error>) -> Void)?
    private var loadedImage: UIImage?
    private var loadError: Error?
    
    private var _isExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    init(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.urlString = urlString
        self.completion = completion
        super.init()
    }
    
    // ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 27 Operation, OperationQueue: Организована очередь загрузки.
    // Главный метод операции, который выполняется при запуске
    override func main() {
        if isCancelled {
            finish()
            return
        }
        
        _isExecuting = true
        
        // Проверка кэша перед загрузкой из интернета
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            loadedImage = cachedImage
            finish()
            return
        }
        
        guard let url = URL(string: urlString) else {
            loadError = NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            finish()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, !self.isCancelled else {
                return
            }
            
            if let error = error {
                self.loadError = error
                self.finish()
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                self.loadError = NSError(domain: "Invalid image data", code: -1, userInfo: nil)
                self.finish()
                return
            }
            
            // Сохранение изображения в кэш для будущего использования
            ImageCache.shared.setImage(image, for: self.urlString)
            
            self.loadedImage = image
            self.finish()
        }
        
        task.resume()
    }
    
    private func finish() {
        _isExecuting = false
        _isFinished = true
        
        if let image = loadedImage {
            completion?(.success(image))
        } else if let error = loadError {
            completion?(.failure(error))
        } else {
            completion?(.failure(NSError(domain: "Unknown error", code: -1, userInfo: nil)))
        }
        
        completion = nil
    }
    
    // ДЗ ТЕМА 32. Поведенческие паттерны.
    // ПАТТЕРН COMMAND: Отмена команды
    // Одно из преимуществ паттерна Command - возможность отменить выполнение команды
    override func cancel() {
        super.cancel()
        if !isFinished {
            loadError = NSError(domain: "Operation cancelled", code: -1, userInfo: nil)
            finish()
        }
    }
}
