import SwiftUI

/// A clean information panel that displays key country data
struct CountryInfoPanel: View {
    @Environment(EnergyDataStore.self) private var dataStore
    
    private var selectedCountryData: CountryEnergyModel? {
        dataStore.countries.first { $0.countryName == dataStore.selectedCountry }
    }
    
    private var quintile: Int {
        guard let country = selectedCountryData else { return 3 }
        let bucketMap = quintileBuckets(for: dataStore.selectedMetric)
        return bucketMap[country.countryName] ?? 3
    }
    
    private var currentValue: Double? {
        guard let country = selectedCountryData else { return nil }
        return dataStore.value(for: country.countryName, metric: dataStore.selectedMetric)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Country Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Country:", value: dataStore.selectedCountry)
                InfoRow(label: "Year:", value: String(dataStore.selectedYear))
                InfoRow(label: "Metric:", value: dataStore.selectedMetric.rawValue)
                
                if let value = currentValue {
                    InfoRow(label: "Value:", value: String(format: "%.2f", value))
                } else {
                    InfoRow(label: "Value:", value: "No data")
                }
                
                InfoRow(label: "Quintile:", value: "\(quintile) of 5", 
                       valueColor: quintileColor(quintile))
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // 3D Chart Legend
            VStack(alignment: .leading, spacing: 8) {
                Text("3D Chart Legend")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Axis explanations
                VStack(alignment: .leading, spacing: 4) {
                    let xAxis = dataStore.logarithmicScale ? "X-Axis: log₁₀(Power + 1)" : "X-Axis: Electric Power (kWh/cap)"
                    let yAxis = dataStore.logarithmicScale ? "Y-Axis: log₁₀(Energy + 1)" : "Y-Axis: Energy Use (kg OE/cap)"
                    let zAxis = dataStore.logarithmicScale ? "Z-Axis: log₁₀(GHG + 1)" : "Z-Axis: GHG Emissions (Mt CO₂e)"
                    
                    Text(xAxis)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(yAxis)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(zAxis)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Color legend
                Text("Quintile Colors:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Circle().fill(.blue).frame(width: 12, height: 12)
                        Text("1st Quintile (Lowest)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Circle().fill(.cyan).frame(width: 12, height: 12)
                        Text("2nd Quintile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Circle().fill(.white).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.gray, lineWidth: 0.5))
                        Text("3rd Quintile (Middle)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Circle().fill(.orange).frame(width: 12, height: 12)
                        Text("4th Quintile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Circle().fill(.red).frame(width: 12, height: 12)
                        Text("5th Quintile (Highest)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private func quintileColor(_ quintile: Int) -> Color {
        let colors: [Color] = [.blue, .cyan, .white, .orange, .red]
        return colors[safe: quintile - 1] ?? .white
    }
    
    // MARK: - Quintile helpers (copied from Country3DChartView)
    private func metricValue(of country: CountryEnergyModel, metric: Metric) -> Double? {
        switch metric {
        case .ghg:   return country.ghgMtCO2e
        case .power: return country.powerKWh
        case .energy: return country.energyUseKgOE
        }
    }
    
    private var validCountries: [CountryEnergyModel] {
        dataStore.countries.filter { $0.powerKWh != nil && $0.energyUseKgOE != nil && $0.ghgMtCO2e != nil }
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
        
        return map
    }
}

/// Helper view for consistent info display
struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CountryInfoPanel()
        .environment(EnergyDataStore())
        .frame(width: 300)
}
