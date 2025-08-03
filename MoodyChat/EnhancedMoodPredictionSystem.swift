//
//  EnhancedMoodPredictionSystem.swift
//  MoodyChat
//
//  Created by Boris Milev on 3.08.25.
//

import Foundation
import SwiftUI

// MARK: - Enhanced Mood Prediction System

class EnhancedMoodPredictionSystem: ObservableObject {
    static let shared = EnhancedMoodPredictionSystem()
    
    @Published var currentPrediction: MoodPrediction?
    @Published var predictionHistory: [MoodPrediction] = []
    @Published var predictionAccuracy: Double = 0.0
    
    private let memorySystem = ConversationMemorySystem.shared
    private let historyPersistence = MoodHistoryPersistence.shared
    private let userDefaults = UserDefaults.standard
    
    // Prediction models
    private var temporalPatterns: [TemporalMoodPattern] = []
    private var contextualTriggers: [ContextualTrigger] = []
    private var sequencePatterns: [MoodSequencePattern] = []
    private var personalityBasedPredictors: [PersonalityPredictor] = []
    
    private init() {
        loadPredictionModels()
        calculateCurrentAccuracy()
    }
    
    // MARK: - Core Prediction Functions
    
    func predictNextMood(
        currentMood: Mood,
        currentText: String,
        conversationContext: [Message],
        timeContext: TimeContext = TimeContext()
    ) -> MoodPrediction {
        
        var predictions: [WeightedMoodPrediction] = []
        
        // 1. Temporal Pattern Prediction
        predictions.append(contentsOf: predictFromTemporalPatterns(
            currentMood: currentMood,
            timeContext: timeContext
        ))
        
        // 2. Sequence Pattern Prediction
        predictions.append(contentsOf: predictFromSequencePatterns(
            currentMood: currentMood,
            recentMoods: extractRecentMoods(from: conversationContext)
        ))
        
        // 3. Contextual Trigger Prediction
        predictions.append(contentsOf: predictFromContextualTriggers(
            currentText: currentText,
            conversationContext: conversationContext
        ))
        
        // 4. Personality-Based Prediction
        predictions.append(contentsOf: predictFromPersonality(
            currentMood: currentMood,
            currentText: currentText
        ))
        
        // 5. Statistical Pattern Prediction
        predictions.append(contentsOf: predictFromStatisticalPatterns(
            currentMood: currentMood,
            timeContext: timeContext
        ))
        
        // Combine predictions using ensemble method
        let finalPrediction = combineWeightedPredictions(predictions)
        
        // Validate and enhance prediction
        let enhancedPrediction = enhancePrediction(
            prediction: finalPrediction,
            currentMood: currentMood,
            context: currentText
        )
        
        // Store prediction for accuracy tracking
        storePrediction(enhancedPrediction)
        
        currentPrediction = enhancedPrediction
        return enhancedPrediction
    }
    
    func updatePredictionAccuracy(actualMood: Mood, predictedMood: Mood) {
        // Update accuracy based on how close the prediction was
        let accuracy = calculateMoodPredictionAccuracy(predicted: predictedMood, actual: actualMood)
        
        // Store accuracy sample
        let accuracySample = AccuracySample(
            predicted: predictedMood,
            actual: actualMood,
            accuracy: accuracy,
            timestamp: Date()
        )
        
        var samples = loadAccuracySamples()
        samples.append(accuracySample)
        
        // Keep only recent samples (last 100)
        if samples.count > 100 {
            samples.removeFirst()
        }
        
        saveAccuracySamples(samples)
        calculateCurrentAccuracy()
        
        // Update prediction models based on accuracy
        updatePredictionModels(based: accuracySample)
    }
    
    func getPersonalizedMoodInsights() -> PersonalizedMoodInsights {
        let recentPredictions = predictionHistory.suffix(20)
        
        // Analyze prediction patterns
        let mostPredictedMood = findMostFrequentPredictedMood(in: Array(recentPredictions))
        let predictionConfidencePattern = analyzePredictionConfidencePattern(in: Array(recentPredictions))
        let volatilityScore = calculateMoodVolatilityScore()
        
        // Generate personalized insights
        let insights = generatePersonalizedInsights(
            mostPredicted: mostPredictedMood,
            confidencePattern: predictionConfidencePattern,
            volatility: volatilityScore
        )
        
        return PersonalizedMoodInsights(
            dominantMoodTrend: mostPredictedMood,
            volatilityScore: volatilityScore,
            predictionReliability: predictionAccuracy,
            personalizedInsights: insights,
            recommendedStrategies: generatePersonalizedStrategies(volatility: volatilityScore)
        )
    }
    
