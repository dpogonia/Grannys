//
//  AreaCountryMapper.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 11.02.2026.
//

// ДЗ MOYA: Утилиты для маппинга областей TheMealDB к кодам стран

import Foundation

// MARK: - Area Models

// Простая структура для области с флагом
public struct AreaWithFlag {
    public let name: String
    public let flagEmoji: String
    
    public init(area: String) {
        self.name = area
        self.flagEmoji = AreaCountryMapper.getFlagEmoji(for: area)
    }
}

// MARK: - Area to Country Mapping

// Маппинг областей TheMealDB к кодам стран для отображения флагов
public struct AreaCountryMapper {
    
    // Маппинг названий областей TheMealDB к ISO кодам стран (для флагов)
    public static let areaToCountryCode: [String: String] = [
        "American": "US",
        "British": "GB",
        "Canadian": "CA",
        "Chinese": "CN",
        "Croatian": "HR",
        "Dutch": "NL",
        "Egyptian": "EG",
        "Filipino": "PH",
        "French": "FR",
        "Greek": "GR",
        "Indian": "IN",
        "Irish": "IE",
        "Italian": "IT",
        "Jamaican": "JM",
        "Japanese": "JP",
        "Kenyan": "KE",
        "Malaysian": "MY",
        "Mexican": "MX",
        "Moroccan": "MA",
        "Polish": "PL",
        "Portuguese": "PT",
        "Russian": "RU",
        "Spanish": "ES",
        "Thai": "TH",
        "Tunisian": "TN",
        "Turkish": "TR",
        "Ukrainian": "UA",
        "Vietnamese": "VN",
        "Algerian": "DZ",
        "Argentinian": "AR",
        "Australian": "AU",
        "Norwegian": "NO",
        "Saudi": "SA",
        "Slovakian": "SK",
        "Syrian": "SY",
        "Uruguayan": "UY",
        "Venezuelan": "VE"
    ]
    
    // Получить emoji флаг для области
    // Название области (например, "Italian", "French")
    public static func getFlagEmoji(for area: String) -> String {
        guard let countryCode = areaToCountryCode[area] else {
            return "🌍"
        }
        
        // Конвертация ISO кода в emoji флаг
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalarValue))
            }
        }
        return emoji.isEmpty ? "🌍" : emoji
    }
}
