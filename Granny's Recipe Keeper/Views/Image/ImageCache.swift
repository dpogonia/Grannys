//
//  ImageCache.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - ImageCache
// ДОМАШНЕЕ ЗАДАНИЕ: Реализация кэширования изображений
// КРИТЕРИЙ ОЦЕНКИ: Реализовано кэширование - 30 баллов

// Реализация кэширования:
// 1. В памяти (NSCache) - быстрый доступ, но ограниченный размер
// 2. На диске (FileManager) - медленнее, но постоянное хранение
// Это двухуровневая система кэширования для оптимальной производительности

class ImageCache {
    // Singleton паттерн - один экземпляр на всё приложение
    // Все части приложения используют один и тот же кэш
    static let shared = ImageCache()
    
    // NSCache - это словарь (ключ-значение) с автоматической очисткой
    // Когда память заканчивается, старые изображения удаляются автоматически
    // <NSString, UIImage> означает: ключ - строка (URL), значение - изображение
    private let cache = NSCache<NSString, UIImage>()
    
    // FileManager - это менеджер файловой системы
    // С его помощью мы работаем с файлами на диске (создаём, читаем, удаляем)
    private let fileManager = FileManager.default
    
    // URL папки, где хранятся изображения на диске
    private let cacheDirectory: URL
    
    // private init() - приватный инициализатор
    // Это значит, что создать ImageCache можно только через .shared
    // Это часть паттерна Singleton
    private init() {
        // Настраиваем кэш в памяти (быстрый склад)
        // countLimit - максимальное количество изображений в памяти (100 штук)
        cache.countLimit = 100
        
        // totalCostLimit - максимальный размер всех изображений в памяти (50 МБ)
        // 50 * 1024 * 1024 = 50 мегабайт
        // Когда размер превысит лимит, старые изображения удалятся
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        
        // Создаем директорию для кэша на диске (медленный склад)
        // .cachesDirectory - это специальная папка для временных данных приложения
        // Система может её очистить, если нужно место, но обычно она сохраняется
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // appendingPathComponent - добавляет подпапку "ImageCache"
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Создаем директорию, если её нет
        // fileExists - проверяет, существует ли файл/папка
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            // createDirectory - создаёт папку
            // withIntermediateDirectories: true - создаёт все промежуточные папки, если их нет
            // try? - если ошибка, просто игнорируем (папка уже существует)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // Получить изображение по URL
    // Сначала ищем в памяти (быстро), потом на диске (медленнее)
    func image(for urlString: String) -> UIImage? {
        // Сначала проверяем кэш в памяти (быстрый склад)
        // object(forKey:) - ищет изображение по ключу (URL)
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            // Нашли в памяти - возвращаем сразу (очень быстро!)
            return cachedImage
        }
        
        // Не нашли в памяти - проверяем кэш на диске (медленный склад)
        if let diskImage = loadFromDisk(urlString: urlString) {
            // Нашли на диске - сохраняем в память для следующего раза
            // Теперь следующее обращение будет быстрым
            cache.setObject(diskImage, forKey: urlString as NSString)
            return diskImage
        }
        
        // Не нашли нигде - возвращаем nil
        // Придётся загружать из интернета заново
        return nil
    }
    
