//
//  ContextualMoodTriggersDetection.swift
//  MoodyChat
//
//  Created by Boris Milev on 3.08.25.
//

import Foundation
import SwiftUI

// MARK: - Contextual Mood Triggers Detection System

class ContextualMoodTriggersDetection: ObservableObject {
    static let shared = ContextualMoodTriggersDetection()
    
    @Published var detectedTriggers: [DetectedTrigger] = []
    @Published var personalizedTriggers: [PersonalizedTrigger] = []
    @Published var triggerInsights: TriggerInsights?
    @Published var realTimeAlerts: [TriggerAlert] = []
    
    private let memorySystem = ConversationMemorySystem.shared
    private let historyPersistence = MoodHistoryPersistence.shared
    private let userDefaults = UserDefaults.standard
    
    // Trigger detection engines
    private var lexicalTriggers: [LexicalTrigger] = []
    private var semanticTriggers: [SemanticTrigger] = []
    private var contextualPatterns: [ContextualPattern] = []
    private var temporalTriggers: [TemporalTriggerPattern] = []
    private var conversationalTriggers: [ConversationalTrigger] = []
    
    private init() {
        initializeDefaultTriggers()
        loadPersonalizedTriggers()
        startRealTimeMonitoring()
    }
    
    // MARK: - Core Detection Functions
    
    func detectTriggers(
        in message: String,
        currentMood: Mood,
        conversationContext: [Message],
        timeContext: Date = Date()
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        
        // 1. Lexical Trigger Detection
        triggers.append(contentsOf: detectLexicalTriggers(
            message: message,
            currentMood: currentMood
        ))
        
        // 2. Semantic Trigger Detection
        triggers.append(contentsOf: detectSemanticTriggers(
            message: message,
            context: conversationContext
        ))
        
        // 3. Contextual Pattern Detection
        triggers.append(contentsOf: detectContextualPatterns(
            message: message,
            conversationFlow: conversationContext
        ))
        
        // 4. Temporal Trigger Detection
        triggers.append(contentsOf: detectTemporalTriggers(
            message: message,
            timeContext: timeContext,
            currentMood: currentMood
        ))
        
        // 5. Conversational Flow Triggers
        triggers.append(contentsOf: detectConversationalTriggers(
            message: message,
            conversationContext: conversationContext
        ))
        
        // 6. Personalized Trigger Detection
        triggers.append(contentsOf: detectPersonalizedTriggers(
            message: message,
            currentMood: currentMood
        ))
        
        // Filter and rank triggers
        let rankedTriggers = rankAndFilterTriggers(triggers)
        
        // Update detected triggers
        detectedTriggers = rankedTriggers
        
        // Generate real-time alerts if needed
        generateRealTimeAlerts(from: rankedTriggers)
        
        // Learn from detections
        learnFromDetections(rankedTriggers, currentMood: currentMood)
        
        return rankedTriggers
    }
    
    func analyzeTriggerPatterns(timeframe: TriggerTimeframe = .month) -> TriggerInsights {
        let history = historyPersistence.getMoodHistory(for: timeframe.toMoodTimeRange())
        let triggerHistory = loadTriggerHistory(for: timeframe)
        
        // Analyze trigger frequency
        let triggerFrequency = analyzeTriggerFrequency(history: triggerHistory)
        
        // Identify trigger-mood correlations
        let moodCorrelations = analyzeTriggerMoodCorrelations(
            triggers: triggerHistory,
            moodHistory: history
        )
        
        // Detect trigger clusters
        let triggerClusters = detectTriggerClusters(history: triggerHistory)
        
        // Analyze trigger intensity patterns
        let intensityPatterns = analyzeTriggerIntensityPatterns(history: triggerHistory)
        
        // Generate coping strategies
        let copingStrategies = generateCopingStrategies(
            frequency: triggerFrequency,
            correlations: moodCorrelations
        )
        
        // Create insights
        let insights = TriggerInsights(
            timeframe: timeframe,
            mostFrequentTriggers: Array(triggerFrequency.prefix(5)),
            strongestMoodCorrelations: Array(moodCorrelations.prefix(3)),
            triggerClusters: triggerClusters,
            intensityPatterns: intensityPatterns,
            copingStrategies: copingStrategies,
            overallTriggerSensitivity: calculateOverallSensitivity(history: triggerHistory),
            recommendations: generateRecommendations(based: triggerFrequency)
        )
        
        self.triggerInsights = insights
        return insights
    }
    
    func getPersonalizedTriggerProfile() -> PersonalizedTriggerProfile {
        let recentTriggers = personalizedTriggers.filter { 
            Calendar.current.isDate($0.lastDetected, equalTo: Date(), toGranularity: .month) 
        }
        
        // Categorize triggers
        let categories = categorizeTriggers(recentTriggers)
        
        // Calculate sensitivity scores
        let sensitivityProfile = calculateSensitivityProfile(triggers: recentTriggers)
        
        // Identify growth areas
        let growthAreas = identifyEmotionalGrowthAreas(triggers: recentTriggers)
        
        // Generate protective strategies
        let protectiveStrategies = generateProtectiveStrategies(
            categories: categories,
            sensitivity: sensitivityProfile
        )
        
        return PersonalizedTriggerProfile(
            triggerCategories: categories,
            sensitivityProfile: sensitivityProfile,
            protectiveStrategies: protectiveStrategies,
            growthAreas: growthAreas,
            triggerResilience: calculateTriggerResilience()
        )
    }
    