    // MARK: - Prediction Methods
    
    private func predictFromTemporalPatterns(
        currentMood: Mood,
        timeContext: TimeContext
    ) -> [WeightedMoodPrediction] {
        
        var predictions: [WeightedMoodPrediction] = []
        
        // Day of week patterns
        if let dayPattern = temporalPatterns.first(where: { 
            $0.type == .dayOfWeek(timeContext.dayOfWeek) 
        }) {
            predictions.append(WeightedMoodPrediction(
                mood: dayPattern.predictedMood,
                confidence: dayPattern.confidence,
                weight: 0.3,
                source: "Day of week pattern",
                reasoning: "Based on your \(timeContext.dayOfWeekName) mood patterns"
            ))
        }
        
        // Time of day patterns
        if let timePattern = temporalPatterns.first(where: { 
            $0.type == .timeOfDay(timeContext.timeOfDay) 
        }) {
            predictions.append(WeightedMoodPrediction(
                mood: timePattern.predictedMood,
                confidence: timePattern.confidence,
                weight: 0.25,
                source: "Time of day pattern",
                reasoning: "Your \(timeContext.timeOfDay.description) emotions tend toward \(timePattern.predictedMood.displayName)"
            ))
        }
        
        return predictions
    }
    
    private func predictFromSequencePatterns(
        currentMood: Mood,
        recentMoods: [Mood]
    ) -> [WeightedMoodPrediction] {
        
        var predictions: [WeightedMoodPrediction] = []
        
        // Look for matching sequence patterns
        let currentSequence = (recentMoods + [currentMood]).suffix(3)
        
        for pattern in sequencePatterns {
            if pattern.sequence.count <= currentSequence.count {
                let lastElements = Array(currentSequence.suffix(pattern.sequence.count))
                if lastElements == pattern.sequence {
                    predictions.append(WeightedMoodPrediction(
                        mood: pattern.nextMood,
                        confidence: pattern.confidence,
                        weight: 0.4,
                        source: "Sequence pattern",
                        reasoning: "Your mood sequence \(pattern.sequence.map { $0.displayName }.joined(separator: " → ")) typically leads to \(pattern.nextMood.displayName)"
                    ))
                }
            }
        }
        
        return predictions
    }
    
    private func predictFromContextualTriggers(
        currentText: String,
        conversationContext: [Message]
    ) -> [WeightedMoodPrediction] {
        
        var predictions: [WeightedMoodPrediction] = []
        let lowerText = currentText.lowercased()
        
        for trigger in contextualTriggers {
            if trigger.keywords.contains(where: { lowerText.contains($0) }) {
                predictions.append(WeightedMoodPrediction(
                    mood: trigger.predictedMood,
                    confidence: trigger.confidence,
                    weight: 0.35,
                    source: "Contextual trigger",
                    reasoning: "Text patterns suggest a shift toward \(trigger.predictedMood.displayName)"
                ))
            }
        }
        
        return predictions
    }
    
    private func predictFromPersonality(
        currentMood: Mood,
        currentText: String
    ) -> [WeightedMoodPrediction] {
        
        var predictions: [WeightedMoodPrediction] = []
        
        guard let personality = memorySystem.personalityInsights else {
            return predictions
        }
        
        for predictor in personalityBasedPredictors {
            if predictor.personalityTraits.contains(where: { personality.traits.contains($0) }) {
                let moodTransition = predictor.moodTransitions.first { $0.fromMood == currentMood }
                
                if let transition = moodTransition {
                    predictions.append(WeightedMoodPrediction(
                        mood: transition.toMood,
                        confidence: transition.probability,
                        weight: 0.2,
                        source: "Personality pattern",
                        reasoning: "Your personality profile suggests a tendency toward \(transition.toMood.displayName)"
                    ))
                }
            }
        }
        
        return predictions
    }
    
