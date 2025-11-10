import SwiftUI
import TipKit

struct ControlPanelView: View {
    // Shared app state
    @Environment(EnergyDataStore.self) var dataStore
    @Environment(AppModel.self) var appModel
    // Window helpers to spawn/dismiss chart panel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    // TipGroup from manager
    @State private var controlsTipGroup = EnergyVisualizerTipManager.shared.controlsTipGroup

    // Filtered list of country names for the picker
    private var countryNames: [String] {
        dataStore.countries.map { $0.countryName }.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Visualization Controls")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Year")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .popoverTip(controlsTipGroup.currentTip as? YearSelectionTip, arrowEdge: .trailing)
                
                Text("\(String(dataStore.selectedYear))")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding<Double>(
                        get: { Double(dataStore.selectedYear) },
                        set: { dataStore.reloadDataForYear(Int($0)) }
                    ),
                    in: 2005...2022,
                    step: 1,
                    minimumValueLabel: Text("2005").font(.caption),
                    maximumValueLabel: Text("2022").font(.caption)
                ) {
                    Text("Year")
                }
            }
            .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Country")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .popoverTip(controlsTipGroup.currentTip as? CountrySelectionTip, arrowEdge: .trailing)
                
                // Explicitly create the binding
                Picker("Country", selection: Binding<String>(
                    get: { dataStore.selectedCountry },
                    set: { dataStore.selectedCountry = $0 }
                )) {
                    // Use the computed countryNames array
                    ForEach(countryNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.bottom, 32)
            
            // 3D Chart Controls Section
            VStack(alignment: .leading, spacing: 12) {
                Text("3D Chart")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .popoverTip(controlsTipGroup.currentTip as? ChartTip, arrowEdge: .trailing)
                
                // Button and toggle in same row
                HStack(spacing: 16) {
                    Button(appModel.showChart ? "Hide Chart" : "Show Chart") {
                        appModel.showChart.toggle()
                        if appModel.showChart {
                            openWindow(id: "ChartPanel")
                        } else {
                            dismissWindow(id: "ChartPanel")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Toggle("Log Scale", isOn: Binding<Bool>(
                        get: { dataStore.logarithmicScale },
                        set: { dataStore.logarithmicScale = $0 }
                    ))
                    .disabled(!appModel.showChart)
                }
            }
            .padding(.bottom, 32)
            
            // AI Insights Section
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Insights")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .popoverTip(controlsTipGroup.currentTip as? AIInsightsTip, arrowEdge: .trailing)
                
                if #available(visionOS 26.0, *) {
                    Button(appModel.showAIPanel ? "Hide Apple Intelligence" : "Learn More with Apple Intelligence") {
                        appModel.showAIPanel.toggle()
                        if appModel.showAIPanel {
                            openWindow(id: "AIPanel")
                        } else {
                            dismissWindow(id: "AIPanel")
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("AI features require visionOS 26.0+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)
            
            Spacer() // Push to bottom
            
            // Audio Controls Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Toggle(appModel.isMusicMuted ? "Unmute Music" : "Mute Music", isOn: Binding<Bool>(
                    get: { appModel.isMusicMuted },
                    set: { appModel.isMusicMuted = $0 }
                ))
            }
            .padding(.bottom, 20)
            
            // In/Out immersive space toggle
            HStack {
                Spacer()
                ToggleImmersiveSpaceButton()
                Spacer()
            }
            .padding(.top, 8) // Space above button here

        }
        .padding(30) // Add padding inside the panel
        .frame(width: 400) // Give the panel a defined width
        // Add a glass background for better visibility
        .glassBackgroundEffect()
    }
}

// Preview
#Preview(windowStyle: .plain) {
    // Create a dummy store for the preview
    let previewStore = EnergyDataStore()
    // Add some dummy data if needed for preview design
    // previewStore.countries = [ ... ]
    
    return ControlPanelView()
        .environment(previewStore)
}
