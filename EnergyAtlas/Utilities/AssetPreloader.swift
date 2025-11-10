//
//  AssetPreloader.swift
//  EnergyAtlas
//
//

import Foundation
import RealityKit
import RealityKitContent
import Observation

@Observable
class AssetPreloader {
    // Asset loading states
    var isIntroModelReady = false
    var isGlobeModelReady = false
    var isPinModelReady = false
    
    // All assets ready flag
    var areAllAssetsReady: Bool {
        return isIntroModelReady && isGlobeModelReady && isPinModelReady
    }
    
    // Preloaded entities
    private var introModelEntity: Entity?
    private var globeModelEntity: Entity?
    private var pinModelEntity: Entity?
    
    // Public accessors for preloaded entities
    var introModel: Entity? { introModelEntity }
    var globeModel: Entity? { globeModelEntity }
    var pinModel: Entity? { pinModelEntity }
    
    init() {
        // Start preloading all assets during app boot
        preloadAllAssets()
    }
    
    private func preloadAllAssets() {
        print("AssetPreloader: Starting asset preloading during boot...")
        
        // Use RunLoop to extend boot screen while assets load
        var allAssetsLoaded = false
        
        Task { @MainActor in
            await loadAllAssetsAsync()
            allAssetsLoaded = true
        }
        
        // Wait for completion using RunLoop with timeout
        let startTime = Date()
        let timeout: TimeInterval = 15.0 // 15 second timeout for all assets
        
        while !allAssetsLoaded && Date().timeIntervalSince(startTime) < timeout {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }
        
        if !allAssetsLoaded {
            print("AssetPreloader: Asset loading timed out, proceeding...")
            // Set all to ready to prevent hanging
            isIntroModelReady = true
            isGlobeModelReady = true
            isPinModelReady = true
        }
    }
    
    @MainActor
    private func loadAllAssetsAsync() async {
        print("AssetPreloader: Loading assets concurrently...")
        
        // Load all assets concurrently using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            // Load intro animation
            group.addTask {
                await self.loadIntroModel()
            }
            
            // Load globe model
            group.addTask {
                await self.loadGlobeModel()
            }
            
            // Load pin model
            group.addTask {
                await self.loadPinModel()
            }
        }
        
        print("AssetPreloader: All assets loaded!")
    }
    
    @MainActor
    private func loadIntroModel() async {
        do {
            print("AssetPreloader: Loading IntroAnimation...")
            introModelEntity = try await Entity(named: "IntroAnimation", in: RealityKitContent.realityKitContentBundle)
            isIntroModelReady = true
            print("AssetPreloader: IntroAnimation loaded!")
        } catch {
            print("AssetPreloader: Failed to load IntroAnimation: \(error)")
            isIntroModelReady = true // Allow app to continue
        }
    }
    
    @MainActor
    private func loadGlobeModel() async {
        do {
            print("AssetPreloader: Loading Earth.usda...")
            globeModelEntity = try await Entity(named: "Earth.usda", in: RealityKitContent.realityKitContentBundle)
            isGlobeModelReady = true
            print("AssetPreloader: Earth.usda loaded!")
        } catch {
            print("AssetPreloader: Failed to load Earth.usda: \(error)")
            isGlobeModelReady = true // Allow app to continue
        }
    }
    
    @MainActor
    private func loadPinModel() async {
        do {
            print("AssetPreloader: Loading Pin.usda...")
            pinModelEntity = try await Entity(named: "Pin.usda", in: RealityKitContent.realityKitContentBundle)
            isPinModelReady = true
            print("AssetPreloader: Pin.usda loaded!")
        } catch {
            print("AssetPreloader: Failed to load Pin.usda: \(error)")
            isPinModelReady = true // Allow app to continue
        }
    }
    
    // Helper method to get a copy of a preloaded model
    func cloneModel(_ modelType: ModelType) -> Entity? {
        switch modelType {
        case .intro:
            return introModelEntity?.clone(recursive: true)
        case .globe:
            return globeModelEntity?.clone(recursive: true)
        case .pin:
            return pinModelEntity?.clone(recursive: true)
        }
    }
}

enum ModelType {
    case intro
    case globe
    case pin
}