    private func predictFromStatisticalPatterns(
        currentMood: Mood,
        timeContext: TimeContext
    ) -> [WeightedMoodPrediction] {
        
        var predictions: [WeightedMoodPrediction] = []
        
        // Get historical mood transitions
        let moodHistory = historyPersistence.getMoodHistory(for: .month)
        let transitions = extractMoodTransitions(from: moodHistory)
        
        // Find transitions from current mood
        let currentMoodTransitions = transitions.filter { $0.fromMood == currentMood }
        
        if !currentMoodTransitions.isEmpty {
            // Calculate probability distribution
            let transitionCounts = Dictionary(grouping: currentMoodTransitions) { $0.toMood }
                .mapValues { $0.count }
            
            let totalTransitions = currentMoodTransitions.count
            
            // Get most likely transition
            if let mostLikely = transitionCounts.max(by: { $0.value < $1.value }) {
                let probability = Double(mostLikely.value) / Double(totalTransitions)
                
                predictions.append(WeightedMoodPrediction(
                    mood: mostLikely.key,
                    confidence: probability,
                    weight: 0.3,
                    source: "Statistical pattern",
                    reasoning: "Historically, your \(currentMood.displayName) mood transitions to \(mostLikely.key.displayName) \(Int(probability * 100))% of the time"
                ))
            }
        }
        
        return predictions
    }
    
    private func combineWeightedPredictions(_ predictions: [WeightedMoodPrediction]) -> MoodPrediction {
        guard !predictions.isEmpty else {
            return MoodPrediction(
                predictedMood: .neutral,
                confidence: 0.1,
                timeframe: "next few messages",
                reasoning: "Insufficient data for prediction",
                alternativeMoods: [],
                influencingFactors: []
            )
        }
        
        // Group predictions by mood
        let groupedPredictions = Dictionary(grouping: predictions) { $0.mood }
        
        // Calculate weighted scores for each mood
        let moodScores = groupedPredictions.mapValues { predictions in
            predictions.reduce(0.0) { total, prediction in
                total + (prediction.confidence * prediction.weight)
            }
        }
        
        // Find the highest scoring mood
        guard let topMood = moodScores.max(by: { $0.value < $1.value }) else {
            return MoodPrediction(
                predictedMood: .neutral,
                confidence: 0.1,
                timeframe: "next few messages",
                reasoning: "Unable to determine prediction",
                alternativeMoods: [],
                influencingFactors: []
            )
        }
        
        // Calculate confidence (normalized)
        let totalScore = moodScores.values.reduce(0, +)
        let confidence = min(topMood.value / totalScore, 1.0)
        
        // Get alternative moods
        let sortedMoods = moodScores.sorted { $0.value > $1.value }
        let alternativeMoods = Array(sortedMoods.dropFirst().prefix(2).map { 
            AlternativeMoodPrediction(mood: $0.key, probability: $0.value / totalScore)
        })
        
        // Get reasoning from top predictions
        let topPredictions = predictions.filter { $0.mood == topMood.key }
        let reasoning = topPredictions.first?.reasoning ?? "Based on multiple factors"
        
        // Extract influencing factors
        let factors = Array(Set(predictions.map { $0.source }))
        
        return MoodPrediction(
            predictedMood: topMood.key,
            confidence: confidence,
            timeframe: "within the next few messages",
            reasoning: reasoning,
            alternativeMoods: alternativeMoods,
            influencingFactors: factors
        )
    }
    
    private func enhancePrediction(
        prediction: MoodPrediction,
        currentMood: Mood,
        context: String
    ) -> MoodPrediction {
        
        var enhancedPrediction = prediction
        
        // Adjust confidence based on context clarity
        let contextClarity = analyzeContextClarity(context)
        enhancedPrediction.confidence *= contextClarity
        
        // Add uncertainty if prediction is same as current mood
        if prediction.predictedMood == currentMood {
            enhancedPrediction.confidence *= 0.8
            enhancedPrediction.reasoning += " (maintaining current state)"
        }
        
        // Add temporal considerations
        enhancedPrediction.timeframe = determineTimeframe(based: enhancedPrediction.confidence)
        
        return enhancedPrediction
    }
    
    // MARK: - Model Learning and Updates
    
    private func updatePredictionModels(based sample: AccuracySample) {
        // Update temporal patterns
        updateTemporalPatterns(sample: sample)
        
        // Update sequence patterns
        updateSequencePatterns(sample: sample)
        
        // Update contextual triggers
        updateContextualTriggers(sample: sample)
        
        // Update personality predictors
        updatePersonalityPredictors(sample: sample)
        
        savePredictionModels()
    }
    
