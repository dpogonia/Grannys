//
//  NetworkService.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

class NetworkService {
    
    static let shared = NetworkService()
    
    private let session: URLSession
    
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        session.dataTask(with: request) { [weak self] data, response, error in
            
            if let error = error {
                let networkError = self?.mapToNetworkError(error: error, response: response)
                completion(.failure(networkError ?? .unknown))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = self?.handleHTTPError(statusCode: httpResponse.statusCode, data: data)
                completion(.failure(error ?? .httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decodedObject = try self?.decoder.decode(T.self, from: data)
                if let decodedObject = decodedObject {
                    completion(.success(decodedObject))
                } else {
                    completion(.failure(.decodingError))
                }
            } catch {
                print("Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    completion(.failure(.decodingFailed(decodingError)))
                } else {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
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
    
    func post<T: Codable, B: Codable>(
        url: URL,
        body: B,
        headers: [String: String]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(.encodingError))
            return
        }
        
        performRequest(request, responseType: responseType, completion: completion)
    }
    
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
            return "No Internet."
        case .timeout:
            return "Timeout. Try later."
        case .hostNotFound:
            return "Server not found. Check Interney."
        case .invalidResponse:
            return "Invalid response."
        case .noData:
            return "No data returned."
        case .decodingError:
            return "Decoding error."
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .encodingError:
            return "Encoding error."
        case .badRequest(let message):
            return message ?? "Wrong request to server."
        case .unauthorized(let message):
            return message ?? "Authorisation required."
        case .forbidden(let message):
            return message ?? "Access denied."
        case .notFound(let message):
            return message ?? "Resource not found."
        case .httpError(let code):
            return "HTTP Error: \(code)."
        case .serverError(let code, let message):
            return message ?? "Server Error: \(code)"
        case .unknown:
            return "Unknown Error."
        }
    }
}
