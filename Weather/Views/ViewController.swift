//
//  ViewController.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import Foundation
import UIKit
import SwiftUI
import CoreLocation

class ViewController: UIViewController {
    private weak var hostingVC: UIHostingController<SearchView>? // SwiftUI wrapper for UIKit
    private let locationManager = CLLocationManager() // location manager
    private let defaults = UserDefaults.standard // user defaults

    // I rather not program UI with xibs or programatic autolayout but the requirement said to use UIKit and bonus if mixed with SwiftUI, so here's the mixture.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        // build SwiftUI wrapper to display in the navigation controller
        let viewController = UIHostingController(
            rootView: SearchView(
                viewModel: SearchView.ViewModel()
            )
        )
        self.navigationController?.setViewControllers([viewController], animated: false)
        self.hostingVC = viewController
        
        // use user default or hard coded location depending on permissions
        self.setupDefaultLocation()
        
        // request user location & update location if permissions are allowed
        self.setupLocationManager()
    }
    
    /// setup the default location.
    /// if no search has been completed a hard coded location (san francisco) is used.
    /// if search has been completed once, we use the location stored in user defaults
    private func setupDefaultLocation() {
        // check if previously saved location is in user defaults and search by this location
        if let coordinates = defaults.object(forKey:"locationCoordinate2D") as? Dictionary<String, Double> {
            guard let lat = coordinates["lat"], let lon = coordinates["lon"] else { return }
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.hostingVC?.rootView.viewModel.fetchWeatherData(for: location)
        } else { // no user defaults value
            // permissions denied, default to a hard coded location until search
            let location = CLLocationCoordinate2D(latitude: 37.774929, longitude: -122.419418)
            self.hostingVC?.rootView.viewModel.fetchWeatherData(for: location)
        }
    }
}

// MARK: - Location manager

// Normally I would have built a reusable Location Manager but since the ViewController wasn't doing anything but initializing the SwiftUI view, I figured it would be more time effient to build it in here.

extension ViewController: CLLocationManagerDelegate {
    
    /// Start the location manager (SDK states on the main thread)
    private func startLocationManager() {
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestLocation() // we only request it once per session since we don't want gps conflicting with search
        }
    }
    
    /// setup the location manager
    /// - ask permissions for location access
    /// - start tracking gps if permissions are approved
    private func setupLocationManager() {
        // Setup location manager
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        
        // request permissions
        self.promptForLocationPermission()
        // start tracking GPS
        self.startLocationManager()
    }
    
    /// Give the user the prompt for permissions to use GPS tracking
    private func promptForLocationPermission() {
        switch self.locationManager.authorizationStatus {
        case .notDetermined, .restricted:
            self.locationManager.requestWhenInUseAuthorization() // normal permission
            self.startLocationManager()
        case .denied:
            self.setupDefaultLocation()
        default:
            return
        }
    }
    
    /// Called when location has updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.hostingVC?.rootView.viewModel.fetchWeatherData(for: location) // update to GPS location
    }
    
    /// Called when auth has changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.startLocationManager() // start manager over to check permission and request again if needed
    }
    
    /// Called when location manager fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationManager.stopUpdatingLocation()
    }
}