    private func updateTemporalPatterns(sample: AccuracySample) {
        let timeContext = TimeContext(date: sample.timestamp)
        
        // Update day of week pattern
        if let patternIndex = temporalPatterns.firstIndex(where: { 
            $0.type == .dayOfWeek(timeContext.dayOfWeek) 
        }) {
            temporalPatterns[patternIndex].updateAccuracy(sample.accuracy)
        } else if sample.accuracy > 0.6 {
            // Create new pattern if accuracy is good
            temporalPatterns.append(TemporalMoodPattern(
                type: .dayOfWeek(timeContext.dayOfWeek),
                predictedMood: sample.actual,
                confidence: sample.accuracy,
                sampleCount: 1
            ))
        }
    }
    
    private func updateSequencePatterns(sample: AccuracySample) {
        // This would analyze recent mood sequences and update patterns
        // Implementation would depend on having access to the sequence that led to this prediction
    }
    
    private func updateContextualTriggers(sample: AccuracySample) {
        // Update trigger accuracy based on successful predictions
        for i in 0..<contextualTriggers.count {
            if contextualTriggers[i].predictedMood == sample.actual {
                contextualTriggers[i].updateConfidence(sample.accuracy)
            }
        }
    }
    
    private func updatePersonalityPredictors(sample: AccuracySample) {
        // Update personality-based predictions based on accuracy
        for i in 0..<personalityBasedPredictors.count {
            personalityBasedPredictors[i].updateAccuracy(sample.accuracy)
        }
    }
    
    // MARK: - Analysis Helper Methods
    
    private func extractRecentMoods(from messages: [Message]) -> [Mood] {
        return messages
            .filter { $0.isFromUser }
            .compactMap { $0.sentiment?.mood }
            .suffix(5)
            .reversed()
    }
    
    private func extractMoodTransitions(from history: [MoodHistoryEntry]) -> [MoodTransition] {
        var transitions: [MoodTransition] = []
        
        let sortedHistory = history.sorted { $0.timestamp < $1.timestamp }
        
        for i in 1..<sortedHistory.count {
            let fromMood = sortedHistory[i-1].mood
            let toMood = sortedHistory[i].mood
            
            if fromMood != toMood {
                transitions.append(MoodTransition(
                    fromMood: fromMood,
                    toMood: toMood,
                    timestamp: sortedHistory[i].timestamp
                ))
            }
        }
        
        return transitions
    }
    
    private func calculateMoodPredictionAccuracy(predicted: Mood, actual: Mood) -> Double {
        if predicted == actual {
            return 1.0
        }
        
        // Calculate similarity between moods
        let moodSimilarity = calculateMoodSimilarity(mood1: predicted, mood2: actual)
        return moodSimilarity
    }
    
    private func calculateMoodSimilarity(mood1: Mood, mood2: Mood) -> Double {
        // Define mood categories for similarity calculation
        let positiveMoods: Set<Mood> = [.happy, .excited, .loving, .peaceful]
        let negativeMoods: Set<Mood> = [.sad, .angry, .frustrated, .anxious]
        let neutralMoods: Set<Mood> = [.neutral, .confused]
        
        // Same category gets partial credit
        if (positiveMoods.contains(mood1) && positiveMoods.contains(mood2)) ||
           (negativeMoods.contains(mood1) && negativeMoods.contains(mood2)) ||
           (neutralMoods.contains(mood1) && neutralMoods.contains(mood2)) {
            return 0.5
        }
        
        return 0.0
    }
    
    private func analyzeContextClarity(_ context: String) -> Double {
        // Analyze how clear the emotional context is
        let emotionalWords = ["feel", "feeling", "emotion", "mood", "happy", "sad", "angry", "excited", "anxious", "peaceful", "frustrated", "loving", "confused"]
        
        let wordsInContext = emotionalWords.filter { context.lowercased().contains($0) }.count
        let clarity = min(Double(wordsInContext) / 3.0, 1.0) // Normalize to max 1.0
        
        return max(clarity, 0.3) // Minimum clarity of 0.3
    }
    
    private func determineTimeframe(based confidence: Double) -> String {
        switch confidence {
        case 0.8...:
            return "within the next message"
        case 0.6..<0.8:
            return "within the next few messages"
        case 0.4..<0.6:
            return "in the near future"
        default:
            return "at some point in this conversation"
        }
    }
    
