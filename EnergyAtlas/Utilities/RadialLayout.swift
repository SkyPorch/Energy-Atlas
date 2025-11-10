import SwiftUI

/*
 A custom `Layout` that arranges its subviews evenly on a circle. This is the
 exact implementation Apple ships in the Canyon Crosser sample — reproduced
 here so the carousel matches the sample’s behaviour and animatability.
*/
struct RadialLayout: Layout, Animatable {
    /// Additional rotation applied to the whole circle (in the XY plane).
    var angleOffset: Angle = .zero
    /// Multiplier applied to the default placement radius (1.0 == original sample).
    /// Use >1 to spread items farther apart, <1 to tighten.
    var radiusMultiplier: CGFloat = 1.0

    // MARK: - Layout protocol
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let updatedProposal = proposal.replacingUnspecifiedDimensions()
        let minDim = min(updatedProposal.width, updatedProposal.height)
        return CGSize(width: minDim, height: minDim)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        // If there’s only one subview, just center it.
        guard subviews.count > 1 else {
            subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: proposal)
            return
        }

        let minDimension = min(bounds.width, bounds.height)
        let subViewDim = minDimension / CGFloat((subviews.count / 2) + 1)
        let radius = minDimension / 2
        var placementRadius = radius - (subViewDim / 2)
        placementRadius *= radiusMultiplier
        // Clamp so items don’t leave the layout’s bounds.
        placementRadius = min(placementRadius, radius - (subViewDim / 2))
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let angleIncrement = 2 * .pi / CGFloat(subviews.count)
        let centerOffset = Double.pi / 2 // Makes item 0 point straight ahead.

        for (index, subview) in subviews.enumerated() {
            let angle = angleIncrement * CGFloat(index) + angleOffset.radians + centerOffset
            let xPosition = center.x + (placementRadius * cos(angle))
            let yPosition = center.y + (placementRadius * sin(angle))
            let point = CGPoint(x: xPosition, y: yPosition)
            subview.place(at: point,
                          anchor: .center,
                          proposal: .init(width: subViewDim, height: subViewDim))
        }
    }

    // MARK: - Animatable
    var animatableData: Angle.AnimatableData {
        get { angleOffset.animatableData }
        set { angleOffset.animatableData = newValue }
    }
}
