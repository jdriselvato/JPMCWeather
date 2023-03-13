//
//  SearchView.swift
//  Weather
//
//  Created by John Riselvato on 3/10/23.
//

import SwiftUI

struct SearchView: View {
    
    @ObservedObject var viewModel: ViewModel
    @State private var location: String = ""
    
    var body: some View {
        VStack {
            searchView() // keep the search view visible even while fetching results
            // display view state depending on results
            switch viewModel.weatherState {
            case .fetched(let weather):
                if let weather = weather { // if api was successful
                    ScrollView {
                        locationTitle(weather)
                        temperatureView(weather)
                        physicalWeatherView(weather)
                    }
                } else { // if api was not successful
                    Text("No data for this location") // ideally all strings would be in a strings file for localization
                }
                Spacer()
            case .fetching: // while fetching data
                Spacer()
                ProgressView()
                Text("Loading...")
                Spacer()
            }
            Spacer()
        }
        .navigationBarHidden(true) // hide navigation
        .navigationTitle("") // recommended addition to hide nav w/ swiftUI
        .onTapGesture { // dismiss keyboard on tap
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Search views
    
    /// displays a search bar and search button
    private func searchView() -> some View {
        HStack {
            TextField("Location", text: $location)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 2.0)
                        .stroke(Color.gray, lineWidth: 1.0)
                )
            Button("Search") {
                self.viewModel.fetchWeatherDataForSearchedLocation(self.location)
            }
        }
        .padding()
    }
    
    // MARK: - Results views & Weather image
    
    /// displays the current location based on `name`
    private func locationTitle(_ weather: Weather) -> some View {
        VStack {
            if let name = weather.name {
                Text(name)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
    
    /// displays various temperature, humidiy and pressure info
    private func temperatureView(_ weather: Weather) -> some View {
        VStack(spacing: 16.0) {
            Text(weather.temperature?.localizedTemp ?? "") // large temp
                .font(.system(size: 64.0))
            HStack {
                Text(weather.temperature?.localizedFeelsLike ?? "") // feels like
            }
            HStack {
                Text(weather.temperature?.localizedMinTemp ?? "") // min temp
                Text(weather.temperature?.localizedMaxTemp ?? "") // max temp
            }
            HStack {
                Text(weather.temperature?.localizedHumidity ?? "") // humidity
                Text(weather.temperature?.localizedPressure ?? "") // pressure
            }
        }
        .padding()
    }
    
    // displays the weathers icon and the main physical name of the condition as well as the description
    private func physicalWeatherView(_ weather: Weather) -> some View {
        HStack {
            AsyncImage(url: weather.physicalWeather.first?.getImageURL) { phase in
                switch phase {
                case .failure:
                    Image(systemName: "photo") // defaults system photo
                        .font(.largeTitle)
                case .success(let image):
                    image
                        .resizable()
                default:
                    ProgressView() // show loader
                }
                
            }
            .frame(width: 100, height: 100) // seems api gives us small images but sett his to make it visible
            VStack(alignment: .leading) {
                Text(weather.physicalWeather.first?.main ?? "") // condition
                if let description = weather.physicalWeather.first?.description { // description
                    Text("Description: \(description)")
                }
            }
        }
        .padding()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(viewModel: SearchView.ViewModel())
    }
}