    private func findMostFrequentPredictedMood(in predictions: [MoodPrediction]) -> Mood {
        let moodCounts = Dictionary(grouping: predictions) { $0.predictedMood }
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
    
    private func analyzePredictionConfidencePattern(in predictions: [MoodPrediction]) -> String {
        let averageConfidence = predictions.map { $0.confidence }.reduce(0, +) / Double(predictions.count)
        
        switch averageConfidence {
        case 0.7...:
            return "High confidence predictions"
        case 0.4..<0.7:
            return "Moderate confidence predictions"
        default:
            return "Lower confidence predictions"
        }
    }
    
    private func calculateMoodVolatilityScore() -> Double {
        let recentHistory = historyPersistence.getMoodHistory(for: .week)
        guard recentHistory.count > 3 else { return 0.0 }
        
        let moodValues = recentHistory.map { moodToNumericalValue($0.mood) }
        let mean = moodValues.reduce(0, +) / Double(moodValues.count)
        let variance = moodValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(moodValues.count)
        
        return min(sqrt(variance) / 2.0, 1.0) // Normalize to 0-1
    }
    
    private func moodToNumericalValue(_ mood: Mood) -> Double {
        switch mood {
        case .excited: return 2.0
        case .happy: return 1.5
        case .loving: return 1.7
        case .peaceful: return 1.0
        case .neutral: return 0.0
        case .confused: return -0.3
        case .anxious: return -1.0
        case .frustrated: return -1.2
        case .sad: return -1.5
        case .angry: return -2.0
        }
    }
    
    private func generatePersonalizedInsights(
        mostPredicted: Mood,
        confidencePattern: String,
        volatility: Double
    ) -> String {
        var insights: [String] = []
        
        insights.append("Your emotional patterns show a tendency toward \(mostPredicted.displayName.lowercased()) states.")
        insights.append("Prediction confidence: \(confidencePattern.lowercased()).")
        
        switch volatility {
        case 0.7...:
            insights.append("You experience high emotional variability, which can indicate rich emotional awareness.")
        case 0.3..<0.7:
            insights.append("Your emotional patterns show moderate variability with some consistency.")
        default:
            insights.append("Your emotions show remarkable stability and consistency.")
        }
        
        return insights.joined(separator: " ")
    }
    
    private func generatePersonalizedStrategies(volatility: Double) -> [String] {
        var strategies: [String] = []
        
        if volatility > 0.7 {
            strategies.append("Practice grounding techniques during emotional transitions")
            strategies.append("Consider journaling to track emotional patterns")
            strategies.append("Develop coping strategies for intense emotional experiences")
        } else if volatility > 0.3 {
            strategies.append("Continue building emotional awareness")
            strategies.append("Notice patterns in your emotional cycles")
            strategies.append("Use your emotional stability as a strength")
        } else {
            strategies.append("Explore expanding your emotional range safely")
            strategies.append("Consider what emotions you might be avoiding")
            strategies.append("Use your stability to support others")
        }
        
        return strategies
    }
    
    // MARK: - Persistence
    
    private func storePrediction(_ prediction: MoodPrediction) {
        predictionHistory.append(prediction)
        
        // Keep only recent predictions
        if predictionHistory.count > 50 {
            predictionHistory.removeFirst()
        }
        
        // Save to UserDefaults (simple implementation)
        if let data = try? JSONEncoder().encode(predictionHistory) {
            userDefaults.set(data, forKey: "predictionHistory")
        }
    }
    
    private func calculateCurrentAccuracy() {
        let samples = loadAccuracySamples()
        guard !samples.isEmpty else {
            predictionAccuracy = 0.0
            return
        }
        
        predictionAccuracy = samples.map { $0.accuracy }.reduce(0, +) / Double(samples.count)
    }
    
    private func loadAccuracySamples() -> [AccuracySample] {
        guard let data = userDefaults.data(forKey: "accuracySamples"),
              let samples = try? JSONDecoder().decode([AccuracySample].self, from: data) else {
            return []
        }
        return samples
    }
    
    private func saveAccuracySamples(_ samples: [AccuracySample]) {
        if let data = try? JSONEncoder().encode(samples) {
            userDefaults.set(data, forKey: "accuracySamples")
        }
    }
    
    private func loadPredictionModels() {
        // Load temporal patterns
        if let data = userDefaults.data(forKey: "temporalPatterns"),
           let patterns = try? JSONDecoder().decode([TemporalMoodPattern].self, from: data) {
            temporalPatterns = patterns
        } else {
            initializeDefaultTemporalPatterns()
        }
        
        // Load other patterns...
        initializeDefaultPatternsIfNeeded()
    }
    
    private func savePredictionModels() {
        // Save temporal patterns
        if let data = try? JSONEncoder().encode(temporalPatterns) {
            userDefaults.set(data, forKey: "temporalPatterns")
        }
        
        // Save other patterns...
    }
    
    private func initializeDefaultTemporalPatterns() {
        // Initialize with common patterns
        temporalPatterns = [
            TemporalMoodPattern(type: .dayOfWeek(2), predictedMood: .neutral, confidence: 0.6, sampleCount: 0), // Monday
            TemporalMoodPattern(type: .dayOfWeek(6), predictedMood: .happy, confidence: 0.7, sampleCount: 0), // Friday
            TemporalMoodPattern(type: .timeOfDay(.morning), predictedMood: .peaceful, confidence: 0.5, sampleCount: 0),
            TemporalMoodPattern(type: .timeOfDay(.evening), predictedMood: .neutral, confidence: 0.5, sampleCount: 0)
        ]
    }
    
    private func initializeDefaultPatternsIfNeeded() {
        if contextualTriggers.isEmpty {
            contextualTriggers = [
                ContextualTrigger(keywords: ["work", "job", "boss"], predictedMood: .anxious, confidence: 0.6),
                ContextualTrigger(keywords: ["weekend", "vacation", "fun"], predictedMood: .happy, confidence: 0.7),
                ContextualTrigger(keywords: ["tired", "exhausted", "sleep"], predictedMood: .neutral, confidence: 0.5)
            ]
        }
    }
}

// MARK: - Data Models

struct MoodPrediction: Identifiable, Codable {
    let id = UUID()
    let predictedMood: Mood
    var confidence: Double
    var timeframe: String
    var reasoning: String
    let alternativeMoods: [AlternativeMoodPrediction]
    let influencingFactors: [String]
    let timestamp = Date()
}

struct WeightedMoodPrediction {
    let mood: Mood
    let confidence: Double
    let weight: Double
    let source: String
    let reasoning: String
}

struct AlternativeMoodPrediction: Codable {
    let mood: Mood
    let probability: Double
}

struct AccuracySample: Codable {
    let predicted: Mood
    let actual: Mood
    let accuracy: Double
    let timestamp: Date
}

struct TimeContext {
    let dayOfWeek: Int
    let timeOfDay: TimeOfDay
    let date: Date
    
