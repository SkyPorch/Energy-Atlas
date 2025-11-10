import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - MetricCarouselView
/// A Vision-optimized radial carousel that lets the user pick the currently
/// displayed energy metric (GHG, Energy, Power). Each item is represented by a
/// small 3-D model that sits on a circular track and always faces the user.
/// Tapping an item sets `EnergyDataStore.selectedMetric`.
@MainActor
struct MetricCarouselView: View {
    @Environment(EnergyDataStore.self) private var dataStore

    // Carousel rotation state
    @State private var angleOffset: Angle = .zero
    @State private var dragOffset: Angle = .zero

    // Shared model for items & selection
    @StateObject private var carouselModel = MetricCarouselModel()

    var body: some View {
        // The Canyon-Crosser sample composes a RadialLayout inside a
        // VStackLayout that is rotated by 90° over the X-axis so that the track
        // becomes horizontal. We replicate that pattern here.
        VStackLayout(spacing: 12).depthAlignment(.front) {
            // Floating label for active metric
            MetricCarouselLabelView()

            // Carousel track
            let offset = angleOffset + dragOffset
            RadialLayout(angleOffset: offset, radiusMultiplier: 1.5) {
                ForEach(Array($carouselModel.items.enumerated()), id: \.1.id) { index, $item in
                    MetricItemView(metric: item.metric)
                        .rotation3DLayout(Rotation3D(angle: .degrees(-90), axis: .x))
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                dataStore.selectedMetric = item.metric
                                centerItem(at: index)
                            }
                        }
                        .onGeometryChange3D(for: Rect3D.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { newValue in
                            item.zPosition = -newValue.origin.z
                            carouselModel.updateNormalizedZPositions()
                        }
                }
            }
            .rotation3DLayout(Rotation3D(angle: .degrees(90), axis: .x))

            // Platter
            Capsule()
                .fill(.regularMaterial)
                .frame(width: 300, height: 6)
                .opacity(0.6)
                .offset(y: 3)
        }
        .frame(width: 400, height: 400)
        .offset(y: -40) // raise
        // MARK: Drag gesture – spin the carousel left/right
        .gesture(
            DragGesture()
                .onChanged { value in
                    let deltaDegrees = -Double(value.translation.width) * 0.3
                    dragOffset = .degrees(deltaDegrees)
                }
                .onEnded { _ in
                    angleOffset += dragOffset
                    dragOffset = .zero

                    // Snap and update selection
                    let snap = carouselModel.degreeToSnapTo
                    let raw = Int(round(angleOffset.degrees / Double(snap)))
                    withAnimation(.easeInOut) {
                        angleOffset = .degrees(Double(raw * snap))
                    }
                    // Calculate front index to match the centerItem logic
                    // Since centerItem uses: angleOffset = -step * index, and raw = angleOffset / step
                    // Therefore: index = -raw
                    let adjustedRaw = -raw
                    let frontIdx = ((adjustedRaw % carouselModel.items.count) + carouselModel.items.count) % carouselModel.items.count
                    
                    dataStore.selectedMetric = carouselModel.items[frontIdx].metric
                }
        )
        // Provide model to subviews that rely on Environment
        .environmentObject(carouselModel)
    }

    // Bring the tapped item to the front (index 0). Items are spaced evenly
    // along the circle, so we rotate by –index * step.
    private func centerItem(at index: Int) {
        let step = carouselModel.degreeToSnapTo
        angleOffset = .degrees(-Double(step * index))
    }
}

// MARK: - MetricItemView
/// A single carousel item: a tiny 3-D model plus a caption.
struct MetricItemView: View {
    let metric: Metric

    var body: some View {
        VStack(spacing: 4) {
            // Tiny 3-D icon.
            Model3D(named: modelName, bundle: realityKitContentBundle)
                .frame(width: 60, height: 60)
                .scaleEffect(0.7)
        }
        // Expand tap hit-area so the items are easy to grab in the headset.
        .padding(15)
        .contentShape(Rectangle())
    }

    private var modelName: String {
        switch metric {
        case .ghg:   return "Factory"          // Factory.usda
        case .energy: return "CoolingTowers"   // CoolingTowers.usda
        case .power: return "PowerLines"       // PowerLines.usda
        }
    }

    private var shortLabel: String { "" }
}

// MARK: - MetricCarouselLabelView
struct MetricCarouselLabelView: View {
    @EnvironmentObject private var model: MetricCarouselModel

    private var text: String {
        guard let metric = model.selectedItem?.metric else { return "" }
        switch metric {
        case .ghg: return "Greenhouse Gas Emissions"
        case .power: return "Power Consumption"
        case .energy: return "Energy Use"
        }
    }

    var body: some View {
        if !text.isEmpty {
            Text(text)
                .font(.title3.weight(.semibold))
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
