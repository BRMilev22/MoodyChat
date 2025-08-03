//
//  ProgressiveMoodDetector.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import Foundation
import SwiftUI

class ProgressiveMoodDetector: ObservableObject {
    static let shared = ProgressiveMoodDetector()
    
    @Published var currentMood: Mood = .neutral
    @Published var moodConfidence: Double = 0.0
    @Published var uiIntensity: UIIntensity = .neutral
    @Published var transitionCoordinator = MoodTransitionCoordinator()
    
    private var userMessages: [String] = []
    private var moodHistory: [MoodReading] = []
    private let fastAnalyzer = FastMoodAnalyzer.shared
    
    private init() {}
    
    // Main function - analyzes new message and updates UI progressively
    func analyzeMessage(_ text: String) async {
        userMessages.append(text)
        
        // STEP 1: Quick initial mood detection
        let detectedMood = await fastAnalyzer.analyzeMoodFast(text: text)
        let initialConfidence = calculateInitialConfidence(for: detectedMood)
        
        // STEP 2: Add to history and update UI immediately with initial reading
        let reading = MoodReading(mood: detectedMood, confidence: initialConfidence, timestamp: Date())
        moodHistory.append(reading)
        
        // Keep only recent history (last 15 messages for better context)
        if moodHistory.count > 15 {
            moodHistory.removeFirst()
        }
        
        // STEP 3: Calculate and update UI immediately
        let (quickMood, quickConfidence) = calculateOverallMood()
        await MainActor.run {
            updateUI(mood: quickMood, confidence: quickConfidence)
        }
        
        // STEP 4: Perform deeper analysis in background for refinement
        Task.detached(priority: .background) {
            await self.performDeepAnalysis(text: text, currentMood: detectedMood)
        }
    }
    
    // Deep analysis considers conversation patterns and context
    private func performDeepAnalysis(text: String, currentMood: Mood) async {
        // Analyze conversation patterns
        let conversationContext = analyzeConversationPatterns()
        
        // Calculate enhanced confidence based on conversation history
        let enhancedConfidence = calculateEnhancedConfidence(
            for: currentMood,
            withContext: conversationContext
        )
        
        // Update the most recent reading with enhanced confidence
        if !moodHistory.isEmpty {
            moodHistory[moodHistory.count - 1] = MoodReading(
                mood: currentMood,
                confidence: enhancedConfidence,
                timestamp: moodHistory.last?.timestamp ?? Date()
            )
        }
        
        // Recalculate overall mood with enhanced data
        let (refinedMood, refinedConfidence) = calculateOverallMood()
        
        // Update UI with refined analysis
        await MainActor.run {
            updateUI(mood: refinedMood, confidence: refinedConfidence)
        }
    }
    
    private func calculateInitialConfidence(for mood: Mood) -> Double {
        // Base confidence from message analysis (lower for immediate response)
        var confidence = 0.3
        
        // Increase confidence if mood is consistent with recent history
        let recentMoods = moodHistory.suffix(3).map { $0.mood }
        let consistentMoods = recentMoods.filter { $0 == mood }.count
        confidence += Double(consistentMoods) * 0.15
        
        // Increase confidence with more messages
        confidence += min(Double(userMessages.count) * 0.05, 0.3)
        
        return min(confidence, 0.7) // Cap initial confidence for refinement
    }
    
    private func calculateEnhancedConfidence(for mood: Mood, withContext context: MoodAnalysisContext) -> Double {
        var confidence = 0.5
        
        // Factor in conversation patterns
        if context.moodConsistency > 0.7 {
            confidence += 0.2
        }
        
        // Factor in emotional trajectory
        if context.isEmotionallyCoherent {
            confidence += 0.15
        }
        
        // Factor in conversation length
        confidence += min(Double(userMessages.count) * 0.02, 0.25)
        
        return min(confidence, 1.0)
    }
    
    private func analyzeConversationPatterns() -> MoodAnalysisContext {
        let recentMoods = moodHistory.suffix(5).map { $0.mood }
        
        // Calculate mood consistency
        let moodCounts = Dictionary(grouping: recentMoods) { $0 }.mapValues { $0.count }
        let dominantMoodCount = moodCounts.values.max() ?? 0
        let consistency = Double(dominantMoodCount) / Double(recentMoods.count)
        
        // Check emotional coherence (smooth transitions vs erratic changes)
        let isCoherent = checkEmotionalCoherence(moods: recentMoods)
        
        return MoodAnalysisContext(
            moodConsistency: consistency,
            isEmotionallyCoherent: isCoherent,
            conversationLength: userMessages.count
        )
    }
    
