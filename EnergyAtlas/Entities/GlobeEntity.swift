import RealityKit
import SwiftUI // Needed for Color
import RealityKitContent



class GlobeEntity: Entity {
    
    // Keep a reference to the loaded model - made public for gesture access
    var globeModel: Entity?
    
    // Cache the factory and power lines prototypes (loaded once)
    private var factoryPrototype: Entity?
    private var powerLinesPrototype: Entity?
    private var coolingTowersPrototype: Entity?
    // Cache the pin prototype (loaded once)
    private var pinPrototype: Entity?
    // The currently displayed asset instance (factory or power lines)
    private var currentFactory: Entity?
    
    // Floating label entity shown above the globe
    private var labelEntity: Entity?
    
    // Map country identifier -> pin entity, so we can animate rather than recreate - made public for gesture access
    var countryPins: [String: Entity] = [:]
    
    // Notification for pin glow trigger
    static let pinGlowNotification = Notification.Name("pinGlowNotification")
    
    // Reference to asset preloader for using preloaded assets
    private var assetPreloader: AssetPreloader?

    
    // Updated initializer to accept AssetPreloader
    @MainActor init(assetPreloader: AssetPreloader) {
        super.init()
        self.assetPreloader = assetPreloader
        // Setup synchronously if assets are preloaded
        if setupGlobeSync() {
            // Successfully setup with preloaded assets, no need for async setup
            print("GlobeEntity: Synchronously setup with preloaded assets")
        } else {
            // Fallback to async setup
            Task {
                await setupGlobe()
            }
        }
    }
    
    // Keep the old init for compatibility, but it will use independent loading
    @MainActor required init() {
        super.init()
        // Call async setup within a Task from the sync initializer
        Task {
            await setupGlobe()
        }
    }
    
    // MARK: - Factory Placement API
    /// Places a small Factory model on the globe at the given latitude/longitude.
    /// If a factory is already shown it is removed first.
    @MainActor
    func showFactory(latitude: Double, longitude: Double) async {
        // Load the prototype once
        if factoryPrototype == nil {
            do {
                factoryPrototype = try await Entity(named: "Factory.usda", in: RealityKitContent.realityKitContentBundle)
            } catch {
                print("GlobeEntity: Failed to load Factory.usda – \(error)")
                return
            }
        }
        guard let prototype = factoryPrototype,
              let globeModel = globeModel,
              let surfacePos = positionOnGlobe(latitude: latitude, longitude: longitude) else { return }
        // If an old FactoryEntity exists, stop its listeners
        if let oldFactory = currentFactory as? FactoryEntity {
            oldFactory.stopListening()
        }
        // Remove previous instance
        currentFactory?.removeFromParent()
        // Create a fresh FactoryEntity that manages its own smoke logic
        let factory = FactoryEntity(cloning: prototype)
        
        // Align factory's Y+ axis with the outward normal from globe center
        let outward = simd_normalize(surfacePos)
        let upAxis   = SIMD3<Float>(0, 1, 0)
        let rotation = simd_quatf(from: upAxis, to: outward)
        factory.orientation = rotation
        
        // Place the base exactly on the surface, with a small outward offset to avoid z-fighting
        let outwardOffset: Float = 0.002 // 2 cm
        factory.position = surfacePos + outward * outwardOffset
        
        // Optional: scale down if the model is large
        factory.scale = [0.1, 0.1, 0.1]
        globeModel.addChild(factory)
        currentFactory = factory
        
        // Start listening for timeline notifications now that it's in the scene
        factory.startListeningForSmokeNotifications()
    }
    