    // MARK: - Detection Methods
    
    private func detectLexicalTriggers(
        message: String,
        currentMood: Mood
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        let lowerMessage = message.lowercased()
        
        for lexicalTrigger in lexicalTriggers {
            for keyword in lexicalTrigger.keywords {
                if lowerMessage.contains(keyword) {
                    let trigger = DetectedTrigger(
                        id: UUID(),
                        type: .lexical,
                        name: lexicalTrigger.name,
                        description: "Keyword-based trigger detected",
                        detectedText: keyword,
                        confidence: lexicalTrigger.confidence,
                        potentialMoodImpact: lexicalTrigger.moodImpact,
                        severity: lexicalTrigger.severity,
                        category: lexicalTrigger.category,
                        timestamp: Date(),
                        context: message
                    )
                    triggers.append(trigger)
                }
            }
        }
        
        return triggers
    }
    
    private func detectSemanticTriggers(
        message: String,
        context: [Message]
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        
        for semanticTrigger in semanticTriggers {
            let semanticMatch = analyzeSemanticMatch(
                message: message,
                trigger: semanticTrigger,
                context: context
            )
            
            if semanticMatch.confidence > 0.6 {
                let trigger = DetectedTrigger(
                    id: UUID(),
                    type: .semantic,
                    name: semanticTrigger.name,
                    description: semanticMatch.reasoning,
                    detectedText: semanticMatch.matchedText,
                    confidence: semanticMatch.confidence,
                    potentialMoodImpact: semanticTrigger.moodImpact,
                    severity: semanticTrigger.severity,
                    category: semanticTrigger.category,
                    timestamp: Date(),
                    context: message
                )
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    private func detectContextualPatterns(
        message: String,
        conversationFlow: [Message]
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        
        for pattern in contextualPatterns {
            let patternMatch = analyzeContextualPattern(
                message: message,
                pattern: pattern,
                conversationFlow: conversationFlow
            )
            
            if patternMatch.isMatch {
                let trigger = DetectedTrigger(
                    id: UUID(),
                    type: .contextual,
                    name: pattern.name,
                    description: patternMatch.description,
                    detectedText: patternMatch.relevantText,
                    confidence: pattern.confidence,
                    potentialMoodImpact: pattern.moodImpact,
                    severity: pattern.severity,
                    category: pattern.category,
                    timestamp: Date(),
                    context: message
                )
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    private func detectTemporalTriggers(
        message: String,
        timeContext: Date,
        currentMood: Mood
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        let calendar = Calendar.current
        
        for temporalTrigger in temporalTriggers {
            let timeMatch = checkTemporalMatch(
                trigger: temporalTrigger,
                timeContext: timeContext,
                calendar: calendar
            )
            
            if timeMatch.isMatch {
                let trigger = DetectedTrigger(
                    id: UUID(),
                    type: .temporal,
                    name: temporalTrigger.name,
                    description: timeMatch.description,
                    detectedText: message,
                    confidence: temporalTrigger.confidence,
                    potentialMoodImpact: temporalTrigger.moodImpact,
                    severity: temporalTrigger.severity,
                    category: .temporal,
                    timestamp: Date(),
                    context: message
                )
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    private func detectConversationalTriggers(
        message: String,
        conversationContext: [Message]
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        
        for convTrigger in conversationalTriggers {
            let convMatch = analyzeConversationalTrigger(
                message: message,
                trigger: convTrigger,
                context: conversationContext
            )
            
            if convMatch.isTriggered {
                let trigger = DetectedTrigger(
                    id: UUID(),
                    type: .conversational,
                    name: convTrigger.name,
                    description: convMatch.reasoning,
                    detectedText: convMatch.triggerText,
                    confidence: convTrigger.confidence,
                    potentialMoodImpact: convTrigger.moodImpact,
                    severity: convTrigger.severity,
                    category: convTrigger.category,
                    timestamp: Date(),
                    context: message
                )
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    private func detectPersonalizedTriggers(
        message: String,
        currentMood: Mood
    ) -> [DetectedTrigger] {
        
        var triggers: [DetectedTrigger] = []
        
        for personalTrigger in personalizedTriggers {
            let personalMatch = analyzePersonalizedTrigger(
                message: message,
                trigger: personalTrigger,
                currentMood: currentMood
            )
            
            if personalMatch.confidence > 0.5 {
                let trigger = DetectedTrigger(
                    id: UUID(),
                    type: .personalized,
                    name: personalTrigger.name,
                    description: personalMatch.reasoning,
                    detectedText: personalMatch.matchedText,
                    confidence: personalMatch.confidence,
                    potentialMoodImpact: personalTrigger.moodImpact,
                    severity: personalTrigger.severity,
                    category: personalTrigger.category,
                    timestamp: Date(),
                    context: message
                )
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeSemanticMatch(
        message: String,
        trigger: SemanticTrigger,
        context: [Message]
    ) -> SemanticMatchResult {
        
        // Simple semantic analysis based on concept matching
        let messageConcepts = extractConcepts(from: message)
        let contextConcepts = extractConcepts(from: context.map { $0.text }.joined(separator: " "))
        
        let conceptOverlap = Set(messageConcepts).intersection(Set(trigger.concepts))
        let confidence = Double(conceptOverlap.count) / Double(trigger.concepts.count)
        
        if confidence > 0.4 {
            return SemanticMatchResult(
                confidence: confidence,
                reasoning: "Semantic concepts match: \(conceptOverlap.joined(separator: ", "))",
                matchedText: Array(conceptOverlap).joined(separator: ", ")
            )
        }
        
        return SemanticMatchResult(confidence: 0.0, reasoning: "No semantic match", matchedText: "")
    }
    
    private func analyzeContextualPattern(
        message: String,
        pattern: ContextualPattern,
        conversationFlow: [Message]
    ) -> ContextualPatternMatch {
        
        let recentMessages = conversationFlow.suffix(pattern.contextWindowSize)
        
        switch pattern.patternType {
        case .escalation:
            return analyzeEscalationPattern(message: message, recent: Array(recentMessages))
        case .repetition:
            return analyzeRepetitionPattern(message: message, recent: Array(recentMessages))
        case .contradiction:
            return analyzeContradictionPattern(message: message, recent: Array(recentMessages))
        case .avoidance:
            return analyzeAvoidancePattern(message: message, recent: Array(recentMessages))
        }
    }
    
    private func checkTemporalMatch(
        trigger: TemporalTriggerPattern,
        timeContext: Date,
        calendar: Calendar
    ) -> TemporalMatch {
        
        switch trigger.temporalType {
        case .timeOfDay(let timeRange):
            let hour = calendar.component(.hour, from: timeContext)
            if timeRange.contains(hour) {
                return TemporalMatch(
                    isMatch: true,
                    description: "Time-based trigger: \(trigger.name) is active during this time period"
                )
            }
            
        case .dayOfWeek(let days):
            let dayOfWeek = calendar.component(.weekday, from: timeContext)
            if days.contains(dayOfWeek) {
                return TemporalMatch(
                    isMatch: true,
                    description: "Day-based trigger: \(trigger.name) is active on this day of the week"
                )
            }
            
        case .anniversary(let date):
            if calendar.isDate(timeContext, equalTo: date, toGranularity: .day) {
                return TemporalMatch(
                    isMatch: true,
                    description: "Anniversary trigger: \(trigger.name) matches this significant date"
                )
            }
            
        case .recurring(let interval):
            // Check if current time matches recurring pattern
            let daysSinceEpoch = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: timeContext).day ?? 0
            if daysSinceEpoch % interval == 0 {
                return TemporalMatch(
                    isMatch: true,
                    description: "Recurring trigger: \(trigger.name) occurs every \(interval) days"
                )
            }
        }
        
        return TemporalMatch(isMatch: false, description: "No temporal match")
    }
    
    private func analyzeConversationalTrigger(
        message: String,
        trigger: ConversationalTrigger,
        context: [Message]
    ) -> ConversationalTriggerResult {
        
        switch trigger.triggerType {
        case .topicShift:
            return analyzeTopicShift(message: message, context: context, trigger: trigger)
        case .emotionalIntensity:
            return analyzeEmotionalIntensity(message: message, trigger: trigger)
        case .communicationPattern:
            return analyzeCommunicationPattern(message: message, context: context, trigger: trigger)
        case .responseLength:
            return analyzeResponseLength(message: message, trigger: trigger)
        }
    }
    
    private func analyzePersonalizedTrigger(
        message: String,
        trigger: PersonalizedTrigger,
        currentMood: Mood
    ) -> PersonalizedTriggerResult {
        
        var confidence = 0.0
        var reasoning = ""
        var matchedText = ""
        
        // Check keyword matches
        let keywordMatches = trigger.personalKeywords.filter { message.lowercased().contains($0.lowercased()) }
        if !keywordMatches.isEmpty {
            confidence += 0.4
            matchedText = keywordMatches.joined(separator: ", ")
            reasoning += "Personal keywords detected: \(matchedText). "
        }
        
        // Check mood context
        if trigger.associatedMoods.contains(currentMood) {
            confidence += 0.3
            reasoning += "Current mood (\(currentMood.displayName)) is associated with this trigger. "
        }
        
        // Check historical accuracy
        confidence *= trigger.historicalAccuracy
        
        return PersonalizedTriggerResult(
            confidence: confidence,
            reasoning: reasoning,
            matchedText: matchedText
        )
    }
    
    // MARK: - Pattern Analysis Helpers
    
    private func analyzeEscalationPattern(message: String, recent: [Message]) -> ContextualPatternMatch {
        // Check if emotional intensity is increasing
        let emotionalWords = ["very", "extremely", "really", "so", "too", "much", "more"]
        let currentIntensity = emotionalWords.filter { message.lowercased().contains($0) }.count
        
        let recentIntensities = recent.map { msg in
            emotionalWords.filter { msg.text.lowercased().contains($0) }.count
        }
        
        if !recentIntensities.isEmpty && currentIntensity > recentIntensities.max() ?? 0 {
            return ContextualPatternMatch(
                isMatch: true,
                description: "Emotional escalation detected - intensity increasing",
                relevantText: message
            )
        }
        
        return ContextualPatternMatch(isMatch: false, description: "", relevantText: "")
    }
    
    private func analyzeRepetitionPattern(message: String, recent: [Message]) -> ContextualPatternMatch {
        let currentWords = Set(message.lowercased().split(separator: " ").map(String.init))
        
        for recentMsg in recent {
            let recentWords = Set(recentMsg.text.lowercased().split(separator: " ").map(String.init))
            let overlap = currentWords.intersection(recentWords)
            
            if Double(overlap.count) / Double(currentWords.count) > 0.6 {
                return ContextualPatternMatch(
                    isMatch: true,
                    description: "Repetitive language pattern detected",
                    relevantText: Array(overlap).joined(separator: " ")
                )
            }
        }
        
        return ContextualPatternMatch(isMatch: false, description: "", relevantText: "")
    }
    
    private func analyzeContradictionPattern(message: String, recent: [Message]) -> ContextualPatternMatch {
        let contradictionIndicators = ["but", "however", "although", "despite", "actually", "wait"]
        
        if contradictionIndicators.contains(where: { message.lowercased().contains($0) }) {
            return ContextualPatternMatch(
                isMatch: true,
                description: "Contradiction or self-correction pattern detected",
                relevantText: message
            )
        }
        
        return ContextualPatternMatch(isMatch: false, description: "", relevantText: "")
    }
    
    private func analyzeAvoidancePattern(message: String, recent: [Message]) -> ContextualPatternMatch {
        let avoidanceIndicators = ["maybe", "i don't know", "whatever", "i guess", "not sure", "doesn't matter"]
        
        if avoidanceIndicators.contains(where: { message.lowercased().contains($0) }) {
            return ContextualPatternMatch(
                isMatch: true,
                description: "Emotional avoidance pattern detected",
                relevantText: message
            )
        }
        
        return ContextualPatternMatch(isMatch: false, description: "", relevantText: "")
    }
    
    private func analyzeTopicShift(message: String, context: [Message], trigger: ConversationalTrigger) -> ConversationalTriggerResult {
        // Simple topic shift detection based on keyword changes
        let currentTopics = extractTopics(from: message)
        let recentTopics = extractTopics(from: context.suffix(3).map { $0.text }.joined(separator: " "))
        
        let topicOverlap = Set(currentTopics).intersection(Set(recentTopics))
        let shiftScore = 1.0 - (Double(topicOverlap.count) / Double(max(currentTopics.count, recentTopics.count, 1)))
        
        if shiftScore > 0.7 {
            return ConversationalTriggerResult(
                isTriggered: true,
                reasoning: "Significant topic shift detected",
                triggerText: message
            )
        }
        
        return ConversationalTriggerResult(isTriggered: false, reasoning: "", triggerText: "")
    }
    
    private func analyzeEmotionalIntensity(message: String, trigger: ConversationalTrigger) -> ConversationalTriggerResult {
        let intensityWords = ["!", "?", "very", "extremely", "so", "really", "absolutely", "completely"]
        let intensityScore = intensityWords.filter { message.contains($0) }.count
        
        if intensityScore >= 3 {
            return ConversationalTriggerResult(
                isTriggered: true,
                reasoning: "High emotional intensity detected",
                triggerText: message
            )
        }
        
        return ConversationalTriggerResult(isTriggered: false, reasoning: "", triggerText: "")
    }
    
    private func analyzeCommunicationPattern(message: String, context: [Message], trigger: ConversationalTrigger) -> ConversationalTriggerResult {
        // Analyze communication patterns like brevity, formality, etc.
        let averageLength = context.map { $0.text.count }.reduce(0, +) / max(context.count, 1)
        let currentLength = message.count
        
        if currentLength < averageLength / 3 && currentLength < 20 {
            return ConversationalTriggerResult(
                isTriggered: true,
                reasoning: "Sudden communication brevity detected",
                triggerText: message
            )
        }
        
        return ConversationalTriggerResult(isTriggered: false, reasoning: "", triggerText: "")
    }
    
    private func analyzeResponseLength(message: String, trigger: ConversationalTrigger) -> ConversationalTriggerResult {
        if message.count < 10 {
            return ConversationalTriggerResult(
                isTriggered: true,
                reasoning: "Unusually short response may indicate disengagement",
                triggerText: message
            )
        }
        
        return ConversationalTriggerResult(isTriggered: false, reasoning: "", triggerText: "")
    }
    
    // MARK: - Utility Methods
    
    private func extractConcepts(from text: String) -> [String] {
        // Simple concept extraction (in production, use NLP)
        let concepts = ["work", "family", "stress", "love", "fear", "anger", "sadness", "joy", "anxiety", "peace"]
        return concepts.filter { text.lowercased().contains($0) }
    }
    
    private func extractTopics(from text: String) -> [String] {
        // Simple topic extraction
        let topics = ["work", "relationship", "health", "money", "family", "future", "past", "goals", "problems"]
        return topics.filter { text.lowercased().contains($0) }
    }
    
    private func rankAndFilterTriggers(_ triggers: [DetectedTrigger]) -> [DetectedTrigger] {
        // Sort by severity and confidence
        let sorted = triggers.sorted { trigger1, trigger2 in
            if trigger1.severity != trigger2.severity {
                return trigger1.severity.rawValue > trigger2.severity.rawValue
            }
            return trigger1.confidence > trigger2.confidence
        }
        
        // Remove duplicates and low-confidence triggers
        let filtered = sorted.filter { $0.confidence > 0.3 }
        
        // Limit to top 5 triggers
        return Array(filtered.prefix(5))
    }
    
    private func generateRealTimeAlerts(from triggers: [DetectedTrigger]) {
        let highSeverityTriggers = triggers.filter { $0.severity == .high }
        
        for trigger in highSeverityTriggers {
            let alert = TriggerAlert(
                id: UUID(),
                trigger: trigger,
                alertType: .warning,
                message: "High-impact emotional trigger detected: \(trigger.name)",
                timestamp: Date(),
                isActive: true
            )
            
            realTimeAlerts.append(alert)
        }
        
        // Keep only recent alerts
        realTimeAlerts = realTimeAlerts.filter { 
            Date().timeIntervalSince($0.timestamp) < 3600 // 1 hour
        }
    }
    
    private func learnFromDetections(_ triggers: [DetectedTrigger], currentMood: Mood) {
        // Update personalized triggers based on successful detections
        for trigger in triggers {
            if trigger.confidence > 0.7 {
                updatePersonalizedTrigger(
                    name: trigger.name,
                    detectedText: trigger.detectedText,
                    mood: currentMood,
                    severity: trigger.severity
                )
            }
        }
        
        savePersonalizedTriggers()
    }
    
    private func updatePersonalizedTrigger(name: String, detectedText: String, mood: Mood, severity: TriggerSeverity) {
        if let existingIndex = personalizedTriggers.firstIndex(where: { $0.name == name }) {
            // Update existing trigger
            personalizedTriggers[existingIndex].frequency += 1
            personalizedTriggers[existingIndex].lastDetected = Date()
            personalizedTriggers[existingIndex].historicalAccuracy = min(personalizedTriggers[existingIndex].historicalAccuracy + 0.1, 1.0)
            
            if !personalizedTriggers[existingIndex].personalKeywords.contains(detectedText) {
                personalizedTriggers[existingIndex].personalKeywords.append(detectedText)
            }
            
            if !personalizedTriggers[existingIndex].associatedMoods.contains(mood) {
                personalizedTriggers[existingIndex].associatedMoods.append(mood)
            }
        } else {
            // Create new personalized trigger
            let newTrigger = PersonalizedTrigger(
                name: name,
                personalKeywords: [detectedText],
                associatedMoods: [mood],
                frequency: 1,
                historicalAccuracy: 0.7,
                lastDetected: Date(),
                moodImpact: MoodImpact(targetMood: mood, intensity: 0.5, direction: .negative),
                severity: severity,
                category: .personal
            )
            personalizedTriggers.append(newTrigger)
        }
    }
    
    // MARK: - Analysis Methods (continued)
    
    private func analyzeTriggerFrequency(history: [TriggerHistoryEntry]) -> [(trigger: String, frequency: Int)] {
        let frequency = Dictionary(grouping: history) { $0.triggerName }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return frequency.map { (trigger: $0.key, frequency: $0.value) }
    }
    
    private func analyzeTriggerMoodCorrelations(triggers: [TriggerHistoryEntry], moodHistory: [MoodHistoryEntry]) -> [(trigger: String, mood: Mood, correlation: Double)] {
        var correlations: [(trigger: String, mood: Mood, correlation: Double)] = []
        
        // Simple correlation analysis
        let triggerGroups = Dictionary(grouping: triggers) { $0.triggerName }
        
        for (triggerName, triggerEntries) in triggerGroups {
            let triggerMoods = triggerEntries.compactMap { triggerEntry in
                moodHistory.first { abs($0.timestamp.timeIntervalSince(triggerEntry.timestamp)) < 300 }?.mood // Within 5 minutes
            }
            
            let moodCounts = Dictionary(grouping: triggerMoods) { $0 }.mapValues { $0.count }
            
            if let dominantMood = moodCounts.max(by: { $0.value < $1.value }) {
                let correlation = Double(dominantMood.value) / Double(triggerMoods.count)
                correlations.append((trigger: triggerName, mood: dominantMood.key, correlation: correlation))
            }
        }
        
        return correlations.sorted { $0.correlation > $1.correlation }
    }
    
    private func detectTriggerClusters(history: [TriggerHistoryEntry]) -> [TriggerCluster] {
        // Group triggers that occur together
        var clusters: [TriggerCluster] = []
        
        // Simple time-based clustering (triggers within 1 hour)
        let timeThreshold: TimeInterval = 3600
        var processed: Set<UUID> = []
        
        for entry in history {
            if processed.contains(entry.id) { continue }
            
            let closeEntries = history.filter { otherEntry in
                abs(entry.timestamp.timeIntervalSince(otherEntry.timestamp)) <= timeThreshold
            }
            
            if closeEntries.count > 1 {
                let triggerNames = Array(Set(closeEntries.map { $0.triggerName }))
                if triggerNames.count > 1 {
                    clusters.append(TriggerCluster(
                        triggerNames: triggerNames,
                        frequency: 1,
                        averageTimeSpan: timeThreshold
                    ))
                    
                    closeEntries.forEach { processed.insert($0.id) }
                }
            }
        }
        
        return clusters
    }
    
    private func analyzeTriggerIntensityPatterns(history: [TriggerHistoryEntry]) -> TriggerIntensityPattern {
        let intensities = history.map { $0.intensity }
        let averageIntensity = intensities.reduce(0, +) / Double(intensities.count)
        
        let variance = intensities.map { pow($0 - averageIntensity, 2) }.reduce(0, +) / Double(intensities.count)
        let volatility = sqrt(variance)
        
        return TriggerIntensityPattern(
            averageIntensity: averageIntensity,
            volatility: volatility,
            peakIntensity: intensities.max() ?? 0.0,
            trend: calculateIntensityTrend(intensities: intensities)
        )
    }
    
    private func calculateIntensityTrend(intensities: [Double]) -> IntensityTrend {
        guard intensities.count > 3 else { return .stable }
        
        let recent = Array(intensities.suffix(intensities.count / 2))
        let earlier = Array(intensities.prefix(intensities.count / 2))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
        
        let difference = recentAvg - earlierAvg
        
        if difference > 0.2 {
            return .increasing
        } else if difference < -0.2 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func generateCopingStrategies(
        frequency: [(trigger: String, frequency: Int)],
        correlations: [(trigger: String, mood: Mood, correlation: Double)]
    ) -> [CopingStrategy] {
        
        var strategies: [CopingStrategy] = []
        
        // Generate strategies for frequent triggers
        for triggerFreq in frequency.prefix(3) {
            let strategy = CopingStrategy(
                triggerName: triggerFreq.trigger,
                strategy: generateCopingStrategyText(for: triggerFreq.trigger),
                effectiveness: 0.7, // Default effectiveness
                category: .prevention
            )
            strategies.append(strategy)
        }
        
        // Generate strategies for high-correlation triggers
        for correlation in correlations.prefix(2) {
            let strategy = CopingStrategy(
                triggerName: correlation.trigger,
                strategy: generateMoodSpecificStrategy(trigger: correlation.trigger, mood: correlation.mood),
                effectiveness: correlation.correlation,
                category: .response
            )
            strategies.append(strategy)
        }
        
        return strategies
    }
    
    private func generateCopingStrategyText(for trigger: String) -> String {
        let strategies = [
            "work": "Practice time management and set boundaries between work and personal time",
            "stress": "Use deep breathing exercises and mindfulness techniques",
            "family": "Communicate openly and set healthy boundaries",
            "money": "Create a budget and focus on what you can control financially",
            "health": "Maintain regular check-ups and practice self-care",
            "relationship": "Practice active listening and express your needs clearly"
        ]
        
        return strategies[trigger.lowercased()] ?? "Practice mindfulness and seek support when needed"
    }
    
    private func generateMoodSpecificStrategy(trigger: String, mood: Mood) -> String {
        switch mood {
        case .anxious:
            return "When \(trigger) triggers anxiety, practice grounding techniques and remind yourself of what you can control"
        case .sad:
            return "When \(trigger) brings sadness, allow yourself to feel the emotion while practicing self-compassion"
        case .angry:
            return "When \(trigger) causes anger, take a pause before responding and identify what boundary may have been crossed"
        case .frustrated:
            return "When \(trigger) leads to frustration, break the situation into smaller, manageable parts"
        default:
            return "When encountering \(trigger), acknowledge your emotional response and practice self-care"
        }
    }
    
    // MARK: - Initialization and Persistence
    
    private func initializeDefaultTriggers() {
        // Initialize lexical triggers
        lexicalTriggers = [
            LexicalTrigger(
                name: "Work Stress",
                keywords: ["deadline", "boss", "overtime", "meeting", "presentation"],
                confidence: 0.8,
                moodImpact: MoodImpact(targetMood: .anxious, intensity: 0.7, direction: .negative),
                severity: .medium,
                category: .work
            ),
            LexicalTrigger(
                name: "Relationship Conflict",
                keywords: ["fight", "argument", "breakup", "divorce", "conflict"],
                confidence: 0.9,
                moodImpact: MoodImpact(targetMood: .sad, intensity: 0.8, direction: .negative),
                severity: .high,
                category: .relationship
            ),
            LexicalTrigger(
                name: "Health Concerns",
                keywords: ["sick", "pain", "doctor", "hospital", "symptoms"],
                confidence: 0.7,
                moodImpact: MoodImpact(targetMood: .anxious, intensity: 0.6, direction: .negative),
                severity: .medium,
                category: .health
            )
        ]
        
        // Initialize semantic triggers
        semanticTriggers = [
            SemanticTrigger(
                name: "Financial Stress",
                concepts: ["money", "budget", "debt", "bills", "financial"],
                confidence: 0.8,
                moodImpact: MoodImpact(targetMood: .anxious, intensity: 0.7, direction: .negative),
                severity: .medium,
                category: .financial
            )
        ]
        
        // Initialize contextual patterns
        contextualPatterns = [
            ContextualPattern(
                name: "Emotional Escalation",
                patternType: .escalation,
                contextWindowSize: 5,
                confidence: 0.7,
                moodImpact: MoodImpact(targetMood: .angry, intensity: 0.8, direction: .negative),
                severity: .high,
                category: .emotional
            )
        ]
    }
    
    private func loadPersonalizedTriggers() {
        if let data = userDefaults.data(forKey: "personalizedTriggers"),
           let triggers = try? JSONDecoder().decode([PersonalizedTrigger].self, from: data) {
            personalizedTriggers = triggers
        }
    }
    
    private func savePersonalizedTriggers() {
        if let data = try? JSONEncoder().encode(personalizedTriggers) {
            userDefaults.set(data, forKey: "personalizedTriggers")
        }
    }
    
    private func loadTriggerHistory(for timeframe: TriggerTimeframe) -> [TriggerHistoryEntry] {
        // Load from persistent storage - simplified implementation
        return []
    }
    
    private func startRealTimeMonitoring() {
        // Start background monitoring for real-time trigger detection
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.cleanupOldAlerts()
        }
    }
    
    private func cleanupOldAlerts() {
        realTimeAlerts.removeAll { alert in
            Date().timeIntervalSince(alert.timestamp) > 3600 // Remove alerts older than 1 hour
        }
    }
    
    // MARK: - Additional Helper Methods
    
    private func calculateOverallSensitivity(history: [TriggerHistoryEntry]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        
        let averageIntensity = history.map { $0.intensity }.reduce(0, +) / Double(history.count)
        let triggerFrequency = Double(history.count) / 30.0 // Triggers per day over a month
        
        return min((averageIntensity + triggerFrequency) / 2.0, 1.0)
    }
    
    private func generateRecommendations(based frequency: [(trigger: String, frequency: Int)]) -> [String] {
        var recommendations: [String] = []
        
        if let topTrigger = frequency.first {
            recommendations.append("Consider developing specific coping strategies for '\(topTrigger.trigger)' as it's your most frequent trigger")
        }
        
        if frequency.count > 3 {
            recommendations.append("You have multiple active triggers - practicing general stress management techniques could be beneficial")
        }
        
        recommendations.append("Regular mood tracking can help identify patterns and early warning signs")
        
        return recommendations
    }
    
    private func categorizeTriggers(_ triggers: [PersonalizedTrigger]) -> [TriggerCategory: Int] {
        return Dictionary(grouping: triggers) { $0.category }
            .mapValues { $0.count }
    }
    
    private func calculateSensitivityProfile(triggers: [PersonalizedTrigger]) -> SensitivityProfile {
        let totalTriggers = triggers.count
        let highSeverityCount = triggers.filter { $0.severity == .high }.count
        let mediumSeverityCount = triggers.filter { $0.severity == .medium }.count
        
        return SensitivityProfile(
            overall: Double(totalTriggers) / 10.0, // Normalize
            highIntensity: Double(highSeverityCount) / Double(max(totalTriggers, 1)),
            mediumIntensity: Double(mediumSeverityCount) / Double(max(totalTriggers, 1))
        )
    }
    
    private func identifyEmotionalGrowthAreas(triggers: [PersonalizedTrigger]) -> [String] {
        let categories = Dictionary(grouping: triggers) { $0.category }
        
        var growthAreas: [String] = []
        
        if (categories[.work]?.count ?? 0) > 2 {
            growthAreas.append("Work-life balance and professional stress management")
        }
        
        if (categories[.relationship]?.count ?? 0) > 2 {
            growthAreas.append("Communication skills and relationship dynamics")
        }
        
        if (categories[.personal]?.count ?? 0) > 3 {
            growthAreas.append("Self-awareness and personal emotional regulation")
        }
        
        return growthAreas
    }
    
    private func generateProtectiveStrategies(categories: [TriggerCategory: Int], sensitivity: SensitivityProfile) -> [String] {
        var strategies: [String] = []
        
        if sensitivity.overall > 0.7 {
            strategies.append("Practice daily mindfulness meditation to build emotional resilience")
            strategies.append("Establish regular self-care routines to prevent trigger accumulation")
        }
        
        if categories[.work] ?? 0 > 0 {
            strategies.append("Set clear work boundaries and practice saying no to excessive demands")
        }
        
        if categories[.relationship] ?? 0 > 0 {
            strategies.append("Develop assertive communication skills and healthy conflict resolution")
        }
        
        return strategies
    }
    
    private func calculateTriggerResilience() -> Double {
        // Calculate based on how well triggers are managed over time
        let recentTriggers = personalizedTriggers.filter { 
            Calendar.current.isDate($0.lastDetected, equalTo: Date(), toGranularity: .month) 
        }
        
        let averageAccuracy = recentTriggers.map { $0.historicalAccuracy }.reduce(0, +) / Double(max(recentTriggers.count, 1))
        
        // Resilience is inversely related to trigger frequency and directly related to management accuracy
        let frequency = Double(recentTriggers.count) / 30.0 // Daily frequency
        let resilience = averageAccuracy / max(frequency, 0.1)
        
        return min(resilience, 1.0)
    }
}

// MARK: - Data Models and Extensions

extension TriggerTimeframe {
    func toMoodTimeRange() -> MoodTimeRange {
        switch self {
        case .day: return .today
        case .week: return .week
        case .month: return .month
        case .threeMonths: return .threeMonths
        case .year: return .year
        }
    }
}

// MARK: - Data Models

struct DetectedTrigger: Identifiable, Codable {
    let id: UUID
    let type: TriggerType
    let name: String
    let description: String
    let detectedText: String
    let confidence: Double
    let potentialMoodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
    let timestamp: Date
    let context: String
}

enum TriggerType: String, Codable, CaseIterable {
    case lexical = "lexical"
    case semantic = "semantic"
    case contextual = "contextual"
    case temporal = "temporal"
    case conversational = "conversational"
    case personalized = "personalized"
}

enum TriggerSeverity: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
}

enum TriggerCategory: String, Codable, CaseIterable {
    case work = "work"
    case relationship = "relationship"
    case health = "health"
    case financial = "financial"
    case personal = "personal"
    case social = "social"
    case temporal = "temporal"
    case emotional = "emotional"
}

struct MoodImpact: Codable {
    let targetMood: Mood
    let intensity: Double
    let direction: ImpactDirection
}

enum ImpactDirection: String, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
}

struct LexicalTrigger: Codable {
    let name: String
    let keywords: [String]
    let confidence: Double
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
}

struct SemanticTrigger: Codable {
    let name: String
    let concepts: [String]
    let confidence: Double
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
}

struct ContextualPattern: Codable {
    let name: String
    let patternType: ContextualPatternType
    let contextWindowSize: Int
    let confidence: Double
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
}

enum ContextualPatternType: String, Codable {
    case escalation = "escalation"
    case repetition = "repetition"
    case contradiction = "contradiction"
    case avoidance = "avoidance"
}

struct TemporalTriggerPattern: Codable {
    let name: String
    let temporalType: TemporalTriggerType
    let confidence: Double
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
}

enum TemporalTriggerType: Codable {
    case timeOfDay(ClosedRange<Int>)
    case dayOfWeek([Int])
    case anniversary(Date)
    case recurring(Int) // Days between occurrences
}

struct ConversationalTrigger: Codable {
    let name: String
    let triggerType: ConversationalTriggerType
    let confidence: Double
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
}

enum ConversationalTriggerType: String, Codable {
    case topicShift = "topicShift"
    case emotionalIntensity = "emotionalIntensity"
    case communicationPattern = "communicationPattern"
    case responseLength = "responseLength"
}

struct PersonalizedTrigger: Codable {
    let name: String
    var personalKeywords: [String]
    var associatedMoods: [Mood]
    var frequency: Int
    var historicalAccuracy: Double
    var lastDetected: Date
    let moodImpact: MoodImpact
    let severity: TriggerSeverity
    let category: TriggerCategory
}

enum TriggerTimeframe: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    
    var displayName: String { rawValue }
}

struct TriggerInsights {
    let timeframe: TriggerTimeframe
    let mostFrequentTriggers: [(trigger: String, frequency: Int)]
    let strongestMoodCorrelations: [(trigger: String, mood: Mood, correlation: Double)]
    let triggerClusters: [TriggerCluster]
    let intensityPatterns: TriggerIntensityPattern
    let copingStrategies: [CopingStrategy]
    let overallTriggerSensitivity: Double
    let recommendations: [String]
}

struct TriggerCluster {
    let triggerNames: [String]
    let frequency: Int
    let averageTimeSpan: TimeInterval
}

struct TriggerIntensityPattern {
    let averageIntensity: Double
    let volatility: Double
    let peakIntensity: Double
    let trend: IntensityTrend
}

enum IntensityTrend {
    case increasing
    case decreasing
    case stable
}

struct CopingStrategy {
    let triggerName: String
    let strategy: String
    let effectiveness: Double
    let category: CopingStrategyCategory
}

enum CopingStrategyCategory {
    case prevention
    case response
    case recovery
}

struct TriggerAlert {
    let id: UUID
    let trigger: DetectedTrigger
    let alertType: AlertType
    let message: String
    let timestamp: Date
    var isActive: Bool
}

enum AlertType {
    case info
    case warning
    case critical
}

struct PersonalizedTriggerProfile {
    let triggerCategories: [TriggerCategory: Int]
    let sensitivityProfile: SensitivityProfile
    let protectiveStrategies: [String]
    let growthAreas: [String]
    let triggerResilience: Double
}

struct SensitivityProfile {
    let overall: Double
    let highIntensity: Double
    let mediumIntensity: Double
}

struct TriggerHistoryEntry {
    let id: UUID
    let triggerName: String
    let intensity: Double
    let timestamp: Date
}

// Analysis Result Structures
struct SemanticMatchResult {
    let confidence: Double
    let reasoning: String
    let matchedText: String
}

struct ContextualPatternMatch {
    let isMatch: Bool
    let description: String
    let relevantText: String
}

struct TemporalMatch {
    let isMatch: Bool
    let description: String
}

struct ConversationalTriggerResult {
    let isTriggered: Bool
    let reasoning: String
    let triggerText: String
}

struct PersonalizedTriggerResult {
    let confidence: Double
    let reasoning: String
    let matchedText: String
}