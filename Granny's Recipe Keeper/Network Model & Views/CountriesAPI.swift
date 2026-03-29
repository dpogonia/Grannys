//
//  CountriesAPI.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

// ДЗ MOYA: Реализация сетевого слоя с использованием Moya

import Foundation
import Moya
import Alamofire

// MARK: - Codable Models

// Реализован парсинг данных с помощью Codable
// Модель страны из REST Countries API
public struct Country: Codable {
    public let name: CountryName
    public let cca2: String?  // Двухбуквенный код страны (US, IT, etc.)
    public let region: String?
    public let subregion: String?
    public let population: Int?
    public let flags: CountryFlags?
    public let capital: [String]?
    
    public var displayName: String {
        return name.common
    }
    
    public var flagEmoji: String {
        guard let cca2 = cca2 else { return "🏳️" }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in cca2.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalarValue))
            }
        }
        return emoji.isEmpty ? "🏳️" : emoji
    }
}

public struct CountryName: Codable {
    public let common: String
    public let official: String?
}

public struct CountryFlags: Codable {
    public let png: String?
    public let svg: String?
}

public enum CountriesTarget {
    case allCountries
    case searchByName(String)
    case filterByRegion(String)
    case getByCode(String)
}

extension CountriesTarget: TargetType {
    
    // Базовый URL для REST Countries API
    public var baseURL: URL {
        return URL(string: "https://restcountries.com/v3.1")!
    }
    
    // Реализовано 3-4 метода
    public var path: String {
        switch self {
        case .allCountries:
            return "/all"
        case .searchByName(let name):
            return "/name/\(name)"
        case .filterByRegion(let region):
            return "/region/\(region)"
        case .getByCode(let code):
            return "/alpha/\(code)"
        }
    }
    
    // HTTP метод для каждого эндпоинта
    public var method: Moya.Method {
        switch self {
        case .allCountries, .searchByName, .filterByRegion, .getByCode:
            return .get
        }
    }
    
    // Параметры запроса
    public var task: Task {
        switch self {
        case .allCountries, .searchByName, .filterByRegion, .getByCode:
            return .requestParameters(
                parameters: ["fields": "name,cca2,region,subregion,population,flags,capital"],
                encoding: URLEncoding.queryString
            )
        }
    }
    
    // Заголовки запроса
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    // Данные для тестирования
    public var sampleData: Data {
        return Data()
    }
}

// Сервис для работы с REST Countries API через Moya
public class CountriesService {
    
    public static let shared = CountriesService()
    
    private let provider = MoyaProvider<CountriesTarget>(plugins: [
        NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
    ])
    
    private init() {}
    
    // 1: Получение всех стран
    // Реализован метод получения данных из API
    public func getAllCountries(completion: @escaping (Result<[Country], Error>) -> Void) {
        provider.request(.allCountries) { result in
            self.handleResponse(result, completion: completion)
        }
    }
    
    // 2: Поиск стран по названию
    public func searchCountries(by name: String, completion: @escaping (Result<[Country], Error>) -> Void) {
        provider.request(.searchByName(name)) { result in
            self.handleResponse(result, completion: completion)
        }
    }
    
    // 3: Фильтрация стран по региону
    public func getCountriesByRegion(_ region: String, completion: @escaping (Result<[Country], Error>) -> Void) {
        provider.request(.filterByRegion(region)) { result in
            self.handleResponse(result, completion: completion)
        }
    }
    
    // 4: Получение страны по коду
    public func getCountry(by code: String, completion: @escaping (Result<Country, Error>) -> Void) {
        provider.request(.getByCode(code)) { result in
            switch result {
            case .success(let response):
                do {
                    // Поддерживается общая обработка результатов/ошибок от API
                    let countries = try JSONDecoder().decode([Country].self, from: response.data)
                    if let country = countries.first {
                        completion(.success(country))
                    } else {
                        completion(.failure(NSError(domain: "CountriesAPI", code: 404, userInfo: [NSLocalizedDescriptionKey: "Country not found"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Универсальный обработчик ответов с использованием Codable
    private func handleResponse<T: Decodable>(_ result: Result<Response, MoyaError>, completion: @escaping (Result<T, Error>) -> Void) {
        switch result {
        case .success(let response):
            do {
                // Проверка статус кода HTTP
                guard (200...299).contains(response.statusCode) else {
                    let error = NSError(
                        domain: "CountriesAPI",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(response.statusCode)"]
                    )
                    completion(.failure(error))
                    return
                }
                
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: response.data)
                completion(.success(decodedData))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        case .failure(let error):
            // Поддерживается общая обработка результатов/ошибок от API
            print("Network error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