    /// Places a PowerLines model on the globe at the given latitude/longitude.
    /// If another asset is already shown it is removed first.
    @MainActor
    func showPowerLines(latitude: Double, longitude: Double) async {
        // Load the prototype once
        if powerLinesPrototype == nil {
            do {
                powerLinesPrototype = try await Entity(named: "PowerLines.usda", in: RealityKitContent.realityKitContentBundle)
            } catch {
                print("GlobeEntity: Failed to load PowerLines.usda – \(error)")
                return
            }
        }
        guard let prototype = powerLinesPrototype,
              let globeModel = globeModel,
              let surfacePos = positionOnGlobe(latitude: latitude, longitude: longitude) else { return }

        // Stop smoke listeners if current asset is a factory
        if let oldFactory = currentFactory as? FactoryEntity {
            oldFactory.stopListening()
        }
        // Remove previous instance (factory or power lines)
        currentFactory?.removeFromParent()

        // Clone and orient
        let powerLines = prototype.clone(recursive: true)
        let outward = simd_normalize(surfacePos)
        let upAxis   = SIMD3<Float>(0, 1, 0)
        let rotation = simd_quatf(from: upAxis, to: outward)
        powerLines.orientation = rotation

        // Slightly offset outward to avoid z-fighting
        let outwardOffset: Float = 0.002
        powerLines.position = surfacePos + outward * outwardOffset

        // Scale if needed (tweak as required for your asset)
        powerLines.scale = [0.1, 0.1, 0.1]

        globeModel.addChild(powerLines)
        currentFactory = powerLines
    }

    @MainActor
    func showCoolingTowers(latitude: Double, longitude: Double) async {
        // Load the prototype once
        if coolingTowersPrototype == nil {
            do {
                coolingTowersPrototype = try await Entity(named: "CoolingTowers.usda", in: RealityKitContent.realityKitContentBundle)
            } catch {
                print("GlobeEntity: Failed to load CoolingTowers.usda – \(error)")
                return
            }
        }
        guard let prototype = coolingTowersPrototype,
              let globeModel = globeModel,
              let surfacePos = positionOnGlobe(latitude: latitude, longitude: longitude) else { return }

        // If current asset is a FactoryEntity, stop listeners
        if let oldFactory = currentFactory as? FactoryEntity {
            oldFactory.stopListening()
        }
        // Remove previous instance
        currentFactory?.removeFromParent()

        // Clone and orient
        let cooling = prototype.clone(recursive: true)
        let outward = simd_normalize(surfacePos)
        let upAxis = SIMD3<Float>(0, 1, 0)
        let rotation = simd_quatf(from: upAxis, to: outward)
        cooling.orientation = rotation

        // Slight offset to avoid z-fighting
        let outwardOffset: Float = 0.002
        cooling.position = surfacePos + outward * outwardOffset

        // Scale to match other assets
        cooling.scale = [0.1, 0.1, 0.1]

        globeModel.addChild(cooling)
        currentFactory = cooling
    }

    /// Removes any existing asset instance from the globe.
    @MainActor
    func hideFactory() {
        // Stop listening if it's a FactoryEntity
        if let factory = currentFactory as? FactoryEntity {
            factory.stopListening()
        }
        
        currentFactory?.removeFromParent()
        currentFactory = nil
    }
    
    
    // MARK: - Floating Label
    
    /// Ensures that a floating label attachment is present and updated.
    /// Call this whenever the selected metric, country, or year changes.
    @MainActor
    func updateFloatingLabel(metric: Metric, country: String, year: Int) {
        if let label = labelEntity {
            // Mutate the existing attachment view – prevents flicker.
            label.components.set(
                ViewAttachmentComponent(rootView: GlobeLabelView(metric: metric,
                                                                  country: country,
                                                                  year: year))
            )
        } else {
            // First-time creation
            let label = Entity()
            label.components.set(ViewAttachmentComponent(rootView: GlobeLabelView(metric: metric,
                                                                                  country: country,
                                                                                  year: year)))
            label.components.set(BillboardComponent())
            label.position = [0, 0.65, 0]
            addChild(label)
            labelEntity = label
        }
    }
    
    // MARK: - Globe Setup and Core Functions
    