    init(date: Date = Date()) {
        self.date = date
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
        
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:
            self.timeOfDay = .morning
        case 12..<17:
            self.timeOfDay = .afternoon
        case 17..<21:
            self.timeOfDay = .evening
        default:
            self.timeOfDay = .night
        }
    }
    
    var dayOfWeekName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    var description: String { rawValue }
}

enum TemporalPatternType: Codable, Equatable {
    case dayOfWeek(Int)
    case timeOfDay(TimeOfDay)
}

struct TemporalMoodPattern: Codable {
    let type: TemporalPatternType
    var predictedMood: Mood
    var confidence: Double
    var sampleCount: Int
    
    mutating func updateAccuracy(_ accuracy: Double) {
        // Simple learning rate
        let learningRate = 0.1
        confidence = confidence * (1 - learningRate) + accuracy * learningRate
        sampleCount += 1
    }
}

struct MoodSequencePattern: Codable {
    let sequence: [Mood]
    let nextMood: Mood
    var confidence: Double
    var frequency: Int
}

struct ContextualTrigger: Codable {
    let keywords: [String]
    var predictedMood: Mood
    var confidence: Double
    
    mutating func updateConfidence(_ newAccuracy: Double) {
        confidence = (confidence + newAccuracy) / 2.0
    }
}

struct PersonalityPredictor: Codable {
    let personalityTraits: [String]
    let moodTransitions: [MoodTransitionProbability]
    var accuracy: Double
    
    mutating func updateAccuracy(_ newAccuracy: Double) {
        accuracy = (accuracy + newAccuracy) / 2.0
    }
}

struct MoodTransitionProbability: Codable {
    let fromMood: Mood
    let toMood: Mood
    let probability: Double
}

struct MoodTransition {
    let fromMood: Mood
    let toMood: Mood
    let timestamp: Date
}

struct PersonalizedMoodInsights {
    let dominantMoodTrend: Mood
    let volatilityScore: Double
    let predictionReliability: Double
    let personalizedInsights: String
    let recommendedStrategies: [String]
}