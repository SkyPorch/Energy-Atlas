import SwiftUI
import FoundationModels

// Custom hover effect for proper button highlighting
struct RoundedRectangleHoverEffect: CustomHoverEffect {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some CustomHoverEffect {
        content.hoverEffect { effect, isActive, proxy in
            effect.animation(.default.delay(isActive ? 0.1 : 0.2)) {
                $0.clipShape(RoundedRectangle(cornerRadius: cornerRadius)
                    .size(width: proxy.size.width, height: proxy.size.height))
                    .scaleEffect(isActive ? 1.02 : 1.0)
            }
        }
    }
}

@available(visionOS 26.0, *)
struct AIEnergyPanel: View {
    @StateObject private var aiAnalyzer: AIEnergyAnalyzer
    @State private var selectedQuestion: AIEnergyAnalyzer.AnalysisQuestion?
    private let dataStore: EnergyDataStore
    
    init(dataStore: EnergyDataStore) {
        self._aiAnalyzer = StateObject(wrappedValue: AIEnergyAnalyzer(dataStore: dataStore))
        self.dataStore = dataStore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            Divider()
            
            // Model Status
            modelStatusSection
            
            if aiAnalyzer.isModelReady {
                Divider()
                
                // Main Content: Questions and Results Side by Side
                HStack(alignment: .top, spacing: 20) {
                    // Left Side: Questions (organized by category)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ask AI Questions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(AIEnergyAnalyzer.QuestionCategory.allCases) { category in
                                    CategorySection(
                                        category: category,
                                        questions: AIEnergyAnalyzer.AnalysisQuestion.allCases.filter { $0.category == category },
                                        selectedQuestion: selectedQuestion,
                                        isAnalyzing: aiAnalyzer.isAnalyzing,
                                        currentCountry: dataStore.selectedCountry,
                                        currentYear: dataStore.selectedYear,
                                        onSelect: analyzeQuestion
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 350)
                    
                    Divider()
                    
                    // Right Side: Results
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Analysis Results")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if aiAnalyzer.analysisResults.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                VStack(spacing: 8) {
                                    Text("AI Analysis Ready")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Ask a question to see intelligent insights about your energy data")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        ForEach(aiAnalyzer.analysisResults.reversed()) { insight in
                                            InsightCard(insight: insight)
                                                .id(insight.id)
                                        }
                                    }
                                    .padding(.top, 1) // Small padding to ensure scroll works
                                }
                                .onChange(of: aiAnalyzer.analysisResults.count) { oldCount, newCount in
                                    if newCount > oldCount, let firstResult = aiAnalyzer.analysisResults.last {
                                        withAnimation(.easeOut(duration: 0.6)) {
                                            proxy.scrollTo(firstResult.id, anchor: .top)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            aiAnalyzer.checkModelAvailability()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("AI Energy Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Powered by Apple Intelligence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if aiAnalyzer.isAnalyzing {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !aiAnalyzer.analysisResults.isEmpty {
                Button("Clear") {
                    aiAnalyzer.clearResults()
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Model Status Section
    private var modelStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(aiAnalyzer.availabilityColor)
                    .frame(width: 12, height: 12)
                
                Text(aiAnalyzer.availabilityMessage)
                    .font(.subheadline)
                    .foregroundColor(aiAnalyzer.availabilityColor)
                
                Spacer()
                
                if !aiAnalyzer.isModelReady {
                    Button("Refresh") {
                        aiAnalyzer.checkModelAvailability()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            // Language tip and debug info
            if aiAnalyzer.isModelReady {
                Text("💡 For best results, ensure your device language is set to English (US)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
        }
    }
    
    
    // MARK: - Actions
    private func analyzeQuestion(_ question: AIEnergyAnalyzer.AnalysisQuestion) {
        selectedQuestion = question
        
        Task {
            await aiAnalyzer.analyzeEnergyData(question: question)
            selectedQuestion = nil
        }
    }
}

// MARK: - Category Section
@available(visionOS 26.0, *)
struct CategorySection: View {
    let category: AIEnergyAnalyzer.QuestionCategory
    let questions: [AIEnergyAnalyzer.AnalysisQuestion]
    let selectedQuestion: AIEnergyAnalyzer.AnalysisQuestion?
    let isAnalyzing: Bool
    let currentCountry: String
    let currentYear: Int
    let onSelect: (AIEnergyAnalyzer.AnalysisQuestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category Header
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            // Questions in this category
            ForEach(questions) { question in
                QuestionCard(
                    question: question,
                    isSelected: selectedQuestion == question,
                    isAnalyzing: isAnalyzing,
                    currentCountry: currentCountry,
                    currentYear: currentYear
                ) {
                    onSelect(question)
                }
            }
        }
    }
}

// MARK: - Question Card
@available(visionOS 26.0, *)
struct QuestionCard: View {
    let question: AIEnergyAnalyzer.AnalysisQuestion
    let isSelected: Bool
    let isAnalyzing: Bool
    let currentCountry: String
    let currentYear: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Use displayText for dynamic country/year replacement
                    Text(question.displayText(country: currentCountry, year: currentYear))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Group {
                        if isSelected && isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                
                Text("Tap to get AI analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .cornerRadius(8)
        .hoverEffect(RoundedRectangleHoverEffect(cornerRadius: 8))
        .buttonStyle(.plain)
        .disabled(isAnalyzing)
    }
}

// MARK: - Insight Card
@available(visionOS 26.0, *)
struct InsightCard: View {
    let insight: AIEnergyAnalyzer.EnergyInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Use displayText with the stored context for dynamic questions
                    Text(insight.question.displayText(country: insight.contextCountry, year: insight.contextYear))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            
            // AI Analysis
            Text(insight.analysis)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Relevant Countries
            if !insight.relevantCountries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Countries Mentioned:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(countries: insight.relevantCountries.prefix(8)) { country in
                        CountryTag(name: country)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Country Tag
@available(visionOS 26.0, *)
struct CountryTag: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
    }
}

// MARK: - Flow Layout for Country Tags
@available(visionOS 26.0, *)
struct FlowLayout<T: Hashable>: View {
    let countries: [T]
    let content: (T) -> CountryTag
    
    init(countries: any Collection<T>, @ViewBuilder content: @escaping (T) -> CountryTag) {
        self.countries = Array(countries)
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(computeRows(), id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func computeRows() -> [[T]] {
        var rows: [[T]] = []
        var currentRow: [T] = []
        
        for item in countries {
            currentRow.append(item)
            if currentRow.count >= 4 { // Max 4 items per row
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// MARK: - Preview
@available(visionOS 26.0, *)
struct AIEnergyPanel_Previews: PreviewProvider {
    static var previews: some View {
        AIEnergyPanel(dataStore: EnergyDataStore())
            .frame(width: 500, height: 800)
    }
}
