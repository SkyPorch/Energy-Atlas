import SwiftUI
import RealityKit

struct GlobeView: View {
    // Access the shared data store
    @Environment(EnergyDataStore.self) var dataStore
    @Environment(AppModel.self) var appModel
    @Environment(AssetPreloader.self) var assetPreloader
    @Environment(\.realityKitScene) private var scene
        
    // Store the GlobeEntity instance to interact with it
    @State private var globeEntity: GlobeEntity?
    // For spin gesture
    @State private var initialRotation: simd_quatf? = nil

    var body: some View {
        // Track these specific properties to trigger RealityView updates
        let selectedMetric = dataStore.selectedMetric
        let selectedCountry = dataStore.selectedCountry
        let selectedYear = dataStore.selectedYear // NEW: Track year changes
        
        RealityView { content in
            // Create GlobeEntity with AssetPreloader
            let entity = GlobeEntity(assetPreloader: assetPreloader)
            globeEntity = entity
            
            // --- Set GlobeEntity's initial position --- 
            entity.position = [0, 1, -2.0] // x, y, z (1.5m in front)
            // ------------------------------------------
            
            // Add the GlobeEntity to the RealityView's content
            content.add(entity)
            
            // Wait for globe to be ready before running visualization
            Task { @MainActor in
                // Wait for globe model to be ready
                while entity.globeModel == nil {
                    try? await Task.sleep(nanoseconds: 100_000_000) // Wait 0.1 seconds
                }
                
                print("GlobeEntity is ready, running initial setup")
                
                // --- Initial Data Visualization --- 
                entity.updateVisualization(metric: selectedMetric, dataStore: dataStore)
                entity.updateFloatingLabel(metric: selectedMetric, country: selectedCountry, year: selectedYear)
                // ----------------------------------
                // Place initial asset based on selected metric
                if dataStore.coordinates(for: selectedCountry) != nil {
                    // Asset placement removed per user request
                    entity.hideFactory()
                }
                
                // --- Initial Spin to selected country ---
                if let coords = dataStore.coordinates(for: selectedCountry) {
                    print("Initial spin to \(selectedCountry) at \(coords)")
                    entity.spinTo(latitude: coords.lat, longitude: coords.lon, duration: 0) // Spin instantly on appear
                } else {
                    print("Initial spin to lat 0, lon 0 (fallback)")
                    entity.spinTo(latitude: 0, longitude: 0, duration: 0) // Fallback to equator
                }
                // --------------------
            }
             
        } update: { content in
            // This closure is called when SwiftUI state changes that the RealityView depends on.
            // We can use this to trigger updates on the GlobeEntity.
            print("RealityView update triggered. Selected Metric: \(selectedMetric), Selected Country: \(selectedCountry)")
            
            guard let entity = globeEntity else { return }
            
            // Only update if globe model is ready
            guard entity.globeModel != nil else {
                print("Globe model not ready yet, skipping update")
                return
            }
            
            // --- Update Data Visualization on Metric Change --- 
            entity.updateVisualization(metric: selectedMetric, dataStore: dataStore)
            entity.updateFloatingLabel(metric: selectedMetric, country: selectedCountry, year: selectedYear)
            // --------------------------------------------------
            
            // --- Spin & Factory placement on Country Change --- 
            if let coords = dataStore.coordinates(for: selectedCountry) {
                print("Updating spin & asset to: \(selectedCountry) at \(coords)")
                entity.spinTo(latitude: coords.lat, longitude: coords.lon) // Animate
                Task { @MainActor in
                    // Asset placement removed per user request
                    entity.hideFactory()
                }
            } else {
                // No coordinates – hide any existing factory
                Task { @MainActor in
                    entity.hideFactory()
                }
            }
            // ------------------------------
        }
        // Apply both spin gesture and pin tap gesture to the RealityView
        .gesture(spinGesture)
        .gesture(pinTapGesture)
        // Handle music mute/unmute changes
        .onChange(of: appModel.isMusicMuted) { oldValue, newValue in
            guard let entity = globeEntity else { return }
            if newValue {
                entity.muteAmbientAudio()
            } else {
                entity.unmuteAmbientAudio()
            }
        }
        .onAppear {
            print("GlobeView appeared, setting appModel.immersiveSpaceState to .open")
            appModel.immersiveSpaceState = .open
        }
        .onDisappear {
            print("GlobeView disappeared, setting appModel.immersiveSpaceState to .closed")
            appModel.immersiveSpaceState = .closed
        }
    }
    
    // MARK: - Pin Glow Animation (Space Turret Pattern)
    func triggerPinGlowAnimation(for selectedCountry: String) {
        guard let currentScene = scene else { return }
        print("🔆 Triggering pin glow for: \(selectedCountry)")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("RealityKit.NotificationTrigger"),
            object: nil,
            userInfo: [
                "RealityKit.NotificationTrigger.Scene": currentScene,
                "RealityKit.NotificationTrigger.Identifier": "IsSelected"
            ]
        )
    }
}

// MARK: - Spin Gesture
extension GlobeView {
    var spinGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                // Only allow globe rotation, not pin manipulation
                guard !isPinEntity(value.entity) else { return }
                
                // Always rotate the globeModel (which contains the pins) regardless of which entity was touched
                guard let entity = globeEntity, let globeModel = entity.globeModel else { return }
                
                // Capture initial rotation once at the start of the drag
                if initialRotation == nil {
                    initialRotation = globeModel.transform.rotation
                }
                // Use horizontal & vertical drag distance to create yaw & pitch
                let delta2D = value.gestureValue.translation
                let yaw   = Float(delta2D.width)  * 0.001 // lower sensitivity
                let pitch = Float(delta2D.height) * 0.001
                let yawQuat   = simd_quatf(angle: yaw,   axis: SIMD3(0, 1, 0))
                let pitchQuat = simd_quatf(angle: pitch, axis: SIMD3(1, 0, 0))
                globeModel.transform.rotation = yawQuat * pitchQuat * (initialRotation ?? simd_quatf())
            }
            .onEnded { _ in
                initialRotation = nil
            }
    }
    
    var pinTapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                let entity = value.entity
                
                // Check if tapped entity is a pin or part of a pin
                if let countryName = findPinCountryName(from: entity) {
                    dataStore.selectedCountry = countryName
                }
            }
    }
    
    // Helper function to determine if an entity is a pin
    private func isPinEntity(_ entity: Entity) -> Bool {
        return findPinCountryName(from: entity) != nil
    }
    
    // Helper function to find the country name associated with a pin entity
    private func findPinCountryName(from entity: Entity) -> String? {
        // Search through the globe entity's country pins to find a match
        guard let globeEntity = globeEntity else { return nil }
        for (countryName, pinEntity) in globeEntity.countryPins {
            if entity == pinEntity || isChildOfPin(entity: entity, pin: pinEntity) {
                return countryName
            }
        }
        return nil
    }
    
    // Helper function to check if entity is a child of a pin
    private func isChildOfPin(entity: Entity, pin: Entity) -> Bool {
        var current: Entity? = entity
        while let parent = current?.parent {
            if parent == pin {
                return true
            }
            current = parent
        }
        return false
    }

}

#Preview {
    GlobeView()
        .environment(EnergyDataStore()) // Provide dummy store for preview
}