    // Synchronous setup function for preloaded assets
    @MainActor
    private func setupGlobeSync() -> Bool {
        guard let preloader = assetPreloader, preloader.areAllAssetsReady else {
            return false
        }
        
        // Use preloaded globe model
        if let preloadedGlobe = preloader.cloneModel(.globe) {
            globeModel = preloadedGlobe
            print("GlobeEntity: Using preloaded Earth model (sync)")
        } else {
            return false
        }
        
        // Use preloaded pin prototype
        if let preloadedPin = preloader.cloneModel(.pin) {
            pinPrototype = preloadedPin
            
            // Add larger collision radius for better ray casting reliability
            if let prototype = pinPrototype, !prototype.components.has(CollisionComponent.self) {
                let sphereRadius: Float = 0.007 // 4mm radius (1/10th previous)
                let sphereShape = ShapeResource.generateSphere(radius: sphereRadius)
                prototype.components.set(CollisionComponent(shapes: [sphereShape]))
            }
            
            print("GlobeEntity: Using preloaded Pin model (sync)")
        } else {
            return false
        }
        
        // Setup the globe model
        setupGlobeModel(globeModel!)
        return true
    }
    
    // Async setup function
    @MainActor
    private func setupGlobe() async { 
        // Use preloaded assets if available, otherwise load independently
        if let preloader = assetPreloader {
            // Wait for assets to be ready
            while !preloader.areAllAssetsReady {
                try? await Task.sleep(nanoseconds: 100_000_000) // Wait 0.1 seconds
            }
            
            // Use preloaded globe model
            if let preloadedGlobe = preloader.cloneModel(.globe) {
                globeModel = preloadedGlobe
                print("GlobeEntity: Using preloaded Earth model")
            } else {
                print("GlobeEntity: Preloaded globe model not available, loading independently")
                await loadGlobeIndependently()
            }
            
            // Use preloaded pin prototype
            if let preloadedPin = preloader.cloneModel(.pin) {
                pinPrototype = preloadedPin
                print("GlobeEntity: Using preloaded Pin model")
            } else {
                print("GlobeEntity: Preloaded pin model not available, loading independently")
                await loadPinIndependently()
            }
        } else {
            // No preloader available, load independently
            print("GlobeEntity: No AssetPreloader available, loading models independently")
            await loadGlobeIndependently()
            await loadPinIndependently()
        }
        
        // Setup the globe model if we have one
        if let loadedModel = globeModel {
            setupGlobeModel(loadedModel)
        }
    }
    
    @MainActor
    private func loadGlobeIndependently() async {
        do {
            globeModel = try await Entity(named: "Earth.usda", in: RealityKitContent.realityKitContentBundle)
            print("GlobeEntity: Loaded Earth model independently")
        } catch {
            print("GlobeEntity: Failed to load Earth.usda – \(error)")
        }
    }
    
    @MainActor
    private func loadPinIndependently() async {
        do {
            pinPrototype = try await Entity(named: "Pin.usda", in: RealityKitContent.realityKitContentBundle)
            
            // Add larger collision radius for better ray casting reliability
            if let prototype = pinPrototype, !prototype.components.has(CollisionComponent.self) {
                let sphereRadius: Float = 0.007 // 4mm radius (1/10th previous)
                let sphereShape = ShapeResource.generateSphere(radius: sphereRadius)
                prototype.components.set(CollisionComponent(shapes: [sphereShape]))
            }
            
            print("GlobeEntity: Loaded Pin model independently")
        } catch {
            print("GlobeEntity: Failed to load Pin.usda – \(error)")
        }
    }
    
    @MainActor
    private func setupGlobeModel(_ loadedModel: Entity) {
        // Scale the model if needed to match desired size 
        let currentBounds = loadedModel.visualBounds(relativeTo: nil)
        let currentDiameter = max(currentBounds.extents.x, currentBounds.extents.y, currentBounds.extents.z)
        if currentDiameter > 0 { // Avoid division by zero
            let desiredDiameter: Float = 1.0 // Target 1 meter diameter
            let scaleFactor = desiredDiameter / currentDiameter
            loadedModel.scale = [scaleFactor, scaleFactor, scaleFactor]
            print("Scaled Earth model by \(scaleFactor)")
        } else {
            print("Warning: Could not determine current diameter of Earth model for scaling.")
        }
        
        // Use collision component from Reality Composer Pro instead of hardcoded bounds
        loadedModel.components.set(InputTargetComponent())
        
        self.addChild(loadedModel)
        print("GlobeEntity: Successfully setup Earth model with preloaded assets")
        
        // Trigger ambient audio using developer docs pattern
        startAmbientAudio(on: loadedModel)
    }
    
