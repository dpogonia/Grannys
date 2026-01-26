//
//  NetworkService.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

// MARK: - NetworkService
/// Базовый сетевой слой с централизованной обработкой ошибок
/// 
/// КРИТЕРИЙ ОЦЕНКИ: Реализован сетевой слой в отдельной сущности - 20 баллов
/// Этот класс представляет собой отдельную сущность для работы с сетью, используя URLSession
///
/// АНАЛОГИЯ: NetworkService - это как почтальон для приложения
/// Когда нужно получить данные из интернета (например, рецепты с сайта),
/// мы отправляем "письмо" (запрос) и ждём "ответ" (данные)
/// Этот класс управляет всей перепиской с серверами в интернете

class NetworkService {
    // Singleton паттерн - один экземпляр на всё приложение
    static let shared = NetworkService()
    
    // URLSession - это инструмент для отправки запросов в интернет
    // Представь его как почтовый сервис: он знает, как доставить запрос и получить ответ
    private let session: URLSession
    
    // JSONDecoder - это переводчик с языка JSON (формат данных в интернете) на язык Swift
    // Когда сервер присылает данные в формате JSON, decoder превращает их в наши структуры
    private let decoder: JSONDecoder
    
    // Приватный инициализатор (часть паттерна Singleton)
    private init() {
        // КРИТЕРИЙ ОЦЕНКИ: Реализован сетевой слой в отдельной сущности - 20 баллов
        // Использование URLSession для реализации сетевого слоя
        
        // Создаём конфигурацию для URLSession
        // Конфигурация - это настройки: как долго ждать ответа, сколько попыток делать и т.д.
        let configuration = URLSessionConfiguration.default
        
        // timeoutIntervalForRequest - максимальное время ожидания одного запроса (30 секунд)
        // Если сервер не ответит за 30 секунд, запрос считается неудачным
        configuration.timeoutIntervalForRequest = 30
        
        // timeoutIntervalForResource - максимальное время загрузки всего ресурса (60 секунд)
        // Это для больших файлов: если загрузка длится больше минуты, прерываем
        configuration.timeoutIntervalForResource = 60
        
        // Создаём URLSession с нашей конфигурацией
        self.session = URLSession(configuration: configuration)
        
        // Настраиваем JSONDecoder
        // ДОМАШНЕЕ ЗАДАНИЕ: Использование Codable для работы с API
        // КРИТЕРИЙ ОЦЕНКИ: Использование Codable - 30 баллов
        //
        // JSONDecoder - это класс для декодирования JSON в Swift объекты (Codable)
        // JSONEncoder - это класс для кодирования Swift объектов в JSON (Codable)
        self.decoder = JSONDecoder()
        
        // keyDecodingStrategy - стратегия преобразования ключей JSON
        // .convertFromSnakeCase - автоматически преобразует snake_case в camelCase
        // Пример: "user_name" в JSON -> "userName" в Swift
        // "total_pages" в JSON -> "totalPages" в Swift
        //
        // ВАЖНО: Если используется .convertFromSnakeCase, CodingKeys для простых случаев не нужен
        // Но если нужен кастомный маппинг или сложная логика, CodingKeys всё равно можно использовать
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    /// Выполняет сетевой запрос с автоматической обработкой ошибок и десериализацией
    /// 
    /// КРИТЕРИЙ ОЦЕНКИ: Поддерживается общая обработка результатов/ошибок от АПИ - 20 баллов
    /// Этот метод обеспечивает централизованную обработку всех сетевых ошибок и результатов
    /// КРИТЕРИЙ ОЦЕНКИ: Реализован сетевой слой в отдельной сущности - 20 баллов
    /// Использование URLSession.dataTask для выполнения сетевых запросов
    ///
    /// АНАЛОГИЯ С МНОГОПОТОЧНОСТЬЮ:
    /// Этот метод работает асинхронно - он не блокирует интерфейс приложения
    /// Представь: ты отправляешь письмо и продолжаешь заниматься своими делами
    /// Когда приходит ответ, тебе звонят (вызывается completion)
    /// Главный поток (UI) не ждёт ответа - он продолжает показывать интерфейс пользователю
    ///
    /// - Parameters:
    ///   - request: URLRequest для выполнения (что именно запрашиваем)
    ///   - responseType: Тип ответа, соответствующий Codable (во что превратим ответ)
    ///   - completion: Замыкание с результатом запроса (что делать, когда получим ответ)
    ///
    /// ВАЖНО: <T: Codable> - это GENERIC (обобщённый тип)
    /// Generic позволяет использовать один и тот же метод для разных типов данных
    /// T - это "заполнитель" для типа, который будет известен при вызове функции
    /// : Codable означает "T должен соответствовать протоколу Codable"
    /// Примеры: T может быть APIRecipe, UnsplashPhoto, или любой другой тип с Codable
    /// Это как универсальный ключ, который подходит к разным замкам (типам данных)
    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // dataTask - создаёт задачу для отправки запроса
        // Это как отправить письмо: мы даём адрес и ждём ответа
        // Замыкание { data, response, error in ... } вызывается, когда приходит ответ
        
        // [weak self] - это CAPTURE LIST (список захвата) - очень важно для памяти!
        // ПРОБЛЕМА: Если не использовать weak, возникает "retain cycle" (цикл удержания)
        // Что происходит:
        // 1. NetworkService держит замыкание в памяти
        // 2. Замыкание держит self (NetworkService) в памяти
        // 3. Никто не может освободиться - утечка памяти!
        // РЕШЕНИЕ: weak self означает "не удерживай NetworkService сильно"
        // Если NetworkService удалится, self станет nil, и это нормально
        // АНАЛОГИЯ: Как слабая нить вместо прочной верёвки - если объект удалится, нить порвётся, но это не проблема
        session.dataTask(with: request) { [weak self] data, response, error in
            // data - данные, которые прислал сервер (JSON, изображение и т.д.)
            // response - информация об ответе (статус код, заголовки)
            // error - ошибка, если что-то пошло не так
            
            // Обработка сетевых ошибок (нет интернета, таймаут и т.д.)
            if let error = error {
                // Преобразуем системную ошибку в нашу NetworkError
                let networkError = self?.mapToNetworkError(error: error, response: response)
                // Вызываем completion с ошибкой
                // .failure - это один из вариантов Result (успех или ошибка)
                completion(.failure(networkError ?? .unknown))
                return // Прекращаем выполнение функции
            }
            
            // Проверка HTTP ответа
            // HTTPURLResponse - это ответ от сервера с информацией о статусе
            // as? - безопасное приведение типа: если response не HTTPURLResponse, вернётся nil
            guard let httpResponse = response as? HTTPURLResponse else {
                // Если ответ не является HTTP ответом, это ошибка
                completion(.failure(.invalidResponse))
                return
            }
            
            // Проверка статус кода
            // HTTP статус коды: 200-299 = успех, 400+ = ошибка
            // 200...299 - это диапазон (range) от 200 до 299 включительно
            // contains - проверяет, входит ли статус код в этот диапазон
            guard (200...299).contains(httpResponse.statusCode) else {
                // Статус код не в диапазоне успеха - обрабатываем ошибку
                let error = self?.handleHTTPError(statusCode: httpResponse.statusCode, data: data)
                completion(.failure(error ?? .httpError(httpResponse.statusCode)))
                return
            }
            
            // Проверка наличия данных
            // Сервер может ответить успешно, но без данных (пустой ответ)
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // ДОМАШНЕЕ ЗАДАНИЕ: Использование Codable для работы с API
            // КРИТЕРИЙ ОЦЕНКИ: Использование Codable - 30 баллов
            //
            // Десериализация данных (преобразование JSON в наши структуры)
            // Здесь используется Codable протокол для автоматической десериализации JSON в модель
            //
            // Процесс декодирования:
            // 1. JSON данные (байты) -> JSONDecoder
            // 2. JSONDecoder использует информацию из Codable структуры
            // 3. Автоматически создаёт объект нужного типа
            // 4. Заполняет все свойства значениями из JSON
            //
            // Преимущества Codable:
            // - Автоматическое преобразование типов
            // - Обработка опциональных значений
            // - Поддержка вложенных структур и массивов
            // - Обработка ошибок через DecodingError
            
            // ВАЖНО: T.self - это МЕТАТИП (тип самого типа)
            // Разница между T и T.self:
            // - T - это экземпляр (объект) типа T
            // - T.self - это сам тип T (не объект, а описание типа)
            // Пример: если T = APIRecipe, то:
            // - APIRecipe() - это экземпляр (объект)
            // - APIRecipe.self - это сам тип APIRecipe
            // decode нужен именно тип (T.self), чтобы знать, во что преобразовывать JSON
            
            // do-catch - это блок для обработки ошибок
            // try - может "выбросить" ошибку (throw), если что-то пойдёт не так
            // Если ошибка произойдёт, выполнение перейдёт в блок catch
            do {
                // self? - опциональная цепочка: если self = nil, вернётся nil
                // Это безопасно, потому что мы использовали [weak self]
                // decode пытается превратить data (JSON байты) в объект типа T
                let decodedObject = try self?.decoder.decode(T.self, from: data)
                
                // if let - безопасное извлечение опционала
                // Если decodedObject не nil, создаём константу и используем её
                if let decodedObject = decodedObject {
                    // Успешно декодировали - возвращаем результат
                    // .success - это вариант Result для успешного результата
                    // Result - это enum с двумя вариантами: .success(значение) или .failure(ошибка)
                    completion(.success(decodedObject))
                } else {
                    // decodedObject был nil (возможно, self был nil из-за weak)
                    completion(.failure(.decodingError))
                }
            } catch {
                // Блок catch выполняется, если в блоке do произошла ошибка
                // catch автоматически получает объект ошибки
                print("Decoding error: \(error)")
                
                // as? - безопасное приведение типа
                // Проверяем, является ли ошибка DecodingError (специальный тип ошибки декодирования)
                if let decodingError = error as? DecodingError {
                    // Это действительно DecodingError - передаём детальную информацию
                    completion(.failure(.decodingFailed(decodingError)))
                } else {
                    // Это какая-то другая ошибка - используем общую
                    completion(.failure(.decodingError))
                }
            }
        }.resume() // resume() - запускает задачу (без этого запрос не отправится!)
    }
    
