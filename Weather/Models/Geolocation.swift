//
//  Geolocation.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import Foundation
import CoreLocation

public struct Geolocation: Codable, Equatable {
    public var lat: Double?
    public var lon: Double?
    public var name: String?
    
    enum CodingKeys: String, CodingKey {
        case lat = "lat"
        case lon = "lon"
        case name = "name"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decodeIfPresent(Double.self, forKey: .lat)
        self.lon = try container.decodeIfPresent(Double.self, forKey: .lon)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    /// Convert the double lat/lon to CLLocationCoordinate2D for reusability with APIServices
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lon = lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
