//
//  AppleTranslationService.swift
//  Granny's
//
//  Created by AI on 18.02.2026.
//

import Foundation
import UIKit
import SwiftUI
import Translation

/// Сервис перевода рецептов через системный Translation API (iOS 17.4+)
final class AppleRecipeTranslationService {
    
    static let shared = AppleRecipeTranslationService()
    
    private init() {}
    
    /// Перевести рецепт на заданный язык. Результат кэшируется.
    func translate(
        recipe: Recipe,
        to targetLanguage: AppLanguage,
        presentingFrom presenter: UIViewController,
        completion: @escaping (Result<RecipeTranslationPayload, Error>) -> Void
    ) {
        // Проверяем кэш
        if let cached = RecipeTranslationCache.shared.loadTranslation(recipeId: recipe.id, language: targetLanguage) {
            completion(.success(cached))
            return
        }
        
        // Translation API доступен только с iOS 17.4
        guard #available(iOS 17.4, *) else {
            completion(.failure(NSError(domain: "Translation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Translation API requires iOS 17.4 or later."])))
            return
        }
        
        let sourceTextName = recipe.name
        let sourceTextInstructions = recipe.recipeInstructions ?? ""
        let sourceTextIngredients = recipe.ingredients.map { $0.displayText }.joined(separator: "\n")
        let sourceTextTags = recipe.tags.joined(separator: ", ")
        
        let configuration = TranslationSession.Configuration(
            source: .init(identifier: "en-US"),
            target: .init(identifier: targetLanguage.localeIdentifier)
        )
        
        let requests: [TranslationSession.Request] = [
            TranslationSession.Request(sourceText: sourceTextName, clientIdentifier: "name"),
            TranslationSession.Request(sourceText: sourceTextInstructions, clientIdentifier: "instructions"),
            TranslationSession.Request(sourceText: sourceTextIngredients, clientIdentifier: "ingredients"),
            TranslationSession.Request(sourceText: sourceTextTags, clientIdentifier: "tags")
        ]
        
        let workerView = TranslationWorkerView(
            configuration: configuration,
            requests: requests
        ) { responses, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let responses = responses else {
                completion(.failure(NSError(domain: "Translation", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty translation response"])))
                return
            }
            
            var translatedName = sourceTextName
            var translatedInstructions = sourceTextInstructions
            var translatedIngredients = sourceTextIngredients
            var translatedTags = sourceTextTags
            
            for response in responses {
                switch response.clientIdentifier {
                case "name":
                    translatedName = response.targetText
                case "instructions":
                    translatedInstructions = response.targetText
                case "ingredients":
                    translatedIngredients = response.targetText
                case "tags":
                    translatedTags = response.targetText
                default:
                    break
                }
            }
            
            let payload = RecipeTranslationPayload(
                languageCode: targetLanguage.rawValue,
                name: translatedName,
                instructions: translatedInstructions.isEmpty ? nil : translatedInstructions,
                ingredientsText: translatedIngredients.isEmpty ? nil : translatedIngredients,
                tags: translatedTags.isEmpty ? nil : translatedTags
            )
            
            RecipeTranslationCache.shared.saveTranslation(payload, for: recipe.id)
            completion(.success(payload))
        }
        
        let hostingController = UIHostingController(rootView: workerView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.isHidden = true
        hostingController.view.frame = .zero
        
        presenter.addChild(hostingController)
        presenter.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: presenter)
    }
}

@available(iOS 17.4, *)
private struct TranslationWorkerView: View {
    let configuration: TranslationSession.Configuration
    let requests: [TranslationSession.Request]
    let onComplete: (_ responses: [TranslationSession.Response]?, _ error: Error?) -> Void
    
    @State private var hasStarted = false
    
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(configuration) { session in
                guard !hasStarted else { return }
                hasStarted = true
                
                do {
                    let responses = try await session.translations(from: requests)
                    DispatchQueue.main.async {
                        onComplete(responses, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        onComplete(nil, error)
                    }
                }
            }
    }
}