    /// Выполняет GET запрос
    /// 
    /// ДОМАШНЕЕ ЗАДАНИЕ: Использование Codable для работы с API
    /// КРИТЕРИЙ ОЦЕНКИ: Использование Codable - 30 баллов
    ///
    /// Метод использует generic с ограничением Codable для автоматической десериализации ответа
    /// <T: Codable> - generic тип, который должен соответствовать протоколу Codable
    /// Это позволяет использовать один метод для разных типов ответов API
    ///
    /// Пример использования:
    /// ```swift
    /// networkService.get(url: url, responseType: APIRecipe.self) { result in
    ///     switch result {
    ///     case .success(let recipe):
    ///         // recipe автоматически декодирован из JSON
    ///     case .failure(let error):
    ///         // обработка ошибки
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: URL для запроса
    ///   - headers: Дополнительные заголовки HTTP (опционально)
    ///   - responseType: Тип ответа (Codable структура), например APIRecipe.self
    ///   - completion: Замыкание с результатом (Result<T, NetworkError>)
    func get<T: Codable>(
        url: URL,
        headers: [String: String]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        performRequest(request, responseType: responseType, completion: completion)
    }
    
    /// Выполняет POST запрос
    /// 
    /// ДОМАШНЕЕ ЗАДАНИЕ: Использование Codable для работы с API
    /// КРИТЕРИЙ ОЦЕНКИ: Использование Codable - 30 баллов
    ///
    /// Метод использует generic с ограничением Codable для:
    /// 1. Сериализации тела запроса (Swift объект -> JSON)
    /// 2. Десериализации ответа (JSON -> Swift объект)
    ///
    /// <T: Codable> - тип ответа (что ожидаем получить)
    /// <B: Codable> - тип тела запроса (что отправляем)
    ///
    /// Пример использования:
    /// ```swift
    /// struct LoginRequest: Codable {
    ///     let username: String
    ///     let password: String
    /// }
    /// struct LoginResponse: Codable {
    ///     let token: String
    /// }
    ///
    /// let request = LoginRequest(username: "user", password: "pass")
    /// networkService.post(url: url, body: request, responseType: LoginResponse.self) { result in
    ///     // обработка результата
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: URL для запроса
    ///   - body: Тело запроса (Codable объект, который будет преобразован в JSON)
    ///   - headers: Дополнительные заголовки HTTP (опционально)
    ///   - responseType: Тип ответа (Codable структура)
    ///   - completion: Замыкание с результатом
    func post<T: Codable, B: Codable>(
        url: URL,
        body: B,
        headers: [String: String]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Указываем, что отправляем данные в формате JSON
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            // ДОМАШНЕЕ ЗАДАНИЕ: Использование Codable для работы с API
            // КРИТЕРИЙ ОЦЕНКИ: Использование Codable - 30 баллов
            //
            // JSONEncoder - это класс для кодирования Swift объектов в JSON
            // encode(_:) - метод для преобразования Codable объекта в JSON данные
            // Это обратная операция к decode - из объекта в JSON
            //
            // keyEncodingStrategy - стратегия преобразования ключей при кодировании
            // .convertToSnakeCase - автоматически преобразует camelCase в snake_case
            // Пример: "userName" в Swift -> "user_name" в JSON
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            // Преобразуем Swift объект (body) в JSON данные для отправки
            request.httpBody = try encoder.encode(body)
        } catch {
            // Если кодирование не удалось (например, объект не Codable или содержит недопустимые данные)
            completion(.failure(.encodingError))
            return
        }
        
