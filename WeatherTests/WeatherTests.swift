//
//  WeatherTests.swift
//  WeatherTests
//
//  Created by John Riselvato on 3/10/23.
//

import XCTest
import Combine
import CoreLocation
@testable import Weather

final class WeatherTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    private func buildViewModel() -> SearchView.ViewModel {
        return SearchView.ViewModel(apiService: TestAPIService())
    }
    
    // MARK: - Weather API tests
    /// Normally I would test for all correct displayable strings or values but I think this gets the point across
    
    /// checks for correct location name based on weather fixture
    func testReturnsCorrecLocationName() throws {
        let viewModel = self.buildViewModel()
        let expectation = XCTestExpectation(description: "Get weather data")

        viewModel.fetchWeatherData(for: CLLocationCoordinate2D(latitude: 35.7804, longitude: -78.6391))
        
        let expected = "Wake"
        var actual: String?
        
        viewModel.$weatherState.dropFirst().sink { state in
            var weather: Weather? { // upcoming bookings unwrapped
                guard case let .fetched(unwrapped) = state else { return nil }
                return unwrapped
            }
            actual = weather?.name
            expectation.fulfill()
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(actual == expected, "Expected \(expected), but got \(actual ?? "nil")")
    }
    
    /// checks for correct location name based on weather fixture
    func testReturnsCorrecTemperatureString() throws {
        let viewModel = self.buildViewModel()
        let expectation = XCTestExpectation(description: "Get weather data")

        viewModel.fetchWeatherData(for: CLLocationCoordinate2D(latitude: 35.7804, longitude: -78.6391))
        
        let expected = "281.13°F"
        var actual: String?
        
        viewModel.$weatherState.dropFirst().sink { state in
            var weather: Weather? { // upcoming bookings unwrapped
                guard case let .fetched(unwrapped) = state else { return nil }
                return unwrapped
            }
            actual = weather?.temperature?.localizedTemp
            expectation.fulfill()
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(actual == expected, "Expected \(expected), but got \(actual ?? "nil")")
    }
    
    // MARK: - Geolocation API Test
    
    /// Since the geolocation object is only used to get the lat/lon and it's passed to `fetchWeatherData` the test here is to ensure the flow from city to final weather is working.
    func testReturnsCorrectNameByCitySearch() throws {
        let viewModel = self.buildViewModel()
        let expectation = XCTestExpectation(description: "Get geolocation data")
        
        let city = "Raleigh"
        viewModel.fetchWeatherDataForSearchedLocation(city)
        
        let expected = "Wake"
        var actual: String?
        
        viewModel.$weatherState.dropFirst(2).sink { state in // because `fetchWeatherData` resets to .fetching skip this sink
            var weather: Weather? { // upcoming bookings unwrapped
                guard case let .fetched(unwrapped) = state else { return nil }
                return unwrapped
            }
            actual = weather?.name
            expectation.fulfill()
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(actual == expected, "Expected \(expected), but got \(actual ?? "nil")")
    }
    
    // We could also write tests for zipcode api but this sufficient
    // Also if this app was more complex, the viewModel would do more heavy lifting on text displayed on the view.
    // I prefer to test open viewModel variables over the entire weather displayState object
    // but the app is too simplistic to extract the code like that.
}

// MARK: - Test API

private class Fixture {}

private class TestAPIService: APIService {
    let bundle = Bundle(for: Fixture.self)
    
    /// Override the `getWeather` api call with our local `weather.json`
    override func getWeather(for location: CLLocationCoordinate2D) async throws -> Weather {
        guard
            let url = self.getFixtureUrl(for: "weather"),
            let data = self.getData(for: url)
        else {
            let error = NSError(domain: "Unable to load data from fixture url", code: 0)
            assertionFailure(error.description)
            throw error
        }
        
        do {
            let weather = try JSONDecoder().decode(Weather.self, from: data)
            return weather
        } catch {
            let error = NSError(domain: "Unable to decode JSON", code: 0)
            assertionFailure(error.description)
            throw error
        }
    }
    
    /// Override the `getGeolocation` api call with our local `geolocation.json`
    override func getGeolocation(location: String ) async throws -> [Geolocation] {
        guard
            let url = self.getFixtureUrl(for: "geolocation"),
            let data = self.getData(for: url)
        else {
            let error = NSError(domain: "Unable to load data from fixture url", code: 0)
            assertionFailure(error.description)
            throw error
        }
        
        do {
            let geolocation = try JSONDecoder().decode([Geolocation].self, from: data)
            return geolocation
        } catch {
            let error = NSError(domain: "Unable to decode JSON", code: 0)
            assertionFailure(error.description)
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func getFixtureUrl(for fixture: String) -> URL? {
        guard let fileUrl = bundle.url(forResource: fixture, withExtension: "json") else {
            assertionFailure("Unable to find fixture named \(fixture).json")
            return nil
        }
        return fileUrl
    }
    
    private func getData(for url: URL) -> Data? {
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
}
