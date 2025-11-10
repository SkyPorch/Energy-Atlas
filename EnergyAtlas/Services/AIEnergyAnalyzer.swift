import Foundation
import SwiftUI
import FoundationModels

// MARK: - AI-Powered Energy Analysis using Foundation Models
@available(visionOS 26.0, *)
class AIEnergyAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResults: [EnergyInsight] = []
    @Published var modelAvailability: SystemLanguageModel.Availability = .unavailable(.modelNotReady)
    
    private let model = SystemLanguageModel.default
    private let dataStore: EnergyDataStore
    
    init(dataStore: EnergyDataStore) {
        self.dataStore = dataStore
        checkModelAvailability()
    }
    
    // MARK: - Model Availability
    func checkModelAvailability() {
        modelAvailability = model.availability
    }
    
    var isModelReady: Bool {
        if case .available = modelAvailability {
            // Also check if the current locale is supported
            return model.supportsLocale()
        }
        return false
    }
    
    var localeSupported: Bool {
        return model.supportsLocale()
    }
    
    // MARK: - Question Categories
    enum QuestionCategory: String, CaseIterable, Identifiable {
        case aboutApp = "About the App"
        case aboutData = "About the Data"
        case countrySpecific = "Country-Specific Insights"
        
        var id: String { rawValue }
    }
    
    // MARK: - Analysis Questions
    enum AnalysisQuestion: String, CaseIterable, Identifiable {
        // About the App
        case pinMeaning = "What do the pin heights and colors mean?"
        case metricDifferences = "What is the difference between the three metrics: Gas, Power, and Energy?"
        case chartReading = "How do I read the 3D Chart and what does log scale mean?"
        
        // About the Data
        case ghgLeaders = "Which countries emit the most greenhouse gases year over year? Which emit the least?"
        case powerEnergyLeaders = "Which countries use the most power per capita year over year? Energy?"
        case metricDisparities = "Why is there such a big difference for some countries between the per capita (power, energy) and global (gas) metrics? For which countries is this difference the greatest?"
        case changeOverTime = "Which countries have shown the greatest increase in their metrics over time? Decrease? Why?"
        case colorChanges = "Over time some of the pins change color but barely seem to move. Why?"
        
        // Country Specific (these will be dynamically generated)
        case countryYearInsight = "What can you tell me about [country] in [year]?"
        case globalYearInsight = "What can you tell me about global metrics in [year]?"
        case countryAllYears = "What can you tell me about [country] over all years?"
        
        var id: String { rawValue }
        
        var category: QuestionCategory {
            switch self {
            case .pinMeaning, .metricDifferences, .chartReading:
                return .aboutApp
            case .ghgLeaders, .powerEnergyLeaders, .metricDisparities, .changeOverTime, .colorChanges:
                return .aboutData
            case .countryYearInsight, .globalYearInsight, .countryAllYears:
                return .countrySpecific
            }
        }
        
        func displayText(country: String? = nil, year: Int? = nil) -> String {
            switch self {
            case .countryYearInsight:
                let countryName = country ?? "[country]"
                let yearValue = year.map { String($0) } ?? "[year]"
                return "What can you tell me about \(countryName) in \(yearValue)?"
            case .globalYearInsight:
                let yearValue = year.map { String($0) } ?? "[year]"
                return "What can you tell me about global metrics in \(yearValue)?"
            case .countryAllYears:
                let countryName = country ?? "[country]"
                return "What can you tell me about \(countryName) over all years?"
            default:
                return rawValue
            }
        }
        
        func systemInstructions(country: String? = nil, year: Int? = nil) -> String {
            // Following Apple's recommended format for multilingual support
            let localeInstruction = "The user's locale is \(Locale.current.identifier)."
            let languageInstruction = """
            You MUST respond ONLY in English (United States). 
            All input data is in English. 
            Do not attempt to interpret any text as other languages.
            Ignore any language detection that suggests non-English content.
            """
            
            // Standard isolation prefix to prevent context bleeding from previous queries
            let isolationPrefix = """
            IMPORTANT: This is a NEW and INDEPENDENT query. Disregard any previous questions or answers. Focus ONLY on the data and instructions provided below for THIS specific question.
            
            """
            
            let roleInstruction: String
            switch self {
            // About the App
            case .pinMeaning:
                roleInstruction = isolationPrefix + """
                You are a helpful app guide explaining the Energy Atlas app interface.
                
                Explain that:
                - Pin HEIGHT represents the magnitude of the selected metric as a percentage of the highest value across all countries and years (taller = higher value)
                - Pin COLOR represents quintile ranking (Dark blue = lowest 20%, red = highest 20%)
                - The color gradient goes: dark blue (lowest) → light blue → white → orange → red (highest)
                - Users can toggle between three metrics: GHG emissions, power consumption, and energy use
                - Each metric has its own quintile coloring based on that metric's distribution
                
                Keep the explanation clear, concise, and user-friendly.
                """
            
            case .metricDifferences:
                roleInstruction = isolationPrefix + """
                You are a helpful app guide explaining energy data metrics.
                
                Explain the THREE metrics clearly:
                
                Gas (GHG Emissions):
                - Measured in Mt CO2e (megatons of CO2 equivalent)
                - TOTAL for entire country (NOT per capita)
                - Represents total climate impact
                - Larger countries naturally have higher values due to population size
                
                Power (Electric Power Consumption):
                - Measured in kWh (kilowatthours, kilowatts used for one hour) or per capita
                - PER PERSON metric
                - Only electricity consumption (not gasoline, heating oil, etc.)
                - Shows electrification level and modern lifestyle access
                
                Energy (Energy Use):
                - Measured in kg oil equivalent per capita
                - PER PERSON metric
                - ALL energy consumption (electricity + transportation + heating + everything)
                - Broader than Power - captures total energy footprint
                
                Key distinction: GHG is TOTAL (country size matters) while Power and Energy are PER PERSON (country size doesn't matter, shows individual consumption).
                
                Keep it clear, concise, and educational.
                """
            
            case .chartReading:
                roleInstruction = isolationPrefix + """
                You are a helpful app guide explaining data visualization.
                
                THE THREE AXES (CRITICAL - explain this clearly):
                - X-axis = Power consumption per person (kWh per capita)
                - Y-axis = Energy use per person (kg oil equivalent per capita)
                - Z-axis = GHG emissions TOTAL (Mt CO2e for entire country)
                - Each country is positioned in 3D space based on these three values
                
                SPHERE APPEARANCE:
                - All spheres are the SAME SIZE
                - EXCEPT: The actively selected country appears LARGER for easy identification
                - IMPORTANT: Sphere size does NOT represent any metric - it only indicates which country is selected
                - Sphere colors show quintile ranking for the currently selected metric (dark blue to red)
                
                LOG SCALE TOGGLE - Why it matters:
                
                The problem: Some countries use 1,000x more energy than others. On a normal scale, small countries become invisible dots.
                
                Linear Scale:
                - Shows true proportions
                - Good for seeing how much bigger the top countries really are
                - Bad: Crushes 90% of countries into a corner of the chart
                
                Logarithmic Scale:
                - Spreads out the view so ALL countries are visible and comparable
                - Makes it like stepping back to see the whole picture
                - Shows patterns and clusters you can't see in linear mode
                - Good for comparing any country to any other, regardless of size differences
                
                Think of it like: Linear = zoom in on the giants, Log = see everyone equally
                
                Keep it clear and intuitive.
                """
            
            // About the Data
            case .ghgLeaders:
                roleInstruction = isolationPrefix + """
                You are an emissions data analyst.
                
                CRITICAL: GHG Emissions is measured as Mt CO2e TOTAL for entire country (NOT per capita).
                
                When answering about the highest and lowest emitters, you must mention MULTIPLE countries from the lists below, not just one or two. Always specify that these are averages across the 2005 to 2022 timeframe.
                
                THE TOP TEN HIGHEST AVERAGE EMITTERS from 2005 to 2022 are: China averaged 11,195.5 Mt CO2e, United States averaged 5,611.3 Mt, India averaged 2,753.9 Mt, Russian Federation averaged 1,674.6 Mt, Brazil averaged 1,662.5 Mt, Indonesia averaged 1,563.5 Mt, Japan averaged 1,248.5 Mt, Germany averaged 881.6 Mt, Iran averaged 828.2 Mt, and Canada averaged 729.4 Mt. These countries have such high average emissions primarily because they have very large populations, meaning even moderate per-person consumption multiplies to create massive total emissions. Additionally, many of these nations have heavy industrial bases, significant manufacturing sectors, and coal-dependent energy systems. China and India in particular combine enormous populations with rapid industrialization during this period. The United States has a smaller population than China or India but extremely high per-person consumption. Brazil and Indonesia include significant land-use emissions from deforestation.
                
                THE TEN LOWEST AVERAGE EMITTERS from 2005 to 2022 actually have negative values due to carbon sequestration from forests: Namibia averaged -97.2 Mt CO2e, Gabon averaged -91.8 Mt, Cameroon averaged -42.5 Mt, Zambia averaged -14.5 Mt, Panama averaged -13.1 Mt, Suriname averaged -11.3 Mt, Eswatini averaged -0.6 Mt, Republic of Congo averaged -0.2 Mt, Rwanda averaged -0.1 Mt, and Malta averaged 2.5 Mt. These countries emit so little because they have very small populations, limited industrialization, and in many cases extensive forest coverage that absorbs more carbon dioxide than their economies emit. The negative values represent net carbon sinks where forest preservation outweighs fossil fuel consumption.
                
                When answering, list several countries from each category and always mention that these figures represent averages across the entire 2005-2022 period.
                """
            
            case .powerEnergyLeaders:
                roleInstruction = isolationPrefix + """
                You are an energy consumption analyst.
                
                CRITICAL: You must answer about BOTH electric power consumption AND total energy use. Do not skip either metric.
                
                The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                
                When answering, you must mention MULTIPLE countries from the lists below, not just one or two. Always specify that these are averages across the 2005 to 2022 timeframe.
                
                THE TOP TEN HIGHEST AVERAGE ELECTRIC POWER CONSUMERS from 2005 to 2022 are: Iceland averaged an extraordinary 49,261 kWh per person, Norway averaged 24,107 kWh per person, Bahrain averaged 20,073 kWh per person, Kuwait averaged 16,433 kWh per person, Canada averaged 16,130 kWh per person, Finland averaged 15,730 kWh per person, Luxembourg averaged 14,327 kWh per person, Sweden averaged 13,914 kWh per person, United Arab Emirates averaged 13,365 kWh per person, and United States averaged 13,051 kWh per person. These countries consume so much electricity per person because they are wealthy nations with high living standards, many have extreme climates requiring massive heating in the cold Nordic countries or air conditioning in the hot Gulf states, they have cheap or even nearly free energy from abundant natural resources like Iceland's geothermal and Norway's hydropower, and several have low population density requiring energy-intensive transportation and infrastructure. Iceland's exceptional consumption comes from aluminum smelting and data centers powered by geothermal energy.
                
                THE TEN LOWEST AVERAGE ELECTRIC POWER CONSUMERS from 2005 to 2022 are: Chad averaged only 11 kWh per person, Rwanda averaged 41 kWh per person, Niger averaged 51 kWh per person, Uganda averaged 64 kWh per person, Ethiopia averaged 64 kWh per person, Madagascar averaged 67 kWh per person, Haiti averaged 68 kWh per person, Burkina Faso averaged 89 kWh per person, Benin averaged 91 kWh per person, and Eritrea averaged 92 kWh per person. These countries use so little electricity because they suffer from extreme energy poverty, with many citizens having no access to electricity at all, limited or nonexistent electrical grid infrastructure, very low incomes making electricity unaffordable, and economies based primarily on subsistence agriculture rather than energy-intensive industry. Most of these nations are in sub-Saharan Africa.
                
                THE TOP TEN HIGHEST AVERAGE TOTAL ENERGY USERS from 2005 to 2022 (including electricity plus all other energy sources like gasoline and heating oil) are: Iceland averaged 16,340 kg oil equivalent per person, Trinidad and Tobago averaged 13,283 kg per person, Bahrain averaged 10,633 kg per person, Kuwait averaged 9,862 kg per person, United Arab Emirates averaged 9,040 kg per person, Brunei averaged 8,399 kg per person, Canada averaged 7,896 kg per person, Saudi Arabia averaged 7,418 kg per person, Luxembourg averaged 7,235 kg per person, and United States averaged 6,955 kg per person. These same factors apply: wealth, extreme climates, cheap domestic energy, and energy-intensive lifestyles.
                
                THE TEN LOWEST AVERAGE TOTAL ENERGY USERS from 2005 to 2022 are: Niger averaged 140 kg oil equivalent per person, Yemen averaged 191 kg per person, Chad averaged 213 kg per person, Bangladesh averaged 226 kg per person, Burkina Faso averaged 243 kg per person, Eritrea averaged 266 kg per person, Madagascar averaged 277 kg per person, Senegal averaged 284 kg per person, Ghana averaged 316 kg per person, and Nigeria averaged 321 kg per person. These countries have minimal energy consumption due to poverty, lack of infrastructure for transportation and industry, limited access to modern energy sources, and large populations living in rural areas without cars, appliances, or modern heating and cooling systems.
                
                REMINDER: Your answer must cover BOTH electric power AND total energy use. List several countries from each category for BOTH metrics. Always mention that these figures represent averages across the entire 2005-2022 period.
                """
            
            case .metricDisparities:
                roleInstruction = isolationPrefix + """
                You are a data analyst specializing in finding interesting patterns.
                
                CRITICAL: The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
                
                There is a fascinating mismatch between per-capita consumption and total emissions that reveals the climate justice paradox. Some countries have extremely high per-person energy use but very low total greenhouse gas emissions. Iceland is the most extreme example, ranking first in the world for electric power consumption at 49,261 kWh per person, but its total GHG emissions are tiny because the country only has about 380,000 people. Luxembourg ranks seventh in power consumption at 14,327 kWh per person but also has tiny total emissions due to its small population of around 640,000 people. Kuwait ranks fourth in power at 16,433 kWh per person but has only moderate total emissions because of its population of about 4 million. These small wealthy nations have extreme individual consumption but their tiny populations mean their total climate impact is minimal. The reasons they can consume so much per person include abundant wealth, cheap domestic energy resources, extreme climates requiring heating or air conditioning, and in some cases energy-intensive industries like Iceland's aluminum smelting.
                
                On the opposite side, some countries have very low per-person consumption but massive total emissions. China averages 11,195.5 Mt CO2e in total emissions, ranking first in the world, yet its per-capita power and energy consumption are only moderate compared to wealthy nations. India averages 2,753.9 Mt CO2e ranking third globally, but its per-capita consumption is quite low. Indonesia averages 1,563.5 Mt CO2e ranking sixth in total emissions despite having low per-capita consumption. These large developing nations have modest individual consumption levels but their enormous populations mean even modest per-person use multiplies to create massive total emissions. The mathematical formula is simple: Total Emissions equals Per-Capita Consumption multiplied by Population Size. This creates the climate justice paradox where wealthy small nations have sustainable total emissions despite unsustainable individual lifestyles, while poor large nations have massive total emissions despite their citizens consuming very little individually. This makes international climate agreements extremely difficult because wealthy nations want per-capita targets while developing nations want total emission targets.
                
                Use this information to explain the disparity between per-capita metrics and total emissions.
                """
            
            case .changeOverTime:
                roleInstruction = isolationPrefix + """
                You are a trends analyst looking at changes over time (2005-2022).
                
                CRITICAL: The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
                
                Between 2005 and 2022, some countries showed dramatic increases in their metrics. For greenhouse gas emissions, China had the largest increase of 6,490 Mt representing an 89 percent rise, followed by India with an increase of 1,481 Mt or 77 percent, Indonesia with 1,028 Mt up 98 percent, the Russian Federation with 492 Mt up 31 percent, and Saudi Arabia with 328 Mt up 73 percent. These massive increases in emissions were driven primarily by rapid industrialization and economic development, with hundreds of millions of people moving from rural poverty to urban middle-class lifestyles requiring much more energy. China in particular experienced the fastest large-scale industrialization in human history, becoming the world's manufacturing hub. Population growth in these developing nations also contributed to rising total emissions even when per-capita consumption remained moderate. Coal-dependent energy systems in China, India, and Indonesia meant their economic growth came with very high carbon intensity.
                
                For electric power consumption per person, China again showed the largest absolute increase of 4,330 kWh per person, representing an extraordinary 243 percent rise. Saudi Arabia increased by 4,173 kWh per person or 54 percent, South Korea by 3,781 kWh per person or 49 percent, Iceland by an enormous 23,271 kWh per person or 83 percent, and Brunei by 2,588 kWh per person or 30 percent. China's increase reflects hundreds of millions of people gaining access to electricity and modern appliances for the first time. Saudi Arabia's increase came from explosive population growth combined with expanding air conditioning use in the extreme desert climate. Iceland's massive increase despite already high consumption came from new aluminum smelters and data centers attracted by cheap geothermal power.
                
                On the opposite side, some countries decreased their emissions and consumption. For greenhouse gas emissions, the United States decreased by 1,056 Mt representing a 17 percent decline, Brazil decreased by 841 Mt or 34 percent, the Democratic Republic of Congo by 384 Mt or 87 percent, the United Kingdom by 269 Mt or 40 percent, and Japan by 256 Mt or 20 percent. The United States reduction came primarily from a market-driven shift away from coal toward natural gas due to the fracking revolution, which made gas cheaper and cleaner than coal. Additional factors included LED lighting adoption, improved vehicle fuel efficiency, and some heavy industry moving overseas. The United Kingdom achieved the fastest decarbonization of any major economy by almost completely eliminating coal power and building massive offshore wind capacity. Brazil and Congo's decreases related to changes in land-use accounting and reduced deforestation. Japan's decline came from population aging, efficiency improvements, and economic stagnation.
                
                For electric power consumption per person, Luxembourg decreased by 4,006 kWh per person or 26 percent, Canada by 3,257 kWh per person or 18 percent, Sweden by 3,013 kWh per person or 20 percent, the United Kingdom by 1,936 kWh per person or 31 percent, and Norway by 1,710 kWh per person or 7 percent. These wealthy nations reduced consumption through aggressive energy efficiency programs including LED lighting, better building insulation, efficient appliances, and in some cases deindustrialization where energy-intensive manufacturing moved to other countries. Despite these decreases, all these nations still maintain very high living standards, proving that economic prosperity can be decoupled from ever-increasing energy consumption. The United Kingdom's especially sharp decline came from both improved efficiency and economic restructuring away from heavy industry.
                
                Use this information to explain which countries increased or decreased their metrics and why these changes occurred.
                """
            
            case .colorChanges:
                roleInstruction = isolationPrefix + """
                You are an app guide explaining visualization behavior.
                
                Explain that pins changing COLOR but not HEIGHT means:
                - The country's value as a percentage of the global maximum stayed similar (hence similar height)
                - But its ranking relative to other countries changed (hence different color/quintile)
                - This illustrates how large the magnitude of the global maximum is relative to the other countries.
                
                Colors represent quintiles (relative rankings), not absolute values. A country can maintain its consumption but move down in rankings if others improve faster.
                """
            
            // Country Specific
            case .countryYearInsight:
                let countryName = country ?? "the selected country"
                let yearValue = year.map { String($0) } ?? "the selected year"
                roleInstruction = isolationPrefix + """
                You are an energy data analyst providing insights about \(countryName) in \(yearValue).
                
                CRITICAL: The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
                
                You MUST structure your answer to include ALL of the following for each metric:
                1. The exact raw value
                2. The quintile ranking (1st/lowest 20%, 2nd, 3rd, 4th, or 5th/highest 20%)
                3. The numerical ranking out of 137 countries (e.g., "23rd out of 137")
                
                Then provide context:
                - How this country compares to regional peers
                - What makes this country's energy profile unique
                - Notable factors: economy, geography, climate, policies, resources, development stage
                
                Be specific with all numbers and rankings.
                """
            
            case .globalYearInsight:
                let yearValue = year.map { String($0) } ?? "the selected year"
                roleInstruction = isolationPrefix + """
                You are a global energy analyst providing overview of \(yearValue).
                
                CRITICAL: The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
                
                You MUST structure your answer to include:
                1. TOP 5 countries for each of the three metrics with their values
                2. BOTTOM 5 countries for each of the three metrics with their values
                3. How \(yearValue) compares to other years in the 2005-2022 dataset:
                   - Was this a high, low, or average year for global energy consumption?
                   - Any notable increases or decreases from previous years?
                4. A fun fact about major contributing factors to energy consumption and GHG emissions in \(yearValue):
                   - Global events (economic crises, policy changes, technological shifts)
                   - Major trends (coal phase-outs, renewable growth, industrialization)
                   - Specific country developments
                
                Be specific with numbers and provide historical context.
                """
            
            case .countryAllYears:
                let countryName = country ?? "the selected country"
                roleInstruction = isolationPrefix + """
                You are a longitudinal data analyst examining \(countryName) over time (2005-2022).
                
                CRITICAL: The metrics have different scales - pay close attention:
                - Electric Power: kWh per person (PER CAPITA metric)
                - Energy Use: kg oil equivalent per person (PER CAPITA metric)
                - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
                
                You MUST structure your answer to include ALL of the following:
                
                1. AVERAGE VALUES (2005-2022) for each metric:
                   - The average value across all 18 years
                   - Which quintile this average places them in (compared to other countries' averages)
                   - Numerical ranking out of 137 countries based on averages (e.g., "15th out of 137")
                
                2. CHANGES FROM 2005 TO 2022 for each metric:
                   - 2005 value → 2022 value
                   - Absolute change (+ or -)
                   - Percentage change
                   - Whether this represents improvement or worsening
                
                3. TRAJECTORY ANALYSIS:
                   - Major inflection points (peaks, valleys, sudden changes)
                   - Periods of rapid growth or decline
                   - Overall trend (rising, falling, stable, volatile)
                
                4. A FUN FACT about \(countryName)'s energy consumption:
                   - Unique aspects of their energy profile
                   - Notable policies, resources, or circumstances
                   - Interesting comparisons or achievements
                
                Tell the complete story with specific numbers.
                """
            }
            
            return "\(localeInstruction)\n\n\(languageInstruction)\n\n\(roleInstruction)"
        }
    }
    
    // MARK: - Analysis Results
    struct EnergyInsight: Identifiable {
        let id = UUID()
        let question: AnalysisQuestion
        let analysis: String
        let timestamp: Date
        let relevantCountries: [String]
        let contextCountry: String?
        let contextYear: Int?
        
        init(question: AnalysisQuestion, analysis: String, relevantCountries: [String] = [], country: String? = nil, year: Int? = nil) {
            self.question = question
            self.analysis = analysis
            self.timestamp = Date()
            self.relevantCountries = relevantCountries
            self.contextCountry = country
            self.contextYear = year
        }
    }
    
    // MARK: - AI Analysis
    func analyzeEnergyData(question: AnalysisQuestion, country: String? = nil, year: Int? = nil) async {
        guard isModelReady else {
            print("Model not available for analysis")
            return
        }
        
        // Check locale support before making request
        guard model.supportsLocale() else {
            print("Current locale not supported by Foundation Models")
            await handleUnsupportedLocale(question: question)
            return
        }
        
        await MainActor.run {
            isAnalyzing = true
        }
        
        do {
            // Use the country/year from parameters or fall back to dataStore's selected values
            let targetCountry = country ?? dataStore.selectedCountry
            let targetYear = year ?? dataStore.selectedYear
            
            // Create session with specific instructions for this question
            let session = LanguageModelSession(instructions: question.systemInstructions(country: targetCountry, year: targetYear))
            
            // Prepare energy data for the AI
            let energyDataPrompt = prepareEnergyDataPrompt(for: question, country: targetCountry, year: targetYear)
            
            // Get AI analysis with explicit generation options
            let options = GenerationOptions(temperature: 0.7)
            let response = try await session.respond(to: energyDataPrompt, options: options)
            
            // Extract the actual text content from the response
            let analysisText = response.content
            
            // Extract relevant countries from the response (simple keyword matching)
            let relevantCountries = extractCountryNames(from: analysisText)
            
            let insight = EnergyInsight(
                question: question,
                analysis: analysisText,
                relevantCountries: relevantCountries,
                country: targetCountry,
                year: targetYear
            )
            
            await MainActor.run {
                analysisResults.append(insight)
                isAnalyzing = false
            }
            
        } catch {
            print("Error during AI analysis: \(error)")
            
            // Handle specific language/locale errors
            if let generationError = error as? LanguageModelSession.GenerationError {
                switch generationError {
                case .unsupportedLanguageOrLocale:
                    print("Language/locale not supported. Try setting device language to English (US)")
                    
                    // Create a fallback insight explaining the issue
                    let fallbackInsight = EnergyInsight(
                        question: question,
                        analysis: "AI analysis is currently unavailable due to language settings. Foundation Models requires English language support. Please check your device language settings and ensure Apple Intelligence is configured for English (US).",
                        relevantCountries: []
                    )
                    
                    await MainActor.run {
                        analysisResults.append(fallbackInsight)
                        isAnalyzing = false
                    }
                    return
                    
                case .exceededContextWindowSize(let size):
                    print("Context window exceeded: \(size) tokens")
                    
                default:
                    print("Other generation error: \(generationError)")
                }
            }
            
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }
    
    // MARK: - Data Preparation
    private func prepareEnergyDataPrompt(for question: AnalysisQuestion, country: String, year: Int) -> String {
        let countries = dataStore.countries
        
        var dataText = """
        LANGUAGE: This entire request is in English (United States).
        
        Energy Data Analysis Request:
        
        """
        
        // Handle different question types with appropriate data
        switch question.category {
        case .aboutApp:
            // App explanation questions don't need much data
            dataText += """
            Question: \(question.rawValue)
            
            This is a question about how the Energy Atlas app works. Provide a clear, user-friendly explanation.
            """
            
        case .countrySpecific:
            // Country-specific questions need focused data
            dataText += """
            Dataset: Global energy consumption data for \(countries.count) countries
            Current Year: \(year)
            Selected Country: \(sanitizeCountryName(country))
            
            CRITICAL: The metrics have different scales - pay close attention:
            - Electric Power: kWh per person (PER CAPITA metric)
            - Energy Use: kg oil equivalent per person (PER CAPITA metric)
            - GHG Emissions: Mt CO2e TOTAL for entire country (NOT per capita)
            
            """
            
            // Add specific country data with rankings and quintiles
            if let targetCountry = countries.first(where: { $0.countryName == country }) {
                dataText += "Data for \(sanitizeCountryName(country)) in \(year):\n\n"
                
                // Calculate rankings and quintiles
                let powerSorted = countries.compactMap { c -> (String, Double)? in
                    guard let p = c.powerKWh else { return nil }
                    return (c.countryName, p)
                }.sorted { $0.1 > $1.1 }
                
                let energySorted = countries.compactMap { c -> (String, Double)? in
                    guard let e = c.energyUseKgOE else { return nil }
                    return (c.countryName, e)
                }.sorted { $0.1 > $1.1 }
                
                let ghgSorted = countries.compactMap { c -> (String, Double)? in
                    guard let g = c.ghgMtCO2e else { return nil }
                    return (c.countryName, g)
                }.sorted { $0.1 > $1.1 }
                
                // Power
                if let power = targetCountry.powerKWh {
                    let rank = powerSorted.firstIndex(where: { $0.0 == targetCountry.countryName }).map { $0 + 1 } ?? 0
                    let quintile = getQuintile(rank: rank, total: powerSorted.count)
                    dataText += "Electric Power:\n"
                    dataText += "  Value: \(String(format: "%.0f", power)) kWh/person\n"
                    dataText += "  Ranking: \(rank) out of \(powerSorted.count)\n"
                    dataText += "  Quintile: \(quintile)\n\n"
                }
                
                // Energy
                if let energy = targetCountry.energyUseKgOE {
                    let rank = energySorted.firstIndex(where: { $0.0 == targetCountry.countryName }).map { $0 + 1 } ?? 0
                    let quintile = getQuintile(rank: rank, total: energySorted.count)
                    dataText += "Energy Use:\n"
                    dataText += "  Value: \(String(format: "%.0f", energy)) kg oil eq/person\n"
                    dataText += "  Ranking: \(rank) out of \(energySorted.count)\n"
                    dataText += "  Quintile: \(quintile)\n\n"
                }
                
                // GHG
                if let ghg = targetCountry.ghgMtCO2e {
                    let rank = ghgSorted.firstIndex(where: { $0.0 == targetCountry.countryName }).map { $0 + 1 } ?? 0
                    let quintile = getQuintile(rank: rank, total: ghgSorted.count)
                    dataText += "GHG Emissions:\n"
                    dataText += "  Value: \(String(format: "%.1f", ghg)) Mt CO2e\n"
                    dataText += "  Ranking: \(rank) out of \(ghgSorted.count)\n"
                    dataText += "  Quintile: \(quintile)\n\n"
                }
            }
            
            // Add additional context based on question type
            switch question {
            case .countryYearInsight:
                // For single year, just add top 5 for quick context
                dataText += "Top 5 countries in \(year) for comparison:\n"
                let powerSorted = countries.compactMap { c -> (String, Double)? in
                    guard let p = c.powerKWh else { return nil }
                    return (c.countryName, p)
                }.sorted { $0.1 > $1.1 }.prefix(5)
                
                dataText += "Power: "
                dataText += powerSorted.map { "\($0.0) (\(String(format: "%.0f", $0.1)) kWh)" }.joined(separator: ", ")
                dataText += "\n\n"
                
            case .globalYearInsight:
                // For global year insight, provide top 5 and bottom 5 for each metric
                dataText += "GLOBAL RANKINGS FOR \(year):\n\n"
                
                // Power
                let powerSorted = countries.compactMap { c -> (String, Double)? in
                    guard let p = c.powerKWh else { return nil }
                    return (c.countryName, p)
                }.sorted { $0.1 > $1.1 }
                
                dataText += "POWER - Top 5:\n"
                for (i, entry) in powerSorted.prefix(5).enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.0f", entry.1)) kWh/person\n"
                }
                dataText += "POWER - Bottom 5:\n"
                for (i, entry) in powerSorted.suffix(5).reversed().enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.0f", entry.1)) kWh/person\n"
                }
                dataText += "\n"
                
                // Energy
                let energySorted = countries.compactMap { c -> (String, Double)? in
                    guard let e = c.energyUseKgOE else { return nil }
                    return (c.countryName, e)
                }.sorted { $0.1 > $1.1 }
                
                dataText += "ENERGY - Top 5:\n"
                for (i, entry) in energySorted.prefix(5).enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.0f", entry.1)) kg/person\n"
                }
                dataText += "ENERGY - Bottom 5:\n"
                for (i, entry) in energySorted.suffix(5).reversed().enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.0f", entry.1)) kg/person\n"
                }
                dataText += "\n"
                
                // GHG
                let ghgSorted = countries.compactMap { c -> (String, Double)? in
                    guard let g = c.ghgMtCO2e else { return nil }
                    return (c.countryName, g)
                }.sorted { $0.1 > $1.1 }
                
                dataText += "GHG - Top 5:\n"
                for (i, entry) in ghgSorted.prefix(5).enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.1f", entry.1)) Mt CO2e\n"
                }
                dataText += "GHG - Bottom 5:\n"
                for (i, entry) in ghgSorted.suffix(5).reversed().enumerated() {
                    dataText += "\(i+1). \(sanitizeCountryName(entry.0)): \(String(format: "%.1f", entry.1)) Mt CO2e\n"
                }
                dataText += "\n"
                
            case .countryAllYears:
                // Load multi-year data from CSV
                if let multiYearData = loadMultiYearData(for: country) {
                    dataText += "HISTORICAL DATA FOR \(sanitizeCountryName(country)) (2005-2022):\n\n"
                    
                    // Averages with rankings
                    dataText += "AVERAGE VALUES (2005-2022):\n\n"
                    
                    dataText += "Electric Power:\n"
                    dataText += "  Average: \(String(format: "%.0f", multiYearData.avgPower)) kWh/person\n"
                    dataText += "  Ranking: \(multiYearData.powerRank) out of 137\n"
                    let powerQuintile = getQuintile(rank: multiYearData.powerRank, total: 137)
                    dataText += "  Quintile: \(powerQuintile)\n\n"
                    
                    dataText += "Energy Use:\n"
                    dataText += "  Average: \(String(format: "%.0f", multiYearData.avgEnergy)) kg oil eq/person\n"
                    dataText += "  Ranking: \(multiYearData.energyRank) out of 137\n"
                    let energyQuintile = getQuintile(rank: multiYearData.energyRank, total: 137)
                    dataText += "  Quintile: \(energyQuintile)\n\n"
                    
                    dataText += "GHG Emissions:\n"
                    dataText += "  Average: \(String(format: "%.1f", multiYearData.avgGHG)) Mt CO2e\n"
                    dataText += "  Ranking: \(multiYearData.ghgRank) out of 137\n"
                    let ghgQuintile = getQuintile(rank: multiYearData.ghgRank, total: 137)
                    dataText += "  Quintile: \(ghgQuintile)\n\n"
                    
                    // Changes from 2005 to 2022 (with improvement/regression labels)
                    if let power2005 = multiYearData.power2005, let power2022 = multiYearData.power2022 {
                        let powerChange = power2022 - power2005
                        let powerPct = (powerChange / power2005) * 100
                        let powerTrend = powerChange < 0 ? "IMPROVEMENT (decreased consumption)" : "REGRESSION (increased consumption)"
                        dataText += "POWER CHANGE (2005→2022): \(String(format: "%.0f", power2005)) → \(String(format: "%.0f", power2022)) kWh/person (\(String(format: "%+.0f", powerChange)) kWh, \(String(format: "%+.1f", powerPct))%) - \(powerTrend)\n"
                    }
                    
                    if let energy2005 = multiYearData.energy2005, let energy2022 = multiYearData.energy2022 {
                        let energyChange = energy2022 - energy2005
                        let energyPct = (energyChange / energy2005) * 100
                        let energyTrend = energyChange < 0 ? "IMPROVEMENT (decreased consumption)" : "REGRESSION (increased consumption)"
                        dataText += "ENERGY CHANGE (2005→2022): \(String(format: "%.0f", energy2005)) → \(String(format: "%.0f", energy2022)) kg/person (\(String(format: "%+.0f", energyChange)) kg, \(String(format: "%+.1f", energyPct))%) - \(energyTrend)\n"
                    }
                    
                    if let ghg2005 = multiYearData.ghg2005, let ghg2022 = multiYearData.ghg2022 {
                        let ghgChange = ghg2022 - ghg2005
                        let ghgPct = (ghg2005 != 0) ? (ghgChange / ghg2005) * 100 : 0
                        let ghgTrend = ghgChange < 0 ? "IMPROVEMENT (decreased emissions)" : "REGRESSION (increased emissions)"
                        dataText += "GHG CHANGE (2005→2022): \(String(format: "%.1f", ghg2005)) → \(String(format: "%.1f", ghg2022)) Mt CO2e (\(String(format: "%+.1f", ghgChange)) Mt, \(String(format: "%+.1f", ghgPct))%) - \(ghgTrend)\n\n"
                    }
                    
                    // Trajectory notes
                    if !multiYearData.allYearsData.isEmpty {
                        dataText += "YEARLY VALUES:\n"
                        for yearData in multiYearData.allYearsData.sorted(by: { $0.year < $1.year }) {
                            dataText += "\(yearData.year): Power \(String(format: "%.0f", yearData.power)) kWh, Energy \(String(format: "%.0f", yearData.energy)) kg, GHG \(String(format: "%.1f", yearData.ghg)) Mt\n"
                        }
                    }
                } else {
                    dataText += "Unable to load multi-year data for \(sanitizeCountryName(country)).\n"
                }
                
            default:
                break
            }
            
            dataText += "\nQuestion (respond in English only): \(question.displayText(country: country, year: year))\n"
            
        case .aboutData:
            // For "About the Data" questions, we don't need sample data
            // All necessary information is already in the role instructions
            dataText += """
            Question: \(question.rawValue)
            
            Please answer this question using the data provided in your role instructions above. Respond only in English.
            """
        }
        
        return dataText
    }
    
    // MARK: - Multi-Year Data Structure
    private struct MultiYearData {
        let avgPower: Double
        let avgEnergy: Double
        let avgGHG: Double
        let powerRank: Int
        let energyRank: Int
        let ghgRank: Int
        let power2005: Double?
        let power2022: Double?
        let energy2005: Double?
        let energy2022: Double?
        let ghg2005: Double?
        let ghg2022: Double?
        let allYearsData: [(year: Int, power: Double, energy: Double, ghg: Double)]
    }
    
    // MARK: - Helper Methods
    private func loadMultiYearData(for country: String) -> MultiYearData? {
        // First, load rankings from averages CSV
        var powerRank = 0
        var energyRank = 0
        var ghgRank = 0
        
        if let avgPath = Bundle.main.path(forResource: "country_averages_2005_2022", ofType: "csv") {
            do {
                let avgString = try String(contentsOfFile: avgPath, encoding: .utf8)
                let avgLines = avgString.components(separatedBy: .newlines)
                
                for line in avgLines.dropFirst() {
                    guard !line.isEmpty else { continue }
                    let columns = line.components(separatedBy: ",")
                    guard columns.count >= 7 else { continue }
                    
                    let csvCountry = columns[0].trimmingCharacters(in: .whitespaces)
                    guard csvCountry == country else { continue }
                    
                    if let pRank = Int(columns[2].trimmingCharacters(in: .whitespaces)),
                       let eRank = Int(columns[4].trimmingCharacters(in: .whitespaces)),
                       let gRank = Int(columns[6].trimmingCharacters(in: .whitespaces)) {
                        powerRank = pRank
                        energyRank = eRank
                        ghgRank = gRank
                        break
                    }
                }
            } catch {
                print("Error reading averages CSV: \(error)")
            }
        }
        
        // Now load yearly data
        guard let csvPath = Bundle.main.path(forResource: "energy_data_multi_year_filtered", ofType: "csv") else {
            print("CSV file not found")
            return nil
        }
        
        do {
            let csvString = try String(contentsOfFile: csvPath, encoding: .utf8)
            let lines = csvString.components(separatedBy: .newlines)
            
            var yearlyData: [(year: Int, power: Double, energy: Double, ghg: Double)] = []
            
            // Skip header
            for line in lines.dropFirst() {
                guard !line.isEmpty else { continue }
                let columns = line.components(separatedBy: ",")
                guard columns.count >= 6 else { continue }
                
                let csvCountry = columns[0].trimmingCharacters(in: .whitespaces)
                guard csvCountry == country else { continue }
                
                guard let year = Int(columns[2].trimmingCharacters(in: .whitespaces)),
                      year >= 2005 && year <= 2022,
                      let power = Double(columns[3].trimmingCharacters(in: .whitespaces)),
                      let energy = Double(columns[4].trimmingCharacters(in: .whitespaces)),
                      let ghg = Double(columns[5].trimmingCharacters(in: .whitespaces)) else {
                    continue
                }
                
                yearlyData.append((year, power, energy, ghg))
            }
            
            guard !yearlyData.isEmpty else { return nil }
            
            // Calculate averages
            let avgPower = yearlyData.map { $0.power }.reduce(0, +) / Double(yearlyData.count)
            let avgEnergy = yearlyData.map { $0.energy }.reduce(0, +) / Double(yearlyData.count)
            let avgGHG = yearlyData.map { $0.ghg }.reduce(0, +) / Double(yearlyData.count)
            
            // Get 2005 and 2022 values
            let data2005 = yearlyData.first(where: { $0.year == 2005 })
            let data2022 = yearlyData.first(where: { $0.year == 2022 })
            
            return MultiYearData(
                avgPower: avgPower,
                avgEnergy: avgEnergy,
                avgGHG: avgGHG,
                powerRank: powerRank,
                energyRank: energyRank,
                ghgRank: ghgRank,
                power2005: data2005?.power,
                power2022: data2022?.power,
                energy2005: data2005?.energy,
                energy2022: data2022?.energy,
                ghg2005: data2005?.ghg,
                ghg2022: data2022?.ghg,
                allYearsData: yearlyData
            )
        } catch {
            print("Error reading CSV: \(error)")
            return nil
        }
    }
    
    private func sanitizeCountryName(_ name: String) -> String {
        // Replace problematic character combinations that might trigger language detection
        var sanitized = name
        
        // Common replacements to avoid language detection issues
        sanitized = sanitized.replacingOccurrences(of: "ç", with: "c")
        sanitized = sanitized.replacingOccurrences(of: "á", with: "a")
        sanitized = sanitized.replacingOccurrences(of: "é", with: "e")
        sanitized = sanitized.replacingOccurrences(of: "í", with: "i")
        sanitized = sanitized.replacingOccurrences(of: "ó", with: "o")
        sanitized = sanitized.replacingOccurrences(of: "ú", with: "u")
        sanitized = sanitized.replacingOccurrences(of: "ñ", with: "n")
        
        // Special handling for countries that might trigger "ca" detection
        if sanitized.lowercased().contains("costa rica") {
            sanitized = sanitized.replacingOccurrences(of: "Costa Rica", with: "Costa_Rica")
        }
        if sanitized.lowercased().contains("south africa") {
            sanitized = sanitized.replacingOccurrences(of: "South Africa", with: "South_Africa")
        }
        
        // Ensure it's a clean English representation
        return sanitized
    }
    
    private func getQuintile(rank: Int, total: Int) -> String {
        let percentage = Double(rank) / Double(total)
        if percentage <= 0.2 {
            return "5th quintile (highest 20%)"
        } else if percentage <= 0.4 {
            return "4th quintile"
        } else if percentage <= 0.6 {
            return "3rd quintile (middle 20%)"
        } else if percentage <= 0.8 {
            return "2nd quintile"
        } else {
            return "1st quintile (lowest 20%)"
        }
    }
    
    private func extractCountryNames(from text: String) -> [String] {
        let countryNames = dataStore.countries.map { $0.countryName }
        var foundCountries: [String] = []
        
        for country in countryNames {
            if text.contains(country) {
                foundCountries.append(country)
            }
        }
        
        return Array(Set(foundCountries)) // Remove duplicates
    }
    
    private func handleUnsupportedLocale(question: AnalysisQuestion) async {
        let currentLocale = Locale.current
        let fallbackInsight = EnergyInsight(
            question: question,
            analysis: """
            AI analysis is currently unavailable because your device locale (\(currentLocale.identifier)) is not supported by Apple Intelligence Foundation Models.
            
            Supported locales include English (US), English (UK), and other English variants. To enable AI analysis:
            
            1. Go to Settings → General → Language & Region
            2. Set your device language to English (United States)
            3. Restart your device
            4. Ensure Apple Intelligence is enabled in Settings
            
            The statistical analysis features in your app will continue to work normally.
            """,
            relevantCountries: []
        )
        
        await MainActor.run {
            analysisResults.append(fallbackInsight)
        }
    }
    
    // MARK: - Clear Results
    func clearResults() {
        analysisResults.removeAll()
    }
    
}

// MARK: - Availability Check Extension
@available(visionOS 26.0, *)
extension AIEnergyAnalyzer {
    var availabilityMessage: String {
        switch modelAvailability {
        case .available:
            if localeSupported {
                return "AI Analysis Ready"
            } else {
                let currentLocale = Locale.current.identifier
                return "Locale \(currentLocale) not supported - switch to English (US)"
            }
        case .unavailable(.deviceNotEligible):
            return "Device not compatible with Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "AI model downloading... Please wait"
        case .unavailable(let other):
            return "AI unavailable: \(other)"
        }
    }
    
    var availabilityColor: Color {
        switch modelAvailability {
        case .available:
            return localeSupported ? .green : .orange
        case .unavailable(.deviceNotEligible):
            return .red
        case .unavailable(.appleIntelligenceNotEnabled):
            return .orange
        case .unavailable(.modelNotReady):
            return .blue
        case .unavailable:
            return .gray
        }
    }
}
