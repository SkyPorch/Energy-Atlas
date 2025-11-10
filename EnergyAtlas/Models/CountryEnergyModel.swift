import Foundation

struct CountryEnergyModel: Identifiable, Hashable {
    let id = UUID() // Unique identifier for SwiftUI lists/charts
    let countryName: String
    let countryCode: String // Assuming your CSV has a country code column

    // Energy Data (using Double for calculations, handle potential nil/NaN)
    let powerKWh: Double?         // Electric Power Consumption (kWh per capita)
    let energyUseKgOE: Double?    // Energy Use (kg of oil equivalent per capita)
    let ghgMtCO2e: Double?        // Greenhouse Gas Emissions (Mt CO2e)

    // Add placeholder coordinates
    let latitude: Double?
    let longitude: Double?

    // Basic initializer
    init(countryName: String, countryCode: String, powerKWh: Double? = nil, energyUseKgOE: Double? = nil, ghgMtCO2e: Double? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.countryName = countryName
        self.countryCode = countryCode
        self.powerKWh = powerKWh
        self.energyUseKgOE = energyUseKgOE
        self.ghgMtCO2e = ghgMtCO2e
        // Assign coordinates
        self.latitude = latitude
        self.longitude = longitude
    }
}