    // MARK: - Ambient Audio (Developer Docs Pattern)
    @MainActor
    private func startAmbientAudio(on earthEntity: Entity) {
        Task {
            do {
                // Developer docs pattern - load audio and set up AmbientAudioComponent
                let resource = try await AudioFileResource(
                    named: "Immersive Earth.m4a",
                    in: Bundle.main,
                    configuration: .init(shouldLoop: true)
                )
                
                // Set up AmbientAudioComponent and play audio
                earthEntity.components.set(AmbientAudioComponent())
                earthEntity.playAudio(resource)
                earthEntity.components[AmbientAudioComponent.self]?.gain = -10
                
                print("🎵 Ambient audio started")
                
            } catch {
                print("❌ Failed to load ambient audio: \(error)")
            }
        }
    }
    
    // MARK: - Audio Control
    /// Mutes the ambient audio
    @MainActor
    func muteAmbientAudio() {
        globeModel?.stopAllAudio()
    }
    
    /// Unmutes the ambient audio by restarting it
    @MainActor
    func unmuteAmbientAudio() {
        guard let globe = globeModel else { return }
        startAmbientAudio(on: globe)
    }
    
    // Function to later add country markers (placeholders)
    func addMarker(at position: SIMD3<Float>, color: Color) {
        let markerMesh = MeshResource.generateSphere(radius: 0.01)
        let markerMaterial = SimpleMaterial(color: UIColor(color), isMetallic: false)
        let markerEntity = ModelEntity(mesh: markerMesh, materials: [markerMaterial])
        markerEntity.position = position
        self.addChild(markerEntity) 
    }
    
    // Convenience overload: place a small (~1 cm) marker by geographic coordinates
    func addMarker(latitude: Double, longitude: Double, color: Color) {
        guard let globeModel = globeModel,
              let localPos = positionOnGlobe(latitude: latitude, longitude: longitude) else { return }
        let desiredVisualRadius: Float = 0.005 // 5 mm radius
        let actualRadius = desiredVisualRadius / globeModel.scale.x
        let mesh = MeshResource.generateSphere(radius: actualRadius)
        let material = SimpleMaterial(color: UIColor(color), isMetallic: false)
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.position = localPos
        globeModel.addChild(marker)
    }
    
    // Helper to convert Lat/Lon to Cartesian coordinates on the globe surface
    private func positionOnGlobe(latitude: Double, longitude: Double) -> SIMD3<Float>? {
        guard let model = globeModel else { return nil } // Ensure the visual model is loaded
        
        // The desired visual radius of the globe after its own scaling is applied.
        let visualGlobeRadius: Float = 0.5 

        // Convert degrees to radians (no inversion—model’s Y+ points to real north)
        let latRadians = Float(latitude * .pi / 180.0)
        
        // Fine-tune longitude: 10° eastward shift (subtract 170° total)
        let lonRadians = Float((longitude - 170.0) * .pi / 180.0)

        // Calculate position on a sphere with visualGlobeRadius
        let x_visual = visualGlobeRadius * cos(latRadians) * sin(lonRadians)
        let y_visual = visualGlobeRadius * sin(latRadians)
        let z_visual = visualGlobeRadius * cos(latRadians) * cos(lonRadians)

        // To place a child on this visual surface, its local position within the (scaled) parent
        // must be pre-adjusted by dividing by the parent's scale components.
        return SIMD3<Float>(x_visual / model.scale.x, 
                             y_visual / model.scale.y, 
                             z_visual / model.scale.z)
    }
    
