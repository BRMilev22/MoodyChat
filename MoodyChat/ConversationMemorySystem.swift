//
//  ConversationMemorySystem.swift
//  MoodyChat
//
//  Created by Boris Milev on 3.08.25.
//

import Foundation
import SwiftUI

// MARK: - Conversation Memory System

class ConversationMemorySystem: ObservableObject {
    static let shared = ConversationMemorySystem()
    
    @Published var emotionalProfile: EmotionalProfile?
    @Published var conversationContexts: [ConversationContext] = []
    @Published var personalityInsights: PersonalityInsights?
    @Published var moodPatterns: [MoodPattern] = []
    
    private let maxContextHistory = 50
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadMemoryData()
    }
    
    // MARK: - Core Memory Functions
    
    func updateConversationMemory(with conversation: Conversation) {
        // Update emotional profile
        updateEmotionalProfile(from: conversation)
        
        // Store conversation context
        let context = ConversationContext(
            id: conversation.id,
            timestamp: conversation.createdAt,
            dominantMood: calculateDominantMood(from: conversation),
            keyTopics: extractKeyTopics(from: conversation),
            emotionalJourney: trackEmotionalJourney(from: conversation),
            conversationLength: conversation.messages.count,
            userEngagement: calculateUserEngagement(from: conversation)
        )
        
        conversationContexts.append(context)
        
        // Keep only recent contexts
        if conversationContexts.count > maxContextHistory {
            conversationContexts.removeFirst()
        }
        
        // Update mood patterns
        updateMoodPatterns(from: conversation)
        
        // Update personality insights
        updatePersonalityInsights(from: conversation)
        
        saveMemoryData()
    }
    
    func getContextualInsights(for currentMood: Mood, message: String) -> ContextualInsights {
        let recentContexts = conversationContexts.suffix(10)
        
        // Analyze mood consistency
        let moodConsistency = analyzeMoodConsistency(currentMood: currentMood, contexts: Array(recentContexts))
        
        // Identify emotional triggers
        let triggers = identifyEmotionalTriggers(currentMood: currentMood, message: message)
        
        // Get personalized response suggestions
        let responseSuggestions = generatePersonalizedResponses(
            mood: currentMood,
            profile: emotionalProfile,
            patterns: moodPatterns
        )
        
        // Predict emotional trajectory
        let trajectory = predictEmotionalTrajectory(
            currentMood: currentMood,
            patterns: moodPatterns
        )
        
        return ContextualInsights(
            moodConsistency: moodConsistency,
            identifiedTriggers: triggers,
            responseSuggestions: responseSuggestions,
            emotionalTrajectory: trajectory,
            personalizedCoaching: generatePersonalizedCoaching(for: currentMood),
            conversationContinuity: assessConversationContinuity()
        )
    }
    
    func getEmotionalGrowthInsights() -> EmotionalGrowthInsights? {
        guard let profile = emotionalProfile,
              conversationContexts.count >= 5 else { return nil }
        
        let recentContexts = conversationContexts.suffix(20)
        
        // Analyze emotional growth over time
        let growthTrends = analyzeEmotionalGrowth(contexts: Array(recentContexts))
        
        // Identify resilience patterns
        let resiliencePatterns = identifyResiliencePatterns(contexts: Array(recentContexts))
        
        // Track emotional vocabulary expansion
        let vocabularyGrowth = trackEmotionalVocabularyGrowth()
        
        return EmotionalGrowthInsights(
            overallGrowthScore: growthTrends.overallScore,
            resilienceScore: resiliencePatterns.score,
            emotionalAwareness: profile.emotionalAwareness,
            vocabularyRichness: vocabularyGrowth,
            keyGrowthAreas: growthTrends.keyAreas,
            recommendedFocus: resiliencePatterns.recommendations
        )
    }
    
    // MARK: - Memory Analysis
    
    private func updateEmotionalProfile(from conversation: Conversation) {
        let userMessages = conversation.messages.filter { $0.isFromUser }
        guard !userMessages.isEmpty else { return }
        
        // Extract emotional characteristics
        let moodDistribution = analyzeMoodDistribution(from: userMessages)
        let communicationStyle = analyzeCommunicationStyle(from: userMessages)
        let emotionalRange = calculateEmotionalRange(from: userMessages)
        let expressiveness = calculateExpressiveness(from: userMessages)
        
        if var profile = emotionalProfile {
            // Update existing profile
            profile.updateWith(
                moodDistribution: moodDistribution,
                communicationStyle: communicationStyle,
                emotionalRange: emotionalRange,
                expressiveness: expressiveness
            )
            self.emotionalProfile = profile
        } else {
            // Create new profile
            self.emotionalProfile = EmotionalProfile(
                dominantMoods: Array(moodDistribution.keys.prefix(3)),
                communicationStyle: communicationStyle,
                emotionalRange: emotionalRange,
                expressiveness: expressiveness,
                emotionalAwareness: 0.5, // Will be updated over time
                conversationCount: 1
            )
        }
    }
    
    private func calculateDominantMood(from conversation: Conversation) -> Mood {
        let userMoods = conversation.messages
            .filter { $0.isFromUser }
            .compactMap { $0.sentiment?.mood }
        
        guard !userMoods.isEmpty else { return .neutral }
        
        let moodCounts = Dictionary(grouping: userMoods) { $0 }
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
    
    private func extractKeyTopics(from conversation: Conversation) -> [String] {
        let allText = conversation.messages
            .filter { $0.isFromUser }
            .map { $0.text }
            .joined(separator: " ")
        
        // Simple keyword extraction (in production, use NLP)
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "i", "you", "he", "she", "it", "we", "they", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "must"])
        
        let words = allText.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !commonWords.contains($0) }
        
        let wordCounts = Dictionary(grouping: words) { $0 }
            .mapValues { $0.count }
            .filter { $0.value > 1 }
        
        return Array(wordCounts.keys.prefix(5))
    }
    
    private func trackEmotionalJourney(from conversation: Conversation) -> [Mood] {
        return conversation.messages
            .filter { $0.isFromUser }
            .compactMap { $0.sentiment?.mood }
    }
    
    private func calculateUserEngagement(from conversation: Conversation) -> Double {
        let userMessages = conversation.messages.filter { $0.isFromUser }
        guard !userMessages.isEmpty else { return 0.0 }
        
        let averageLength = userMessages.map { $0.text.count }.reduce(0, +) / userMessages.count
        let responseRate = Double(userMessages.count) / Double(conversation.messages.count)
        
        // Normalize engagement score
        let lengthScore = min(Double(averageLength) / 100.0, 1.0)
        let engagementScore = (lengthScore + responseRate) / 2.0
        
        return min(engagementScore, 1.0)
    }
    
    private func updateMoodPatterns(from conversation: Conversation) {
        let emotionalJourney = trackEmotionalJourney(from: conversation)
        guard emotionalJourney.count >= 2 else { return }
        
        // Analyze mood transitions
        for i in 1..<emotionalJourney.count {
            let fromMood = emotionalJourney[i-1]
            let toMood = emotionalJourney[i]
            
            if let existingPattern = moodPatterns.first(where: { $0.fromMood == fromMood && $0.toMood == toMood }) {
                existingPattern.frequency += 1
                existingPattern.lastOccurrence = Date()
            } else {
                let pattern = MoodPattern(
                    fromMood: fromMood,
                    toMood: toMood,
                    frequency: 1,
                    lastOccurrence: Date(),
                    triggers: []
                )
                moodPatterns.append(pattern)
            }
        }
        
        // Keep only most frequent patterns
        moodPatterns.sort { $0.frequency > $1.frequency }
        if moodPatterns.count > 20 {
            moodPatterns = Array(moodPatterns.prefix(20))
        }
    }
    
    private func updatePersonalityInsights(from conversation: Conversation) {
        let userMessages = conversation.messages.filter { $0.isFromUser }
        guard !userMessages.isEmpty else { return }
        
        // Analyze personality traits from communication patterns
        let traits = analyzePersonalityTraits(from: userMessages)
        let emotionalIntelligence = calculateEmotionalIntelligence(from: userMessages)
        let communicationPreferences = analyzeCommunicationPreferences(from: userMessages)
        
        if var insights = personalityInsights {
            insights.updateWith(traits: traits, ei: emotionalIntelligence, preferences: communicationPreferences)
            self.personalityInsights = insights
        } else {
            self.personalityInsights = PersonalityInsights(
                traits: traits,
                emotionalIntelligence: emotionalIntelligence,
                communicationPreferences: communicationPreferences,
                lastUpdated: Date()
            )
        }
    }
    
    // MARK: - Analysis Helper Methods
    
    private func analyzeMoodConsistency(currentMood: Mood, contexts: [ConversationContext]) -> Double {
        guard !contexts.isEmpty else { return 0.0 }
        
        let recentMoods = contexts.map { $0.dominantMood }
        let consistentMoods = recentMoods.filter { $0 == currentMood }.count
        
        return Double(consistentMoods) / Double(recentMoods.count)
    }
    
    private func identifyEmotionalTriggers(currentMood: Mood, message: String) -> [String] {
        var triggers: [String] = []
        
        // Analyze message content for potential triggers
        let lowerMessage = message.lowercased()
        
        // Common emotional triggers
        let triggerKeywords: [String: [String]] = [
            "stress": ["work", "deadline", "pressure", "overwhelmed", "busy"],
            "loneliness": ["alone", "lonely", "isolated", "miss", "nobody"],
            "anxiety": ["worried", "nervous", "scared", "afraid", "anxious"],
            "anger": ["frustrated", "angry", "mad", "annoyed", "irritated"],
            "sadness": ["sad", "depressed", "down", "upset", "hurt"]
        ]
        
        for (trigger, keywords) in triggerKeywords {
            if keywords.contains(where: { lowerMessage.contains($0) }) {
                triggers.append(trigger)
            }
        }
        
        return triggers
    }
    
    private func generatePersonalizedResponses(mood: Mood, profile: EmotionalProfile?, patterns: [MoodPattern]) -> [String] {
        guard let profile = profile else {
            return ["How are you feeling about that?", "Tell me more about what's on your mind."]
        }
        
        var responses: [String] = []
        
        // Personalize based on communication style
        switch profile.communicationStyle {
        case "direct":
            responses.append("What specific support do you need right now?")
            responses.append("Let's focus on what you can control in this situation.")
        case "reflective":
            responses.append("What insights are you gaining from this experience?")
            responses.append("How does this connect to your personal growth journey?")
        case "expressive":
            responses.append("I can really feel the emotion in your words.")
            responses.append("Your feelings are completely valid and important.")
        default:
            responses.append("I'm here to listen and support you.")
            responses.append("What would be most helpful for you right now?")
        }
        
        // Add mood-specific responses
        switch mood {
        case .excited:
            responses.append("Your excitement is contagious! What's got you feeling so energized?")
        case .anxious:
            responses.append("It sounds like you're carrying some worry. What's the main concern on your mind?")
        case .sad:
            responses.append("I can sense the heaviness you're feeling. Would you like to talk about what's bringing you down?")
        default:
            responses.append("I'm curious to hear more about what you're experiencing.")
        }
        
        return Array(responses.prefix(3))
    }
    
    private func predictEmotionalTrajectory(currentMood: Mood, patterns: [MoodPattern]) -> EmotionalTrajectory {
        let relevantPatterns = patterns.filter { $0.fromMood == currentMood }
        guard !relevantPatterns.isEmpty else {
            return EmotionalTrajectory(
                predictedMood: .neutral,
                confidence: 0.3,
                timeframe: "unknown",
                reasoning: "Insufficient data for prediction"
            )
        }
        
        // Find most frequent transition
        let mostFrequentTransition = relevantPatterns.max(by: { $0.frequency < $1.frequency })!
        let confidence = Double(mostFrequentTransition.frequency) / Double(patterns.reduce(0) { $0 + $1.frequency })
        
        return EmotionalTrajectory(
            predictedMood: mostFrequentTransition.toMood,
            confidence: min(confidence * 2, 1.0), // Boost confidence for display
            timeframe: "within this conversation",
            reasoning: "Based on your historical mood patterns"
        )
    }
    
    private func generatePersonalizedCoaching(for mood: Mood) -> String {
        guard let profile = emotionalProfile else {
            return "Focus on acknowledging your current emotional state and being gentle with yourself."
        }
        
        let baseCoaching: [Mood: String] = [
            .anxious: "Remember that anxiety often comes from future uncertainty. Try grounding yourself in the present moment.",
            .sad: "Your sadness is valid and temporary. Allow yourself to feel it while also nurturing self-compassion.",
            .angry: "Your anger might be signaling that a boundary has been crossed. What needs your attention?",
            .excited: "Your excitement is wonderful! How can you channel this positive energy constructively?",
            .neutral: "This balanced state is perfect for reflection. What insights are emerging for you?"
        ]
        
        var coaching = baseCoaching[mood] ?? "Take a moment to check in with yourself and honor whatever you're feeling."
        
        // Personalize based on emotional awareness level
        if profile.emotionalAwareness > 0.7 {
            coaching += " Given your high emotional awareness, consider what deeper need this feeling might be pointing to."
        } else if profile.emotionalAwareness < 0.4 {
            coaching += " Take time to simply notice and name what you're feeling without trying to change it."
        }
        
        return coaching
    }
    
    private func assessConversationContinuity() -> Double {
        guard conversationContexts.count >= 2 else { return 0.0 }
        
        let recentContexts = conversationContexts.suffix(5)
        let topicOverlap = calculateTopicOverlap(contexts: Array(recentContexts))
        let moodStability = calculateMoodStability(contexts: Array(recentContexts))
        
        return (topicOverlap + moodStability) / 2.0
    }
    
    // MARK: - Detailed Analysis Methods
    
    private func analyzeMoodDistribution(from messages: [Message]) -> [Mood: Double] {
        let moods = messages.compactMap { $0.sentiment?.mood }
        guard !moods.isEmpty else { return [:] }
        
        let counts = Dictionary(grouping: moods) { $0 }.mapValues { $0.count }
        let total = Double(moods.count)
        
        return counts.mapValues { Double($0) / total }
    }
    
    private func analyzeCommunicationStyle(from messages: [Message]) -> String {
        let totalLength = messages.map { $0.text.count }.reduce(0, +)
        let averageLength = Double(totalLength) / Double(messages.count)
        
        let questionCount = messages.filter { $0.text.contains("?") }.count
        let questionRate = Double(questionCount) / Double(messages.count)
        
        if averageLength > 100 && questionRate > 0.3 {
            return "reflective"
        } else if averageLength < 50 && questionRate < 0.1 {
            return "direct"
        } else if averageLength > 80 {
            return "expressive"
        } else {
            return "balanced"
        }
    }
    
    private func calculateEmotionalRange(from messages: [Message]) -> Double {
        let uniqueMoods = Set(messages.compactMap { $0.sentiment?.mood })
        return Double(uniqueMoods.count) / Double(Mood.allCases.count)
    }
    
    private func calculateExpressiveness(from messages: [Message]) -> Double {
        let totalWords = messages.map { $0.text.split(separator: " ").count }.reduce(0, +)
        let emotionalWords = messages.map { message in
            let emotionalKeywords = ["feel", "think", "believe", "love", "hate", "amazing", "terrible", "wonderful", "awful", "excited", "sad", "happy", "angry"]
            return emotionalKeywords.filter { message.text.lowercased().contains($0) }.count
        }.reduce(0, +)
        
        guard totalWords > 0 else { return 0.0 }
        return Double(emotionalWords) / Double(totalWords)
    }
    
    private func analyzeEmotionalGrowth(contexts: [ConversationContext]) -> (overallScore: Double, keyAreas: [String]) {
        // Analyze improvement in emotional vocabulary, awareness, and regulation
        let emotionalComplexity = contexts.map { $0.emotionalJourney.count }.reduce(0, +)
        let averageComplexity = Double(emotionalComplexity) / Double(contexts.count)
        
        let keyAreas = ["Emotional Vocabulary", "Self-Awareness", "Emotional Regulation"]
        let score = min(averageComplexity / 5.0, 1.0) // Normalize to 0-1
        
        return (score, keyAreas)
    }
    
    private func identifyResiliencePatterns(contexts: [ConversationContext]) -> (score: Double, recommendations: [String]) {
        // Look for patterns of recovery from negative emotions
        var recoveryInstances = 0
        
        for context in contexts {
            let journey = context.emotionalJourney
            for i in 1..<journey.count {
                let prev = journey[i-1]
                let curr = journey[i]
                
                if [Mood.sad, .angry, .anxious].contains(prev) && [Mood.happy, .peaceful, .neutral].contains(curr) {
                    recoveryInstances += 1
                }
            }
        }
        
        let score = min(Double(recoveryInstances) / Double(contexts.count), 1.0)
        let recommendations = score > 0.7 ? 
            ["Continue building on your strong emotional resilience"] :
            ["Practice self-compassion", "Develop coping strategies", "Build emotional support networks"]
        
        return (score, recommendations)
    }
    
    private func trackEmotionalVocabularyGrowth() -> Double {
        // Track the richness of emotional expression over time
        guard let profile = emotionalProfile else { return 0.0 }
        return profile.emotionalRange * profile.expressiveness
    }
    
    private func analyzePersonalityTraits(from messages: [Message]) -> [String] {
        let allText = messages.map { $0.text }.joined(separator: " ").lowercased()
        
        var traits: [String] = []
        
        // Simple trait detection based on word patterns
        if allText.contains("i think") || allText.contains("i believe") {
            traits.append("thoughtful")
        }
        if allText.contains("excited") || allText.contains("amazing") {
            traits.append("enthusiastic")
        }
        if allText.contains("others") || allText.contains("people") {
            traits.append("socially aware")
        }
        if allText.contains("worry") || allText.contains("concerned") {
            traits.append("cautious")
        }
        
        return traits.isEmpty ? ["communicative"] : traits
    }
    
    private func calculateEmotionalIntelligence(from messages: [Message]) -> Double {
        let emotionalVocabulary = Set(messages.flatMap { message in
            ["happy", "sad", "angry", "excited", "anxious", "peaceful", "frustrated", "loving", "confused"]
                .filter { message.text.lowercased().contains($0) }
        }).count
        
        let selfReflectionWords = messages.filter { 
            $0.text.lowercased().contains("i feel") || $0.text.lowercased().contains("i'm feeling")
        }.count
        
        return min((Double(emotionalVocabulary) + Double(selfReflectionWords)) / 10.0, 1.0)
    }
    
    private func analyzeCommunicationPreferences(from messages: [Message]) -> [String] {
        let totalLength = messages.map { $0.text.count }.reduce(0, +)
        let averageLength = Double(totalLength) / Double(messages.count)
        
        var preferences: [String] = []
        
        if averageLength > 100 {
            preferences.append("detailed conversations")
        } else {
            preferences.append("concise communication")
        }
        
        let questionRate = Double(messages.filter { $0.text.contains("?") }.count) / Double(messages.count)
        if questionRate > 0.3 {
            preferences.append("inquiry-based dialogue")
        }
        
        return preferences
    }
    
    private func calculateTopicOverlap(contexts: [ConversationContext]) -> Double {
        guard contexts.count >= 2 else { return 0.0 }
        
        var totalOverlap = 0.0
        for i in 1..<contexts.count {
            let current = Set(contexts[i].keyTopics)
            let previous = Set(contexts[i-1].keyTopics)
            let overlap = current.intersection(previous)
            totalOverlap += Double(overlap.count) / Double(max(current.count, previous.count, 1))
        }
        
        return totalOverlap / Double(contexts.count - 1)
    }
    
    private func calculateMoodStability(contexts: [ConversationContext]) -> Double {
        guard contexts.count >= 2 else { return 0.0 }
        
        let moods = contexts.map { $0.dominantMood }
        let transitions = zip(moods, moods.dropFirst())
        let stableTransitions = transitions.filter { $0.0 == $0.1 }.count
        
        return Double(stableTransitions) / Double(moods.count - 1)
    }
    
    // MARK: - Persistence
    
    private func saveMemoryData() {
        // Save emotional profile
        if let profile = emotionalProfile,
           let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: "emotionalProfile")
        }
        
        // Save conversation contexts (recent ones only)
        let recentContexts = Array(conversationContexts.suffix(20))
        if let data = try? JSONEncoder().encode(recentContexts) {
            userDefaults.set(data, forKey: "conversationContexts")
        }
        
        // Save mood patterns
        if let data = try? JSONEncoder().encode(moodPatterns) {
            userDefaults.set(data, forKey: "moodPatterns")
        }
        
        // Save personality insights
        if let insights = personalityInsights,
           let data = try? JSONEncoder().encode(insights) {
            userDefaults.set(data, forKey: "personalityInsights")
        }
    }
    
    private func loadMemoryData() {
        // Load emotional profile
        if let data = userDefaults.data(forKey: "emotionalProfile"),
           let profile = try? JSONDecoder().decode(EmotionalProfile.self, from: data) {
            self.emotionalProfile = profile
        }
        
        // Load conversation contexts
        if let data = userDefaults.data(forKey: "conversationContexts"),
           let contexts = try? JSONDecoder().decode([ConversationContext].self, from: data) {
            self.conversationContexts = contexts
        }
        
        // Load mood patterns
        if let data = userDefaults.data(forKey: "moodPatterns"),
           let patterns = try? JSONDecoder().decode([MoodPattern].self, from: data) {
            self.moodPatterns = patterns
        }
        
        // Load personality insights
        if let data = userDefaults.data(forKey: "personalityInsights"),
           let insights = try? JSONDecoder().decode(PersonalityInsights.self, from: data) {
            self.personalityInsights = insights
        }
    }
}

