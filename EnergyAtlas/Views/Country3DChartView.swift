import SwiftUI
import Charts

/// A 3-axis scatter plot that shows each country as a single point in 3-D space.
/// X-axis: Electric power consumption (kWh per capita)
/// Y-axis: Energy use (kg of oil equivalent per capita)
/// Z-axis: Green-house gas emissions (Mt CO₂e)
/// Requires iOS 26 / macOS 15 / visionOS 2 SDKs with Swift Charts 3D APIs.
struct Country3DChartView: View {
    @Environment(EnergyDataStore.self) private var dataStore


    private var validCountries: [CountryEnergyModel] {
        dataStore.countries.filter { $0.powerKWh != nil && $0.energyUseKgOE != nil && $0.ghgMtCO2e != nil }
    }

    var body: some View {
        // Compute bucket mapping every time the selected metric changes
        let bucketMap = quintileBuckets(for: dataStore.selectedMetric)
        let colorScale: KeyValuePairs<String, Color> = [
            "1": .blue,
            "2": .cyan,
            "3": .white,
            "4": .orange,
            "5": .red
        ]

        return Chart3D(validCountries) { country in
            let q = bucketMap[country.countryName] ?? 3 // fallback middle bucket
            let qStr = String(q)
            
            // Get the exact color for this quintile
            let exactColor = colorScale.first(where: { $0.key == qStr })?.value ?? .white
            let isSelected = country.countryName == dataStore.selectedCountry
            
            // Apply logarithmic transformation manually if enabled
            let xValue = dataStore.logarithmicScale ? 
                log10(max(country.powerKWh! + 1, 0.1)) : country.powerKWh!
            let yValue = dataStore.logarithmicScale ? 
                log10(max(country.energyUseKgOE! + 1, 0.1)) : country.energyUseKgOE!
            let zValue = dataStore.logarithmicScale ? 
                log10(max(country.ghgMtCO2e! + 1, 0.1)) : country.ghgMtCO2e!
            
            // Update labels to reflect transformation
            let xLabel = dataStore.logarithmicScale ? "log₁₀(Power + 1)" : "Power (kWh/cap)"
            let yLabel = dataStore.logarithmicScale ? "log₁₀(Energy + 1)" : "Energy (kg OE/cap)"
            let zLabel = dataStore.logarithmicScale ? "log₁₀(GHG + 1)" : "GHG (Mt CO₂e)"
            
            PointMark(
                x: .value(xLabel, xValue),
                y: .value(yLabel, yValue),
                z: .value(zLabel, zValue)
            )
            .foregroundStyle(exactColor)
            // Shrink all symbols; enlarge slightly if selected
            .symbolSize(isSelected ? 0.02 : 0.005)
        }
        .padding()
        // Include logarithmic option in ID to trigger chart reload when it changes
        .id("\(dataStore.selectedCountry)-\(dataStore.logarithmicScale)")
    }

    // MARK: - Quintile helpers
    private func metricValue(of country: CountryEnergyModel, metric: Metric) -> Double? {
        switch metric {
        case .ghg:   return country.ghgMtCO2e
        case .power: return country.powerKWh
        case .energy: return country.energyUseKgOE
        }
    }

    private func quintileBuckets(for metric: Metric) -> [String: Int] {
        let values = validCountries.compactMap { metricValue(of: $0, metric: metric) }
        guard !values.isEmpty else { return [:] }
        
        let sorted = values.sorted()
        func threshold(_ p: Double) -> Double {
            sorted[min(Int(Double(sorted.count) * p), sorted.count - 1)]
        }
        
        let t20 = threshold(0.2)
        let t40 = threshold(0.4)
        let t60 = threshold(0.6)
        let t80 = threshold(0.8)
        
        print("Quintile thresholds for \(metric): 20% \(t20) 40% \(t40) 60% \(t60) 80% \(t80)")
        
        var map: [String: Int] = [:]
        for c in validCountries {
            guard let v = metricValue(of: c, metric: metric) else { continue }
            let q: Int
            if v <= t20 { q = 1 }
            else if v <= t40 { q = 2 }
            else if v <= t60 { q = 3 }
            else if v <= t80 { q = 4 }
            else { q = 5 }
            map[c.countryName] = q
        }
        
        var counts = Array(repeating: 0, count: 6)
        for q in map.values { counts[q] += 1 }
        print("Bucket counts (1-5):", (1...5).map { counts[$0] })
        
        return map
    }
    
}

#Preview {
    Country3DChartView()
        .environment(EnergyDataStore())
}