    // Function to spin the globe
    func spinTo(latitude: Double, longitude: Double, duration: TimeInterval = 1.5) {
        print("GlobeEntity: Spinning to Lat: \(latitude), Lon: \(longitude)")
        guard let globe = globeModel else {
            print("GlobeEntity: globeModel is nil, cannot spin.")
            return
        }

        // -------------------------------------------------------------
        // 1. Build Cartesian unit vector for the requested lat/lon (negating latitude to invert hemispheres)
        let latRad = Float(-latitude * .pi / 180.0)
        let lonRad = Float(longitude * .pi / 180.0)
        let targetVector = simd_normalize(SIMD3<Float>(
            x: cos(latRad) * sin(lonRad),
            y: sin(latRad),
            z: cos(latRad) * cos(lonRad)
        ))
        
        // 2. First quaternion: point that vector at the camera (−Z)
        let forwardVector = SIMD3<Float>(0, 0, -1)
        let q1 = simd_quatf(from: targetVector, to: forwardVector)
        
        // 3. Keep north pole up: roll correction
        let northPole = SIMD3<Float>(0, 1, 0)
        let northAfter = q1.act(northPole)
        let rollAngle = atan2(northAfter.x, northAfter.y) // radians; rotate around −Z
        let correction = simd_quatf(angle: -rollAngle, axis: forwardVector)
        
        let targetOrientation = correction * q1

        var targetTransform = globe.transform // Start with current transform (preserves scale, position)
        targetTransform.rotation = targetOrientation // Only change rotation
        
        // Animation
        if duration > 0 {
            globe.move(to: targetTransform, relativeTo: self, duration: duration, timingFunction: .easeInOut)
        } else {
            globe.transform = targetTransform // Set instantly if duration is 0
        }
    }
    
    // Helper struct for metric statistics
    struct MetricStats {
        let sortedValues: [Double]
        let quintileBoundaries: [Double] // 4 boundaries creating 5 groups
    }
    
    // Calculate statistics for a given metric
    private func calculateStats(for metric: Metric, dataStore: EnergyDataStore) -> MetricStats {
        let values = dataStore.countries.compactMap { country -> Double? in
            switch metric {
            case .ghg: return country.ghgMtCO2e
            case .power: return country.powerKWh
            case .energy: return country.energyUseKgOE
            }
        }.filter { $0 > 0 }
        
        guard values.count >= 5 else {
            // If we have fewer than 5 values, return empty boundaries
            return MetricStats(sortedValues: values.sorted(), quintileBoundaries: [])
        }
        
        let sortedValues = values.sorted()
        let count = sortedValues.count
        
        // Calculate quintile boundaries (20th, 40th, 60th, 80th percentiles)
        let boundaries = [0.2, 0.4, 0.6, 0.8].map { percentile -> Double in
            let index = percentile * Double(count - 1)
            let lowerIndex = Int(floor(index))
            let upperIndex = Int(ceil(index))
            
            if lowerIndex == upperIndex {
                return sortedValues[lowerIndex]
            } else {
                let weight = index - Double(lowerIndex)
                return sortedValues[lowerIndex] * (1 - weight) + sortedValues[upperIndex] * weight
            }
        }
        
        return MetricStats(sortedValues: sortedValues, quintileBoundaries: boundaries)
    }
    
