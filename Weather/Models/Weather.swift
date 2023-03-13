//
//  Weather.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import Foundation
import UIKit

public struct Weather: Codable, Equatable {
    public var physicalWeather: [PhysicalWeather] = []
    public var id: Int = 0
    public var name: String?
    public var temperature: Temperature?
    
    enum CodingKeys: String, CodingKey {
        case physicalWeather = "weather"
        case id = "id"
        case name = "name"
        case temperature = "main"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.physicalWeather = try container.decodeIfPresent([PhysicalWeather].self, forKey: .physicalWeather) ?? []
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.temperature = try container.decodeIfPresent(Temperature.self, forKey: .temperature)
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: Weather, rhs: Weather) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct PhysicalWeather: Codable {
    public let id: Int?
    public let main: String?
    public let description: String?
    public let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case main = "main"
        case description = "description"
        case icon = "icon"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.main = try container.decodeIfPresent(String.self, forKey: .main)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
    
    // MARK: - Helpers
    
    // ideally we could download every image and keep them locally.
    // we could also cache them each time a new image was downloaded.
    public var getImageURL: URL? {
        guard let icon = icon else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }
}

public struct Temperature: Codable {
    public let temp: Double?
    public let feelsLike: Double?
    public let tempMin: Double?
    public let tempMax: Double?
    public let pressure: Double?
    public let humidity: Double?
    
    
    enum CodingKeys: String, CodingKey {
        case temp = "temp"
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure = "pressure"
        case humidity = "humidity"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.temp = try container.decodeIfPresent(Double.self, forKey: .temp)
        self.feelsLike = try container.decodeIfPresent(Double.self, forKey: .feelsLike)
        self.tempMin = try container.decodeIfPresent(Double.self, forKey: .tempMin)
        self.tempMax = try container.decodeIfPresent(Double.self, forKey: .tempMax)
        self.pressure = try container.decodeIfPresent(Double.self, forKey: .pressure)
        self.humidity = try container.decodeIfPresent(Double.self, forKey: .humidity)
    }
    
    // MARK: - localized strings
    /// Normally I would say a weather app should support switching between units and should include localization.
    /// Since API is returning fahrenheit, we'll hardcode fahrenheit and since I don't have localization tools available, I'll display text in english.
    private let kFahrenheitSymbol: String = "°F"
    
    public var localizedTemp: String? {
        guard let temp = self.temp else { return nil }
        return "\(temp.description)\(kFahrenheitSymbol)"
    }
    
    public var localizedFeelsLike: String? {
        guard let feelsLike = self.feelsLike else { return nil }
        return "Feels like: \(feelsLike.description)\(kFahrenheitSymbol)"
    }
    
    public var localizedMinTemp: String? {
        guard let tempMin = self.tempMin else { return nil }
        return "Min: \(tempMin.description)\(kFahrenheitSymbol)"
    }
    
    public var localizedMaxTemp: String? {
        guard let tempMax = self.tempMax else { return nil }
        return "Min: \(tempMax.description)\(kFahrenheitSymbol)"
    }
    
    public var localizedHumidity: String? {
        guard let humidity = self.humidity else { return nil }
        return "Humidity: \(humidity.description)"
    }
    
    public var localizedPressure: String? {
        guard let pressure = self.pressure else { return nil }
        return "Pressure: \(pressure.description)"
    }
}
