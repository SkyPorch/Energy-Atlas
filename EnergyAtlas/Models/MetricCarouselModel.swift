import SwiftUI

// MARK: - MetricCarouselItem
struct MetricCarouselItem: Identifiable, Hashable {
    let id = UUID()
    let metric: Metric
    var zPosition: Double = 0 // Will be updated via GeometryChange3D
}

// MARK: - MetricCarouselModel
final class MetricCarouselModel: ObservableObject {
    // All items displayed in the carousel (in order).
    @Published var items: [MetricCarouselItem] = [] {
        didSet { updateNormalizedZPositions() }
    }

    // The z-positions normalised to 0.3…1.3 (used for opacity).
    @Published var normalizedZPosition: [Double] = []

    // Front-most item
    var selectedItem: MetricCarouselItem? {
        items.min(by: { $0.zPosition < $1.zPosition })
    }

    // Snapping helpers
    let degreeToSnapTo: Int
    let cutoffAngle: Int

    init() {
        let metrics = Metric.allCases
        let initialItems = metrics.map { MetricCarouselItem(metric: $0) }
        self.items = initialItems
        self.degreeToSnapTo = Int(360.0 / Double(initialItems.count))
        self.cutoffAngle = self.degreeToSnapTo / 2
        updateNormalizedZPositions()
    }

    // Re-calculate normalised z-positions whenever an item’s z changes.
    func updateNormalizedZPositions() {
        guard
            let minItem = items.min(by: { $0.zPosition < $1.zPosition }),
            let maxItem = items.max(by: { $0.zPosition < $1.zPosition })
        else {
            normalizedZPosition = []
            return
        }

        // Avoid 0 so rear items never become fully transparent.
        let minimumValue = 0.3
        normalizedZPosition = items.map {
            (($0.zPosition - minItem.zPosition) / (maxItem.zPosition - minItem.zPosition)) + minimumValue
        }
    }
}
