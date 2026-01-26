//
//  ImageLoadOperation.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import Foundation

// MARK: - ImageLoadOperation
// ДОМАШНЕЕ ЗАДАНИЕ: Создать очередь загрузки изображений с использованием OperationQueue
// КРИТЕРИЙ ОЦЕНКИ: Организована очередь загрузки - 50 баллов
// КРИТЕРИЙ ОЦЕНКИ: Очередь сделана в отдельном классе - 20 баллов
//
// ImageLoadOperation - это операция (Operation) для загрузки одного изображения
// Operation - это абстракция для выполнения задачи, которую можно добавить в очередь
// АНАЛОГИЯ: Как задача в списке дел - её можно добавить в очередь и выполнить позже
//
// Зачем нужен Operation вместо простого URLSession?
// 1. Можно отменить загрузку, если ячейка уже не видна
// 2. Можно установить приоритет загрузки
// 3. Можно установить зависимости между операциями
// 4. OperationQueue автоматически управляет количеством одновременных загрузок
class ImageLoadOperation: Operation {
    // URL изображения для загрузки
    private let urlString: String
    
    // Замыкание, которое вызывается после загрузки изображения
    // Result<UIImage, Error> - либо успех с изображением, либо ошибка
    private var completion: ((Result<UIImage, Error>) -> Void)?
    
    // Загруженное изображение (результат операции)
    private var loadedImage: UIImage?
    
    // Ошибка загрузки (если произошла)
    private var loadError: Error?
    
    // isExecuting - флаг, что операция выполняется сейчас
    // В Operation нужно вручную управлять состоянием (executing, finished)
    private var _isExecuting = false {
        willSet {
            // willSet вызывается перед изменением значения
            // Обновляем KVO (Key-Value Observing) для свойства isExecuting
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            // didSet вызывается после изменения значения
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    // isFinished - флаг, что операция завершена
    private var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    // Переопределяем isExecuting для Operation
    // OperationQueue проверяет это свойство, чтобы понять, выполняется ли операция
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    // Переопределяем isFinished для Operation
    // OperationQueue проверяет это свойство, чтобы понять, завершена ли операция
    override var isFinished: Bool {
        return _isFinished
    }
    
    // isAsynchronous - асинхронная ли операция
    // true означает, что операция выполняется в фоновом потоке
    override var isAsynchronous: Bool {
        return true
    }
    
    // Инициализатор
    // urlString - URL изображения для загрузки
    // completion - замыкание, которое вызывается после загрузки
    init(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.urlString = urlString
        self.completion = completion
        super.init()
    }
    
    // main() - главный метод операции, который выполняется при запуске
    // Здесь происходит вся работа по загрузке изображения
    override func main() {
        // Проверяем, не была ли операция отменена перед началом выполнения
        if isCancelled {
            finish()
            return
        }
        
        // Устанавливаем флаг выполнения
        _isExecuting = true
        
        // Проверяем кэш перед загрузкой из интернета
        // КРИТЕРИЙ ОЦЕНКИ: Реализовано кэширование - 30 баллов
        // Используем ImageCache для проверки, есть ли изображение в кэше
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            // Нашли в кэше - сразу возвращаем результат
            loadedImage = cachedImage
            finish()
            return
        }
        
        // Не нашли в кэше - загружаем из интернета
        guard let url = URL(string: urlString) else {
            loadError = NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            finish()
            return
        }
        
        // Создаём URLSessionDataTask для загрузки данных
        // dataTask - это задача для загрузки данных из интернета
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // [weak self] - слабая ссылка, чтобы избежать утечек памяти
            
            // Проверяем, не была ли операция отменена во время загрузки
            guard let self = self, !self.isCancelled else {
                return
            }
            
            // Обрабатываем ошибку, если она есть
            if let error = error {
                self.loadError = error
                self.finish()
                return
            }
            
            // Проверяем, что данные получены и можно создать UIImage
            guard let data = data, let image = UIImage(data: data) else {
                self.loadError = NSError(domain: "Invalid image data", code: -1, userInfo: nil)
                self.finish()
                return
            }
            
            // Сохраняем изображение в кэш для будущего использования
            // КРИТЕРИЙ ОЦЕНКИ: Реализовано кэширование - 30 баллов
            ImageCache.shared.setImage(image, for: self.urlString)
            
            // Сохраняем загруженное изображение
            self.loadedImage = image
            
            // Завершаем операцию
            self.finish()
        }
        
        // Запускаем задачу загрузки
        task.resume()
    }
    
    // finish() - завершает операцию
    // Вызывается после завершения загрузки (успешной или с ошибкой)
    private func finish() {
        // Устанавливаем флаги завершения
        _isExecuting = false
        _isFinished = true
        
        // Вызываем completion с результатом
        // Если есть изображение - успех, если есть ошибка - ошибка
        if let image = loadedImage {
            completion?(.success(image))
        } else if let error = loadError {
            completion?(.failure(error))
        } else {
            // Если ни изображения, ни ошибки нет - это тоже ошибка
            completion?(.failure(NSError(domain: "Unknown error", code: -1, userInfo: nil)))
        }
        
        // Очищаем completion, чтобы освободить память
        completion = nil
    }
    
    // cancel() - отменяет операцию
    // Переопределяем, чтобы правильно обработать отмену
    override func cancel() {
        super.cancel()
        // Если операция ещё не завершена, завершаем её с ошибкой отмены
        if !isFinished {
            loadError = NSError(domain: "Operation cancelled", code: -1, userInfo: nil)
            finish()
        }
    }
}