    // Сохранить изображение в кэш
    func setImage(_ image: UIImage, for urlString: String) {
        // Сохраняем в кэш памяти (быстрый склад)
        // Это происходит синхронно (сразу, блокируя выполнение)
        cache.setObject(image, forKey: urlString as NSString)
        
        // Сохраняем на диск асинхронно (в фоновом потоке)
        // АНАЛОГИЯ С МНОГОПОТОЧНОСТЬЮ:
        // Представь ресторан: главный поток (UI) - это официант, который обслуживает клиентов
        // Фоновый поток - это повар на кухне, который готовит блюда
        // Официант не может ждать, пока повар закончит готовить - он должен обслуживать клиентов!
        // Поэтому сохранение на диск происходит "на кухне" (в фоне), а официант продолжает работать
        
        // DispatchQueue - это очередь задач (queue)
        // .global - глобальная очередь (общая для всех приложений)
        // qos (quality of service) - приоритет задачи:
        //   .userInteractive - самый высокий (анимации UI)
        //   .userInitiated - высокий (действия пользователя)
        //   .default - средний (по умолчанию)
        //   .utility - средний-низкий (загрузка данных, сохранение файлов) ← мы используем это
        //   .background - самый низкий (фоновые задачи)
        // async - выполнить асинхронно (не ждать завершения, продолжить выполнение)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            // [weak self] - это CAPTURE LIST (список захвата) - очень важно!
            
            // ПРОБЛЕМА БЕЗ WEAK (retain cycle):
            // 1. ImageCache.shared держит замыкание в памяти
            // 2. Замыкание держит self (ImageCache) в памяти
            // 3. ImageCache не может освободиться, пока замыкание существует
            // 4. Замыкание не может освободиться, пока ImageCache существует
            // 5. УТЕЧКА ПАМЯТИ! 💥
            
            // РЕШЕНИЕ С WEAK:
            // weak self означает "не удерживай ImageCache сильно"
            // Если ImageCache удалится, self станет nil
            // self? - опциональная цепочка: если self = nil, ничего не произойдёт
            // Это безопасно и предотвращает утечки памяти
            
            self?.saveToDisk(image: image, urlString: urlString)
        }
    }
    
    // Загрузить изображение с диска
    // Приватная функция (private) - можно вызывать только внутри этого класса
    private func loadFromDisk(urlString: String) -> UIImage? {
        // md5 - это хэш-функция, которая превращает строку в уникальный код
        // Например: "https://example.com/image.jpg" -> "a1b2c3d4e5f6..."
        // Зачем это нужно? URL может содержать недопустимые символы для имени файла
        // (например, "/", "?", "&"), а md5 всегда даёт безопасное имя файла
        let fileName = urlString.md5
        // Формируем полный путь к файлу: папка кэша + имя файла
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // guard - это "охранник": если условие не выполнится, функция прекратит работу
        // Здесь мы проверяем два условия:
        // 1. Можем ли прочитать данные из файла
        // 2. Можем ли создать UIImage из этих данных
        // Если хотя бы одно не удастся, вернём nil
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // Сохранить изображение на диск
    // Эта функция вызывается в фоновом потоке (не блокирует интерфейс)
    private func saveToDisk(image: UIImage, urlString: String) {
        // Создаём имя файла из URL (через md5)
        let fileName = urlString.md5
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Преобразуем UIImage в данные (JPEG формат)
        // compressionQuality: 0.8 - качество сжатия (0.0 = худшее, 1.0 = лучшее)
        // 0.8 - хороший баланс между качеством и размером файла
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            // Если не удалось создать данные, прекращаем работу
            return
        }
        
        // Записываем данные в файл
        // try? - если ошибка (например, нет места на диске), просто игнорируем
        try? data.write(to: fileURL)
    }
    
    // Очистить весь кэш (и память, и диск)
    // Полезно, если нужно освободить место
    func clearCache() {
        // Удаляем все изображения из памяти
        cache.removeAllObjects()
        
        // Удаляем папку с файлами на диске
        try? fileManager.removeItem(at: cacheDirectory)
        // Создаём папку заново (она будет пустая)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

import CryptoKit

// MARK: - String Extension
// Extension добавляет новое свойство к типу String
// Теперь у любой строки есть свойство .md5, которое возвращает MD5 хэш

extension String {
    // Вычисляемое свойство (computed property) - вычисляет MD5 хэш строки
    // MD5 - это алгоритм, который превращает любую строку в уникальный код фиксированной длины
    // Например: "hello" -> "5d41402abc4b2a76b9719d911017c592"
    // Зачем это нужно? Для создания безопасных имён файлов из URL
    var md5: String {
        // Преобразуем строку в данные (байты)
        // utf8 - это кодировка символов (как буквы превращаются в числа)
        let data = Data(self.utf8)
        
        // Вычисляем MD5 хэш
        // Insecure.MD5 - это устаревший алгоритм (небезопасный для паролей),
        // но для имён файлов он подходит отлично
        let hash = Insecure.MD5.hash(data: data)
        
        // Преобразуем хэш в строку
        // map - преобразует каждый байт в строку из двух символов (hex)
        // format: "%02x" - формат: два символа в шестнадцатеричной системе
        // joined() - соединяет все строки в одну
        // Результат: "a1b2c3d4e5f6..."
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