    // Function to update visualization based on metric
    func updateVisualization(metric: Metric, dataStore: EnergyDataStore) {
        print("GlobeEntity: Updating visualization for metric: \(metric.rawValue)")
        
        // Calculate statistics for this metric
        let stats = calculateStats(for: metric, dataStore: dataStore)
        if !stats.quintileBoundaries.isEmpty {
            print("Stats for \(metric.rawValue): quintile boundaries = \(stats.quintileBoundaries.map { String(format: "%.2f", $0) })")
        } else {
            print("Stats for \(metric.rawValue): insufficient data for quintiles (\(stats.sortedValues.count) values)")
        }
        
        // We'll keep existing pins and animate them; track which ones are touched this pass
        var seenCountries: Set<String> = []

        // 2. Iterate through countries and add new markers
        for country in dataStore.countries {
            // Get coordinates and metric value
            guard let lat = country.latitude, 
                  let lon = country.longitude,
                  let globeModel = self.globeModel else { 
                continue 
            }

            // DEBUG: Print the scale of the globeModel (can be removed later)
            // print("DEBUG: globeModel.scale.x = \(globeModel.scale.x)")

            // Get the value for the selected metric (check if it exists)
            let metricValue: Double? // Declare a variable to hold the metric value
            switch metric { // 'metric' is of type Metric (defined in EnergyDataStore.swift)
            case .ghg:
                metricValue = country.ghgMtCO2e
            case .power:
                metricValue = country.powerKWh // Assign value for Electric Power Consumption
            case .energy:
                metricValue = country.energyUseKgOE // Assign value for Energy Use
            // All cases of Metric enum (.ghg, .power, .energy) are covered.
            }

            if let value = metricValue, value != 0 { // Ensure value exists and is non-zero for visualization
                // --- PIN MARKER CREATION OR UPDATE ---
                
                if let position = positionOnGlobe(latitude: lat, longitude: lon) {
                    // Ensure the pin prototype is loaded
                    guard let prototype = pinPrototype else {
                        print("GlobeEntity: pin prototype not loaded – skipping marker for \(country.countryName)")
                        continue
                    }

                    // Calculate quintile group (0-4, with any rounding errors going to group 2 - medium)
                    let quintileGroup = calculateQuintileGroup(value: value, stats: stats)
                    
                    // Shared calculations
                    let outward = simd_normalize(position)
                    // NEW: Use global max across ALL years for absolute scaling
                    let globalMax = dataStore.globalMaxValue(for: metric)
                    let maxValue = globalMax > 0 ? globalMax : 1.0
                    
                    // Handle negative values with placeholder height, positive values with normal scaling
                    let normalizedValue: Float
                    if value < 0 {
                        normalizedValue = Float(0.1 / maxValue) // Treat negative values as if they were 0.1
                    } else {
                        normalizedValue = Float(value / maxValue) // 0.0 to 1.0 for positive values
                    }
                    let outwardOffset: Float = 0.002 + normalizedValue * 0.030 // 2-32 mm
                    let targetPos = position + outward * outwardOffset
                    let key = country.countryName
                    
                    if let existingPin = countryPins[key] {
                        // Animate existing pin
                        var newTransform = existingPin.transform
                        newTransform.translation = targetPos
                        existingPin.move(to: newTransform, relativeTo: globeModel, duration: 0.6, timingFunction: .easeInOut)
                        applyPinColor(to: existingPin, quintileGroup: quintileGroup, countryName: key)
                        // Country name is now stored in the ViewAttachmentComponent label
                        updateCountryLabel(for: existingPin, countryName: key, isSelected: key == dataStore.selectedCountry)
                        seenCountries.insert(key)
                    } else {
                        // Create fresh pin
                        let pinEntity = prototype.clone(recursive: true)
                        pinEntity.orientation = simd_quatf(from: SIMD3<Float>(0,1,0), to: outward)
                        applyPinColor(to: pinEntity, quintileGroup: quintileGroup, countryName: key)
                        pinEntity.position = targetPos
                        
                        // Ensure the cloned pin has larger collision radius for ray casting
                        if !pinEntity.components.has(CollisionComponent.self) {
                            let sphereRadius: Float = 0.007 // 4mm radius (1/10th previous)
                            let sphereShape = ShapeResource.generateSphere(radius: sphereRadius)
                            pinEntity.components.set(CollisionComponent(shapes: [sphereShape]))
                        }
                        
                        // Country name is now stored in the ViewAttachmentComponent label
                        updateCountryLabel(for: pinEntity, countryName: key, isSelected: key == dataStore.selectedCountry)
                        globeModel.addChild(pinEntity)
                        countryPins[key] = pinEntity
                        seenCountries.insert(key)
                    }
                
                /* ORIGINAL ORB CODE DISABLED - all orb creation logic commented out
                 END OF COMMENTED ORB CODE */
                }
            }
        }
        // Remove pins for countries not seen in this update
        for (key, pin) in countryPins where !seenCountries.contains(key) {
            pin.removeFromParent()
            countryPins.removeValue(forKey: key)
        }
        print("Added / updated markers for \(metric.rawValue).")
        
        // Trigger pin glow for selected country (same logic as updateCountryLabel)
        updatePinGlow(selectedCountry: dataStore.selectedCountry)
    }
    