// MARK: - Data Models

struct ConversationContext: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let dominantMood: Mood
    let keyTopics: [String]
    let emotionalJourney: [Mood]
    let conversationLength: Int
    let userEngagement: Double
}

struct EmotionalProfile: Codable {
    var dominantMoods: [Mood]
    var communicationStyle: String
    var emotionalRange: Double
    var expressiveness: Double
    var emotionalAwareness: Double
    var conversationCount: Int
    
    mutating func updateWith(moodDistribution: [Mood: Double], communicationStyle: String, emotionalRange: Double, expressiveness: Double) {
        self.dominantMoods = Array(moodDistribution.keys.prefix(3))
        self.communicationStyle = communicationStyle
        self.emotionalRange = (self.emotionalRange + emotionalRange) / 2.0
        self.expressiveness = (self.expressiveness + expressiveness) / 2.0
        self.conversationCount += 1
        
        // Update emotional awareness based on engagement
        self.emotionalAwareness = min(self.emotionalAwareness + 0.1, 1.0)
    }
}

class MoodPattern: Codable, ObservableObject {
    let fromMood: Mood
    let toMood: Mood
    var frequency: Int
    var lastOccurrence: Date
    var triggers: [String]
    
    init(fromMood: Mood, toMood: Mood, frequency: Int, lastOccurrence: Date, triggers: [String]) {
        self.fromMood = fromMood
        self.toMood = toMood
        self.frequency = frequency
        self.lastOccurrence = lastOccurrence
        self.triggers = triggers
    }
}

struct PersonalityInsights: Codable {
    var traits: [String]
    var emotionalIntelligence: Double
    var communicationPreferences: [String]
    var lastUpdated: Date
    
    mutating func updateWith(traits: [String], ei: Double, preferences: [String]) {
        self.traits = Array(Set(self.traits + traits).prefix(5))
        self.emotionalIntelligence = (self.emotionalIntelligence + ei) / 2.0
        self.communicationPreferences = preferences
        self.lastUpdated = Date()
    }
}

struct ContextualInsights {
    let moodConsistency: Double
    let identifiedTriggers: [String]
    let responseSuggestions: [String]
    let emotionalTrajectory: EmotionalTrajectory
    let personalizedCoaching: String
    let conversationContinuity: Double
}

struct EmotionalTrajectory {
    let predictedMood: Mood
    let confidence: Double
    let timeframe: String
    let reasoning: String
}

struct EmotionalGrowthInsights {
    let overallGrowthScore: Double
    let resilienceScore: Double
    let emotionalAwareness: Double
    let vocabularyRichness: Double
    let keyGrowthAreas: [String]
    let recommendedFocus: [String]
}