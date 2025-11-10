//
//  EnergyAtlasApp.swift
//  EnergyAtlas
//
//  An open-source visionOS application for visualizing global energy data
//

import SwiftUI
import Observation
import TipKit

@main
struct EnergyAtlasApp: App {
    // Create a single instance of the data store for the entire app
    @State private var dataStore = EnergyDataStore()
    // Create a single instance of the AppModel for app-wide state
    @State private var appModel = AppModel()
    // Create asset preloader for managing all RealityKit assets
    @State private var assetPreloader = AssetPreloader()
    
    // State to control the immersion style (set to mixed as requested)
    @State private var immersionStyle: ImmersionStyle = .mixed
    
    init() {
        // Configure TipKit for the app
        Task {
            await EnergyVisualizerTipManager.shared.configureTips()
        }
    }

    var body: some Scene {
        // Main window for the application (will show Intro when ready)
        WindowGroup {
            if assetPreloader.isIntroModelReady {
                ContentView()
                    .environment(dataStore) // Inject the data store into the environment
                    .environment(appModel)  // Inject the AppModel into the environment
                    .environment(assetPreloader) // Inject the asset preloader
            } else {
                // Empty view while loading - window exists but is invisible
                Color.clear
                    .frame(width: 1, height: 1)
                    .environment(dataStore)
                    .environment(appModel)
                    .environment(assetPreloader)
            }
        }
        .windowStyle(.plain) // Use a standard window style
        
        // --- Control Panel with new CountryInfoPanel ---
        WindowGroup(id: "ControlPanel") {
            VStack(alignment: .center, spacing: 0.02) {
                // Row of control panels
                HStack(alignment: .top, spacing: 0.05) {
                    CountryInfoPanel()
                        .frame(width: 300)
                    ControlPanelView()
                    MetricCarouselView()
                        .offset(z: 0.02) // slight depth offset
                }
            }
            .environment(dataStore)
            .environment(appModel)
            .environment(assetPreloader)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        // Attempt to use .utilityPanel for placement.
        .defaultWindowPlacement { _, _ in 
            let placementPosition = SwiftUI.WindowPlacement.Position.utilityPanel
            return SwiftUI.WindowPlacement(placementPosition) // Use the init(_ position: WindowPlacement.Position?) initializer
        }
        
        // --- Chart Panel as Volumetric Window (3D) ---
        WindowGroup(id: "ChartPanel") {
            // Use GeometryReader3D to properly scale and center the 3D chart within volumetric bounds
            GeometryReader3D { proxy in
                let windowSize = proxy.size
                // Convert window size from meters to points for SwiftUI (rough conversion: 1m ≈ 1000 points)
                let chartWidth = windowSize.width * 2  // Use most of the width
                let chartHeight = windowSize.height * 2 // Use most of the height
                
                Country3DChartView()
                    .environment(dataStore)
                    .environment(appModel)
                    .environment(assetPreloader)
                    // Explicitly size the chart to fill the volumetric window
                    .frame(width: chartWidth, height: chartHeight)
                    .background(.clear)
                    // Center within the volumetric space
                    .position(x: chartWidth/4, y: chartHeight/4)
                    // Offset slightly towards the back to prevent front clipping
                    .offset(y: 100)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.5, depth: 0.5, in: .meters)
        .defaultWindowPlacement { _, context in
            SwiftUI.WindowPlacement(.leading(context.windows.first { $0.id == "ControlPanel" }!))
        }
        
        // --- AI Analysis Panel ---
        if #available(visionOS 26.0, *) {
            WindowGroup(id: "AIPanel") {
                AIEnergyPanel(dataStore: dataStore)
                    .environment(dataStore)
                    .environment(appModel)
                    .environment(assetPreloader)
            }
            .windowStyle(.automatic)
            .windowResizability(.contentSize)
            .defaultSize(width: 900, height: 700)
            .defaultWindowPlacement { _, context in
                SwiftUI.WindowPlacement(.trailing(context.windows.first { $0.id == "ControlPanel" }!))
            }
        }
        
        // Define the Immersive Space for the globe visualization
        ImmersiveSpace(id: appModel.immersiveSpaceID) { // Use ID from AppModel
            // We will create GlobeView later
            GlobeView()
                .environment(dataStore) // Pass the store here too
                .environment(appModel)  // Pass the AppModel here too
                .environment(assetPreloader) // Pass the asset preloader here too
        }
        // Crucially set the style to mixed to place content in the room
        .immersionStyle(selection: $immersionStyle, in: .mixed)
        .immersiveEnvironmentBehavior(.coexist)
    }
}