    // MARK: - Pin Glow Management (Following updateCountryLabel pattern)
    /// Triggers glow animation only for the selected country's pin using built-in timeline
    private func updatePinGlow(selectedCountry: String) {
        // Stop all existing glow animations
        for (_, pin) in countryPins {
            stopPinGlowTimeline(pin: pin)
        }
        
        // Find the specific pin for the selected country
        guard let selectedPin = countryPins[selectedCountry] else {
            print("⚠️ No pin found for selected country: \(selectedCountry)")
            return
        }
        
        print("🔆 Triggering glow for \(selectedCountry) pin only")
        
        // Trigger the built-in PinGlowLoop timeline on this specific pin
        startPinGlowTimeline(pin: selectedPin)
    }
    
    /// Stop only glow-related animations on a specific pin, preserving positioning animations
    private func stopPinGlowTimeline(pin: Entity) {
        // Find Root entity where glow timelines live
        guard let rootEntity = pin.children.first(where: { $0.name == "Root" }) else {
            print("⚠️ Could not find Root entity to stop glow animations")
            return
        }
        
        // Stop all animations on Root entity
        rootEntity.stopAllAnimations()
        print("⏹️ Stopped all animations on Root entity (glow timelines)")
        
        // SIMPLE FIX: Set all pin sphere opacity to 100% when stopping animations
        // This ensures no freeze-frame artifacts - all pins are fully visible
        if let sphereEntity = pin.findEntity(named: "Sphere") {
            sphereEntity.components.set(OpacityComponent(opacity: 1.0))
            print("🔄 Reset Sphere opacity to 100%")
        }
        
        // Note: Pin positioning animations should be on the main pin entity, not Root,
        // so this should preserve those animations while stopping glow
    }
    
    /// Start the built-in PinGlowLoop timeline on a specific pin entity
    private func startPinGlowTimeline(pin: Entity) {
        // Debug: Print what's actually in the pin entity
        print("🔍 Debugging pin entity structure:")
        print("  Pin name: \(pin.name)")
        print("  Available animations: \(pin.availableAnimations.map { $0.name })")
        print("  Child entities: \(pin.children.map { $0.name })")
        
        // Look deeper in hierarchy
        for child in pin.children {
            print("    Child '\(child.name)' has children: \(child.children.map { $0.name })")
            print("    Child '\(child.name)' has animations: \(child.availableAnimations.map { $0.name })")
        }
        
        // The PinGlowLoop timeline is under the "Root" child entity according to Pin.usda
        if let rootEntity = pin.children.first(where: { $0.name == "Root" }) {
            print("🎯 Found Root entity, looking for PinGlowLoop timeline...")
            
            if let glowTimeline = rootEntity.findEntity(named: "PinGlowLoop") {
                // Try to play available animations on the timeline
                if let glowAnimation = glowTimeline.availableAnimations.first {
                    glowTimeline.playAnimation(glowAnimation.repeat())
                    print("✅ Started PinGlowLoop timeline animation")
                } else {
                    print("❌ No animations found on PinGlowLoop timeline")
                }
            } else {
                print("❌ Could not find PinGlowLoop timeline in Root entity")
                
                // Try all available animations on the root entity
                let allAnimations = rootEntity.availableAnimations
                if !allAnimations.isEmpty {
                    print("🎯 Found \(allAnimations.count) animations on root, trying first one:")
                    let animation = allAnimations[0]
                    rootEntity.playAnimation(animation.repeat())
                    print("✅ Started animation: \(animation.name ?? "unnamed")")
                } else {
                    print("❌ No animations found on root entity")
                }
            }
        } else {
            print("❌ Could not find Root child entity in pin")
        }
    }
    
