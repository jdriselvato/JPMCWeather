//
//  SearchViewModel.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import CoreLocation
import Combine
import UIKit

// This would normally go to a model so it be shared in other SwiftUI v/vms
/// The display state for SwiftUI while API gets the data.
/// `fetched(T)` returns a fetched state with the fetched declared object
/// `fetching` will normally display a loading or empty state
enum DisplayState<T: Equatable>: Equatable {
    case fetched(T) // after betting set
    case fetching // initial state
}

extension SearchView {
    class ViewModel: ObservableObject {
        private let apiService: APIService // API
        private let defaults = UserDefaults.standard // user defaults
        
        @Published var weatherState: DisplayState<Weather?> = .fetching

        // pass apiService so we can pass a test APIService for unit tests
        init(apiService: APIService = APIService()) {
            self.apiService = apiService
        }
        
        // MARK: - Helpers
        
        private func cacheLast(_ location: CLLocationCoordinate2D) {
            let coordinate: [String: Double] = ["lat": location.latitude, "lon": location.longitude]
            defaults.setValue(coordinate, forKey: "locationCoordinate2D") // store last searched location in defaults
            defaults.synchronize() // sometimes defaults are slow to write. this fixes that.
        }
        
        /// fetches the weather data for a location `CLLocationCoordinate2D`
        func fetchWeatherData(for location: CLLocationCoordinate2D) {
            
            self.weatherState = .fetching // reset before new API call
            Task { @MainActor in
                do {
                    self.cacheLast(location) // store last location in user defaults
                    let weatherObject = await self.getWeather(for: location)
                    self.weatherState = .fetched(weatherObject) // complete fetching
                }
            }
        }
        
        /// fetches the weather data for location by string
        /// first it uses the api call for geolocation to get lat/lon
        /// then reuses `fetchWeatherData` to get a `weather` object
        func fetchWeatherDataForSearchedLocation(_ location: String) {
            print(location)
            Task { @MainActor in
                do {
                    let geolocationObject = await self.getGeolocation(location: location) // get geolocation
                    guard let location = geolocationObject?.coordinate else {
                        self.weatherState = .fetched(nil)
                        return
                    }
                    fetchWeatherData(for: location) // update weather object
                }
            }
        }
        
        // MARK: - API

        /// get the `Weather` object from `CLLocation` if user allows GPS
        private func getWeather(for location: CLLocationCoordinate2D) async -> Weather? {
            do {
                let weather = try await apiService.getWeather(for: location)
                return weather
            } catch {
                print("Error:", error)
                return nil
            }
        }
        
        /// returns the first `Geolocation` object from string based location
        private func getGeolocation(location: String) async -> Geolocation? {
            // zipcode search uses a different endpoint
            if let _ = Int(location), location.count == 5 { // numbers only and 5 numbers in total
                do {
                let geolocation = try await apiService.getGeolocation(zipcode: location) // zipcode
                    return geolocation
                } catch {
                    print("Error:", error)
                    return nil
                }
            } else { // normal search by city, country code
                do {
                    let geolocation = try await apiService.getGeolocation(location: location) // city, country code
                    return geolocation.first
                } catch {
                    print("Error:", error)
                    return nil
                }
            }
        }
    }
}
