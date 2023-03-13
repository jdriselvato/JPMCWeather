//
//  APIService.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import Foundation
import CoreLocation

/// All supported Endpoints
enum Endpoint: String {
    case weather = "https://api.openweathermap.org/data/2.5/weather"
    case geolocation = "https://api.openweathermap.org/geo/1.0/direct"
    case geolocationZipcode = "https://api.openweathermap.org/geo/1.0/zip"
}

typealias DataResponse = (data: Data, response: URLResponse) // helper tuple

// A protocol list of supported API calls
public protocol APIServiceProtocol {
    func getWeather(for location: CLLocationCoordinate2D) async throws -> Weather
    func getGeolocation(location: String ) async throws -> [Geolocation]
    func getGeolocation(zipcode: String ) async throws -> Geolocation
}

class APIService: APIServiceProtocol {
    private let API_KEY = "d5c15ecb843b621f116764debccd1f79" // openweathermap API key
    
    /// Makes the url request and returns the raw data and URLResponse
    /// `endpoint`: the end point for the specific call
    /// `queryParameters`:the query parameters ie ?lat=44.34&lon=10.99
    private func makeRequest(_ endpoint: Endpoint, queryParameters: [String: String]) async throws -> DataResponse {
        guard let url = URL(string: endpoint.rawValue) else { fatalError("Missing endpoint") }
        
        let actualURL: URL // the final url
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true) // for queryParameters
        
        // build the queryParameters as an array of URLQueryItem to create the final url
        var queryParameters = queryParameters
        queryParameters["appid"] = "d5c15ecb843b621f116764debccd1f79" // makeRequest handles the appid not the api calls
        components?.queryItems = queryParameters.map({ (key, value) in URLQueryItem(name: key, value: value)})
        
        // the final url including queryParameters
        actualURL = components?.url ?? url // I suppose we should throw bad `DataResponse` if component?.url is nil instead of fallback to the original url
        
        // make url request and return data and response
        let urlRequest = URLRequest(url: actualURL)
        let dataResponse: DataResponse = try await URLSession.shared.data(for: urlRequest)
        return dataResponse
    }
    
    /// Returns a failure with `Error` or a success result with the decoded `T.Type` from `DataResponse`
    private func build<T: Decodable>(type: T.Type, dataResponse: DataResponse) -> Result<T, Error> {
        do {
            let decoded = try JSONDecoder().decode(T.self, from: dataResponse.data) // decode data with type
            return .success(decoded)
        } catch { // failure create an error message
            let statusCode = (dataResponse.response as? HTTPURLResponse)?.statusCode ?? 0
            let error = NSError(
                domain: "Fetching data error \(dataResponse.response.debugDescription)",
                code: statusCode,
                userInfo: nil
            )
            return .failure(error)
        }
    }
    
    /// Returns the `Weather` object for a specified location by `CLLocationCoordinate2D`
    /// API call example: https://api.openweathermap.org/data/2.5/weather?lat=44.34&lon=10.99&appid=d5c15ecb843b621f116764debccd1f79
    func getWeather(for location: CLLocationCoordinate2D) async throws -> Weather {
        let queryParameters: [String: String] = [
            "lat": location.latitude.description,
            "lon": location.longitude.description,
            "units": "imperial" // no point in doing client side math
        ]
        let dataResponse = try await self.makeRequest(.weather, queryParameters: queryParameters)
        let weather = self.build(type: Weather.self, dataResponse: dataResponse)
        return try weather.get()
    }
    
    /// Returns array `Geolocation` object for a specified string location
    /// Api returns an array because Geolocation by city name may return multiple results
    func getGeolocation(location: String ) async throws -> [Geolocation] {
        let queryParameters: [String: String] = [
            "q": location
        ]
        let dataResponse = try await self.makeRequest(.geolocation, queryParameters: queryParameters)
        let geolocation = self.build(type: [Geolocation].self, dataResponse: dataResponse)
        return try geolocation.get()
    }
    
    /// Returns `Geolocation` object if search is a zip code
    func getGeolocation(zipcode: String ) async throws -> Geolocation {
        let queryParameters: [String: String] = [
            "zip": zipcode
        ]
        let dataResponse = try await self.makeRequest(.geolocationZipcode, queryParameters: queryParameters)
        let geolocation = self.build(type: Geolocation.self, dataResponse: dataResponse)
        return try geolocation.get()
    }
}