    // Calculate which quintile group a value belongs to (0-4)
    private func calculateQuintileGroup(value: Double, stats: MetricStats) -> Int {
        // Handle edge cases
        guard !stats.quintileBoundaries.isEmpty else {
            return 2 // Default to medium group if insufficient data
        }
        
        let boundaries = stats.quintileBoundaries
        
        // Determine which quintile the value falls into
        if value <= boundaries[0] {
            return 0 // Lowest (0-20th percentile)
        } else if value <= boundaries[1] {
            return 1 // Low (20th-40th percentile)
        } else if value <= boundaries[2] {
            return 2 // Medium (40th-60th percentile)
        } else if value <= boundaries[3] {
            return 3 // High (60th-80th percentile)
        } else {
            return 4 // Highest (80th-100th percentile)
        }
    }
    
    // MARK: - Country Label Helpers
    /// Adds or removes a floating `Text` label that shows the country's name above a pin.
    /// - Parameters:
    ///   - pin: The pin `Entity` to attach the label to.
    ///   - countryName: The country display name.
    ///   - isSelected: If `true`, the label is shown; otherwise it is removed.
    private func updateCountryLabel(for pin: Entity, countryName: String, isSelected: Bool) {
        let labelName = "CountryLabel"
        if isSelected {
            // Re-use existing label entity or create it
            let labelEntity: Entity
            if let existing = pin.children.first(where: { $0.name == labelName }) {
                labelEntity = existing
            } else {
                labelEntity = Entity()
                labelEntity.name = labelName
                labelEntity.components.set(BillboardComponent())
                pin.addChild(labelEntity)
            }
            // Update / set SwiftUI view
            labelEntity.components.set(ViewAttachmentComponent(rootView:
                Text(countryName)
                    .font(.system(size: 3, weight: .bold))
                    .padding(1)
                    .background(.regularMaterial, in: Capsule())
            ))
            // Position ~5 cm above pin head in local space
            labelEntity.position = [0, 0.005, 0.005]
        } else {
            // Remove label if no longer selected
            if let existing = pin.children.first(where: { $0.name == labelName }) {
                existing.removeFromParent()
            }
        }
    }

    // Apply pin color using exact Graffiti-EG spraycan pattern
    private func applyPinColor(to pinEntity: Entity, quintileGroup: Int, countryName: String) {
        // Map quintile group directly to IntensityValue (0-4)
        let intensityValue: Int32 = Int32(quintileGroup)
        
        let groupName = ["Lowest", "Low", "Medium", "High", "Highest"][quintileGroup]
        print("PIN COLOR: \(countryName) quintile=\(quintileGroup) (\(groupName)) -> IntensityValue=\(intensityValue)")
        
        // Apply to both sphere entities (GlossyBlackWoodPlank and GlossyBlackWoodPlank_1)
        let sphereNames = ["Sphere", "Sphere_1"]
        
        for sphereName in sphereNames {
            guard let sphereEntity = pinEntity.findEntity(named: sphereName) else {
                print("       ⚠️ Could not find \(sphereName) entity in pin")
                continue
            }
            
            // Apply color using Graffiti-EG updateMaterials pattern
            sphereEntity.updateMaterials { material in
                guard var shaderGraphMaterial = material as? ShaderGraphMaterial else { 
                    print("       ⚠️  \(sphereName) material is not ShaderGraphMaterial: \(type(of: material))")
                    return 
                }
                
                do {
                    // This is the exact line from Graffiti-EG: set the IntensityValue parameter
                    try shaderGraphMaterial.setParameter(name: "IntensityValue", value: .int(intensityValue))
                    material = shaderGraphMaterial
                    print("       ✅ Successfully set IntensityValue to \(intensityValue) on \(sphereName)")
                } catch {
                    print("       ❌ Failed to set IntensityValue on \(sphereName): \(error)")
                }
            }
        }
    }
}

// Extension from Graffiti-EG: Recursively walks the entity hierarchy and lets you mutate every Material in-place
extension Entity {
    func updateMaterials(_ edit: (inout RealityKit.Material) -> Void) {
        for child in children { child.updateMaterials(edit) }
        if var mc = components[ModelComponent.self] {
            mc.materials = mc.materials.map { var m = $0; edit(&m); return m }
            components.set(mc)
        }
    }
}
