//
//  ImageLoadOperation.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import Foundation

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
    
    override func main() {
        if isCancelled {
            finish()
            return
        }
        
        _isExecuting = true
        
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            loadedImage = cachedImage
            finish()
            return
        }
        
        guard let url = URL(string: urlString) else {
            loadError = ImageLoadError.invalidURL
            print("❌ Invalid URL: \(urlString)")
            finish()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if self.isCancelled {
                self.loadError = ImageLoadError.cancelled
                self.finish()
                return
            }
            
            if let error = error {
                self.loadError = ImageLoadError.networkError(error)
                print("❌ Network error loading image: \(error.localizedDescription)")
                self.finish()
                return
            }
            
            guard let data = data else {
                self.loadError = ImageLoadError.invalidData
                print("❌ No data received for image")
                self.finish()
                return
            }
            
            guard let image = UIImage(data: data) else {
                self.loadError = ImageLoadError.decodingFailed
                print("❌ Failed to decode image from data")
                self.finish()
                return
            }
            
            ImageCache.shared.setImage(image, for: self.urlString)
            
            self.loadedImage = image
            print("✅ Image loaded successfully")
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
        } else if isCancelled {
            completion?(.failure(ImageLoadError.cancelled))
        } else {
            completion?(.failure(ImageLoadError.invalidData))
        }
        
        completion = nil
    }
    
    override func cancel() {
        super.cancel()
        if !isFinished {
            loadError = ImageLoadError.cancelled
            print("🚫 Image load cancelled: \(urlString)")
            finish()
        }
    }
}
