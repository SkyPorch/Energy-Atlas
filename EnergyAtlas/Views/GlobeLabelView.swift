import SwiftUI
import RealityKit

/// Small floating label that shows the current country, metric, and year.
/// This view is rendered as a SwiftUI attachment in the scene so it automatically
/// tracks the globe entity.
struct GlobeLabelView: View {
    let metric: Metric
    let country: String
    let year: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Country: \(country)")
            Text("Year: \(year, format: .number.grouping(.never))")
            Text("Parameter: \(metric.rawValue)")
        }
        .font(.system(size: 40, weight: .bold))
        .foregroundStyle(.primary)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