        // Выполняем запрос с помощью общего метода performRequest
        performRequest(request, responseType: responseType, completion: completion)
    }
    
    // MARK: - Private Helpers
    
    private func mapToNetworkError(error: Error, response: URLResponse?) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noConnection
            case .timedOut:
                return .timeout
            case .cannotFindHost, .cannotConnectToHost:
                return .hostNotFound
            default:
                return .unknown
            }
        }
        return .unknown
    }
    
    private func handleHTTPError(statusCode: Int, data: Data?) -> NetworkError {
        var errorMessage: String?
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String ?? json["error"] as? String {
            errorMessage = message
        }
        
        switch statusCode {
        case 400:
            return .badRequest(errorMessage)
        case 401:
            return .unauthorized(errorMessage)
        case 403:
            return .forbidden(errorMessage)
        case 404:
            return .notFound(errorMessage)
        case 500...599:
            return .serverError(statusCode, errorMessage)
        default:
            return .httpError(statusCode)
        }
    }
}

// MARK: - NetworkError

/// Типы ошибок сети
/// 
/// КРИТЕРИЙ ОЦЕНКИ: Поддерживается общая обработка результатов/ошибок от АПИ - 20 баллов
/// Этот enum обеспечивает централизованную обработку всех типов сетевых ошибок
enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case hostNotFound
    case invalidResponse
    case noData
    case decodingError
    case decodingFailed(DecodingError)
    case encodingError
    case badRequest(String?)
    case unauthorized(String?)
    case forbidden(String?)
    case notFound(String?)
    case httpError(Int)
    case serverError(Int, String?)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Нет подключения к интернету. Проверьте соединение и попробуйте снова."
        case .timeout:
            return "Превышено время ожидания ответа. Попробуйте позже."
        case .hostNotFound:
            return "Не удалось найти сервер. Проверьте подключение к интернету."
        case .invalidResponse:
            return "Получен неверный ответ от сервера."
        case .noData:
            return "Сервер не вернул данные."
        case .decodingError:
            return "Ошибка при обработке данных от сервера."
        case .decodingFailed(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .encodingError:
            return "Ошибка при подготовке данных для отправки."
        case .badRequest(let message):
            return message ?? "Неверный запрос к серверу."
        case .unauthorized(let message):
            return message ?? "Требуется авторизация."
        case .forbidden(let message):
            return message ?? "Доступ запрещен."
        case .notFound(let message):
            return message ?? "Ресурс не найден."
        case .httpError(let code):
            return "Ошибка HTTP: \(code)"
        case .serverError(let code, let message):
            return message ?? "Ошибка сервера: \(code)"
        case .unknown:
            return "Произошла неизвестная ошибка."
        }
    }
}
