//
//  VisualizationTips.swift
//  EnergyAtlas
//
//  Tips for guiding users through the Visualization Controls
//

import Foundation
import TipKit
import SwiftUI

// MARK: - Individual Tips
struct YearSelectionTip: Tip {
    var title: Text {
        Text("Select a Year")
    }
    
    var message: Text? {
        Text("Use the slider to explore energy data from 2005 to 2022. Watch how countries' consumption and emissions change over time.")
    }
    
    var image: Image? {
        Image(systemName: "calendar")
    }
    
    var options: [Option] {
        [Tips.MaxDisplayCount(1)]
    }
}

struct CountrySelectionTip: Tip {
    var title: Text {
        Text("Choose a Country")
    }
    
    var message: Text? {
        Text("Select any country to view its detailed energy metrics. You can also tap on the pin to select a country. Use the carousel on the right to change the metric (Total Greenhouse Gas Emissions, Electric Power consumed per person, And Total Energy consumed per person)")
    }
    
    var image: Image? {
        Image(systemName: "globe.americas")
    }
    
    var options: [Option] {
        [Tips.MaxDisplayCount(1)]
    }
}

struct ChartTip: Tip {
    var title: Text {
        Text("View 3D Chart")
    }
    
    var message: Text? {
        Text("Toggle the 3D chart to see how all countries compare across three dimensions: power, energy, and emissions. Your actively selected country will appear as a larger sphere, and its color will match the metric selected in the main view. Use log scale to better visualize countries with different magnitudes.")
    }
    
    var image: Image? {
        Image(systemName: "chart.bar.xaxis")
    }
    
    var options: [Option] {
        [Tips.MaxDisplayCount(1)]
    }
}

struct AIInsightsTip: Tip {
    var title: Text {
        Text("Learn with AI")
    }
    
    var message: Text? {
        Text("Ask Apple Intelligence questions about how to navigate the app, energy trends, country comparisons, and what the data reveals. Get instant insights powered by on-device AI.")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
    
    var options: [Option] {
        [Tips.MaxDisplayCount(1)]
    }
}

// MARK: - Tip Manager
@MainActor
class EnergyVisualizerTipManager {
    static let shared = EnergyVisualizerTipManager()
    
    // Individual tips
    let yearTip = YearSelectionTip()
    let countryTip = CountrySelectionTip()
    let chartTip = ChartTip()
    let aiTip = AIInsightsTip()
    
    // TipGroup for controlling the sequence of tips
    @State var controlsTipGroup = TipGroup(.firstAvailable) {
        YearSelectionTip()
        CountrySelectionTip()
        ChartTip()
        AIInsightsTip()
    }
    
    private init() {}
    
    func configureTips() async {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        
        #if DEBUG
        // Uncomment to reset tips during development
        // Tips.showAllTipsForTesting()
        print("DEBUG: Tips configured for Energy Atlas")
        #endif
    }
    
    func resetTips() async {
        yearTip.invalidate(reason: .actionPerformed)
        countryTip.invalidate(reason: .actionPerformed)
        chartTip.invalidate(reason: .actionPerformed)
        aiTip.invalidate(reason: .actionPerformed)
        print("All tips have been reset")
    }
}

