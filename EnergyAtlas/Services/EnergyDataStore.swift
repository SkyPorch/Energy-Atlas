import Foundation
import Observation // Use the new Observation framework
import SwiftCSV // We will add this dependency later

enum Metric: String, CaseIterable, Identifiable, Hashable { // Add Hashable
    case ghg = "Greenhouse Gas Emissions (Mt CO2e)"
    case power = "Electric Power Consumption (kWh per capita)"
    case energy = "Energy Use (kg oil equivalent per capita)"

    var id: String { self.rawValue } // Conformance for Picker/ForEach
}

@Observable // Make this class observable for SwiftUI views
class EnergyDataStore {
    var countries: [CountryEnergyModel] = []
    var selectedMetric: Metric = .ghg // Default metric
    var selectedCountry: String = "United States" // Default country selection
    var selectedYear: Int = 2020 // Default year - NEW
    var availableYears: [Int] = [2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022] // NEW

    // Logarithmic scale option (applies to all axes)
    var logarithmicScale: Bool = false

    // Dictionary to store loaded centroid coordinates, keyed by country name
    var countryCoordinates: [String: (lat: Double, lon: Double)] = [:]

    init() {
        loadCentroidData() // Load centroid data first
        loadEnergyData()
    }
    
    // NEW: Method to reload data when year changes
    func reloadDataForYear(_ year: Int) {
        selectedYear = year
        loadEnergyData()
    }
    
    // NEW: Get global maximum value for a metric across ALL years
    func globalMaxValue(for metric: Metric) -> Double {
        // We need to scan the entire CSV to find the max across all years
        // This is cached after first calculation
        return cachedGlobalMaxValues[metric] ?? calculateGlobalMax(for: metric)
    }
    
    private var cachedGlobalMaxValues: [Metric: Double] = [:]
    
    private func calculateGlobalMax(for metric: Metric) -> Double {
        guard let csvUrl = Bundle.main.url(forResource: "energy_data_multi_year_filtered", withExtension: "csv") else {
            print("Error: CSV file not found for global max calculation")
            return 1.0
        }
        
        do {
            let csvFile = try CSV<Named>(url: csvUrl)
            var maxValue: Double = 0.0
            
            for row in csvFile.rows {
                let valueStr: String?
                switch metric {
                case .ghg:
                    valueStr = row[Metric.ghg.rawValue]
                case .power:
                    valueStr = row[Metric.power.rawValue]
                case .energy:
                    valueStr = row[Metric.energy.rawValue]
                }
                
                if let str = valueStr, let value = Double(str), value > maxValue {
                    maxValue = value
                }
            }
            
            // Cache the result
            cachedGlobalMaxValues[metric] = maxValue
            print("Global max for \(metric.rawValue): \(maxValue)")
            return maxValue
            
        } catch {
            print("Error calculating global max: \(error)")
            return 1.0
        }
    }

    func loadCentroidData() {
        guard let csvUrl = Bundle.main.url(forResource: "country_centroids", withExtension: "csv") else {
            print("Error: country_centroids.csv file not found in bundle.")
            return
        }

        do {
            let csvFile = try CSV<Named>(url: csvUrl)
            for row in csvFile.rows {
                guard let countryName = row["COUNTRY"], // Use the 'COUNTRY' column for the name
                      let latStr = row["latitude"],     // Use 'latitude' column
                      let lonStr = row["longitude"],   // Use 'longitude' column
                      let latitude = Double(latStr),
                      let longitude = Double(lonStr) else {
                    // print("Warning: Could not parse row in country_centroids.csv: \(row)")
                    continue
                }
                countryCoordinates[countryName] = (lat: latitude, lon: longitude)
            }
            print("Successfully loaded \(countryCoordinates.count) country centroids.")
        } catch {
            print("Error reading or parsing country_centroids.csv: \(error)")
        }
    }

    func loadEnergyData() {
        // --- IMPORTANT ---
        // 1. Add 'energy_data_multi_year_filtered.csv' to your Xcode project target.
        //    Make sure it's included in the 'Copy Bundle Resources' build phase.
        // 2. Add the SwiftCSV package: File > Add Packages... > enter URL:
        //    https://github.com/swiftcsv/SwiftCSV.git
        // ---

        guard let csvUrl = Bundle.main.url(forResource: "energy_data_multi_year_filtered", withExtension: "csv") else {
            print("Error: CSV file not found in bundle.")
            return
        }

        do {
            // Ensure SwiftCSV is added before trying to build
            let csvFile = try CSV<Named>(url: csvUrl)

            var loadedCountries: [CountryEnergyModel] = []

            for row in csvFile.rows {
                // NEW: Filter by selected year
                guard let yearStr = row["Year"],
                      let year = Int(yearStr),
                      year == selectedYear else {
                    continue // Skip rows that don't match the selected year
                }
                
                // Safely extract and convert values, defaulting to nil if missing or invalid
                let name = row["Country Name"] ?? "Unknown"
                let code = row["Country Code"] ?? ""

                // Extract values using the Metric enum rawValue as the key
                let powerStr = row[Metric.power.rawValue]
                let power = Double(powerStr ?? "")

                let energyStr = row[Metric.energy.rawValue]
                let energy = Double(energyStr ?? "")

                let ghgStr = row[Metric.ghg.rawValue]
                let ghg = Double(ghgStr ?? "")

                // --- Assign Coordinates from Centroid Data --- 
                var lat: Double? = nil
                var lon: Double? = nil
                if let coords = countryCoordinates[name] { // 'name' is from energy_data's 'Country Name'
                    lat = coords.lat
                    lon = coords.lon
                } else {
                    print("Warning: No centroid coordinates found for \(name). Marker will not be placed.")
                }

                let country = CountryEnergyModel(
                    countryName: name,
                    countryCode: code, // Make sure this column exists in your CSV
                    powerKWh: power,
                    energyUseKgOE: energy,
                    ghgMtCO2e: ghg,
                    latitude: lat,      // Assign looked-up lat
                    longitude: lon      // Assign looked-up lon
                )
                loadedCountries.append(country)
            }

            // Sort alphabetically by country name for pickers
            self.countries = loadedCountries.sorted { $0.countryName < $1.countryName }

            // Ensure default selected country exists, otherwise pick the first one
            if !self.countries.contains(where: { $0.countryName == self.selectedCountry }) {
                self.selectedCountry = self.countries.first?.countryName ?? ""
            }

            print("Successfully loaded \(self.countries.count) countries from CSV for year \(selectedYear).")

        } catch {
            print("Error reading or parsing CSV: \(error)")
        }
    }

    // --- Helper function to get data for a specific metric ---
    func value(for countryName: String, metric: Metric) -> Double? {
        guard let country = countries.first(where: { $0.countryName == countryName }) else {
            return nil
        }
        switch metric {
            case .ghg: return country.ghgMtCO2e
            case .power: return country.powerKWh
            case .energy: return country.energyUseKgOE
        }
    }

    // --- Add Helper Function for Coordinates --- 
    func coordinates(for countryName: String) -> (lat: Double, lon: Double)? {
        guard let country = countries.first(where: { $0.countryName == countryName }) else {
            return nil // Country not found
        }
        // Return coordinates only if both lat and lon exist (they should with random assignment)
        if let lat = country.latitude, let lon = country.longitude {
            return (lat: lat, lon: lon)
        } else {
            return nil // Should not happen with random assignment, but good practice
        }
    }
    // -------------------------------------------
}
