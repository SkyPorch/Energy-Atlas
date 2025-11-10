//
//  ContentView.swift
//  EnergyAtlas
//
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @Environment(EnergyDataStore.self) var dataStore
    @Environment(AssetPreloader.self) var assetPreloader
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        VStack {
            //Text("Energy Atlas")
                //.padding()
            Model3D(named: "IntroAnimation", bundle: realityKitContentBundle)
                .padding(.bottom, 75)

            //Text("Learn About Global Energy Consumption")

            ToggleImmersiveSpaceButton()
        }
        .padding()
        // This onChange should now be reliably triggered by GlobeView's onAppear/onDisappear
        .onChange(of: appModel.immersiveSpaceState) { oldState, newState in 
            print("ContentView: AppModel immersiveSpaceState changed from \(oldState) to: \(newState)")
            if newState == .open {
                print("ContentView: AppModel state is .open, attempting to open ControlPanel for ID: ControlPanel")
                openWindow(id: "ControlPanel")
                // Auto-dismiss this ContentView window after entering immersive space
                dismissWindow()
            } else if newState == .closed {
                print("ContentView: AppModel state is .closed. Optional: considering dismissing ControlPanel.")
                // dismissWindow(id: "ControlPanel")
            }
        }
        .onAppear {
            print("ContentView appeared. Initial appModel.immersiveSpaceState: \(appModel.immersiveSpaceState)")
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
        .environment(EnergyDataStore())
}