    private func checkEmotionalCoherence(moods: [Mood]) -> Bool {
        guard moods.count > 2 else { return true }
        
        // Check if mood changes make emotional sense
        var coherentTransitions = 0
        
        for i in 1..<moods.count - 1 {
            let previous = moods[i-1]
            let current = moods[i]
            let next = moods[i+1]
            
            // Consider transition coherent if there's gradual change or consistency
            if isGradualTransition(from: previous, to: current, to: next) {
                coherentTransitions += 1
            }
        }
        
        return Double(coherentTransitions) / Double(moods.count - 2) > 0.6
    }
    
    private func isGradualTransition(from mood1: Mood, to mood2: Mood, to mood3: Mood) -> Bool {
        // Define mood families for gradual transitions
        let positive: Set<Mood> = [.happy, .excited, .loving, .peaceful]
        let negative: Set<Mood> = [.sad, .angry, .frustrated, .anxious]
        let neutral: Set<Mood> = [.neutral, .confused]
        
        let moods = [mood1, mood2, mood3]
        
        // Check if moods stay within same family or gradually transition
        let positiveCount = moods.filter { positive.contains($0) }.count
        let negativeCount = moods.filter { negative.contains($0) }.count
        let neutralCount = moods.filter { neutral.contains($0) }.count
        
        // Coherent if mostly in one family or gradual shift
        return positiveCount >= 2 || negativeCount >= 2 || neutralCount >= 2
    }
    
    private func calculateOverallMood() -> (Mood, Double) {
        guard !moodHistory.isEmpty else { return (.neutral, 0.0) }
        
        // Weight recent readings more heavily
        var weightedMoods: [Mood: Double] = [:]
        let totalReadings = moodHistory.count
        
        for (index, reading) in moodHistory.enumerated() {
            let weight = Double(index + 1) / Double(totalReadings) // More weight to recent
            weightedMoods[reading.mood, default: 0.0] += weight * reading.confidence
        }
        
        // Find the dominant mood
        let dominantMood = weightedMoods.max(by: { $0.value < $1.value })?.key ?? .neutral
        let confidence = weightedMoods[dominantMood] ?? 0.0
        
        return (dominantMood, min(confidence, 1.0))
    }
    
    private func updateUI(mood: Mood, confidence: Double) {
        let previousMood = self.currentMood
        let previousConfidence = self.moodConfidence
        
        print("🎭 Mood Update: \(previousMood.displayName) → \(mood.displayName) (confidence: \(confidence))")
        
        // Check if this is a significant mood change that deserves animation
        let moodChanged = previousMood != mood
        let confidenceIncreased = confidence > previousConfidence + 0.2
        let isHighConfidence = confidence > 0.3 // Lower threshold for more animations
        
        let isSignificantChange = (moodChanged && isHighConfidence) || confidenceIncreased
        
        print("🎨 Significant change: \(isSignificantChange) (moodChanged: \(moodChanged), confidence: \(confidence))")
        
        if isSignificantChange {
            print("🚀 Triggering transition animation!")
            // FORCE immediate dramatic UI update first
            updateMoodDirectly(mood: mood, confidence: confidence)
            
            // Then trigger animation (if it works, great; if not, we still have dramatic UI)
            transitionCoordinator.triggerMoodTransition(
                from: previousMood,
                to: mood,
                confidence: confidence
            )
        } else {
            print("⚡ Direct UI update")
            // Direct update for subtle changes
            updateMoodDirectly(mood: mood, confidence: confidence)
        }
    }
    
    func applyMoodTransition(mood: Mood, confidence: Double) {
        updateMoodDirectly(mood: mood, confidence: confidence)
    }
    
    private func updateMoodDirectly(mood: Mood, confidence: Double) {
        self.currentMood = mood
        self.moodConfidence = confidence
        
        // MAXIMUM aggressive UI intensity (immediate drama!)
        switch confidence {
        case 0.0..<0.1:
            self.uiIntensity = .neutral
        case 0.1..<0.3:
            self.uiIntensity = .confident(mood) // Skip subtle, go straight to confident
        default:
            self.uiIntensity = .dramatic(mood) // Everything above 0.3 is dramatic
        }
        
        print("🎨 UI Intensity set to: \(self.uiIntensity.description)")
    }
    
    func resetMoodHistory() {
        userMessages.removeAll()
        moodHistory.removeAll()
        currentMood = .neutral
        moodConfidence = 0.0
        uiIntensity = .neutral
    }
}

// MARK: - Supporting Types

struct MoodReading {
    let mood: Mood
    let confidence: Double
    let timestamp: Date
}

struct MoodAnalysisContext {
    let moodConsistency: Double
    let isEmotionallyCoherent: Bool
    let conversationLength: Int
}

enum UIIntensity: Equatable {
    case neutral
    case subtle(Mood)
    case confident(Mood)
    case dramatic(Mood)
    
    var description: String {
        switch self {
        case .neutral: return "Neutral"
        case .subtle(let mood): return "Subtle \(mood.displayName)"
        case .confident(let mood): return "Confident \(mood.displayName)"
        case .dramatic(let mood): return "Dramatic \(mood.displayName)"
        }
    }
}