//
//  SentimentAnalysisService.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation
import NaturalLanguage

class SentimentAnalysisService: ObservableObject {
    static let shared = SentimentAnalysisService()
    
    // Store conversation context for better analysis
    private var messageHistory: [String] = []
    private var sentimentHistory: [Double] = []
    private var moodHistory: [Mood] = []
    private let maxHistorySize = 15
    
    // User learning system
    private var userCommunicationPatterns: [String: Mood] = [:]
    private var userEmotionalBaseline: Double = 0.0
    private var conversationContext: [String] = []
    private var userPersonalityTraits: [String: Double] = [:]
    
    private init() {}
    
    func analyzeSentiment(for text: String) async -> SentimentResult {
        // Add to history for learning
        messageHistory.append(text)
        if messageHistory.count > maxHistorySize {
            messageHistory.removeFirst()
        }
        
        // Use advanced semantic analysis
        let mood = await performAdvancedSentimentAnalysis(for: text)
        let confidence = calculateAdvancedConfidence(for: text, mood: mood)
        
        // Store mood in history for pattern analysis
        moodHistory.append(mood)
        if moodHistory.count > maxHistorySize {
            moodHistory.removeFirst()
        }
        
        return SentimentResult(mood: mood, confidence: confidence)
    }
    
    private func performAdvancedSentimentAnalysis(for text: String) async -> Mood {
        // 1. Semantic sentence analysis using NLP
        let semanticMood = await analyzeSemanticMeaning(text: text)
        
        // 2. Contextual relationship analysis
        let contextualMood = analyzeConversationalFlow()
        
        // 3. User pattern learning
        let personalizedMood = analyzePersonalCommunicationPatterns(text: text)
        
        // 4. Emotional intensity and progression analysis
        let emotionalProgression = analyzeEmotionalProgression()
        
        // Combine with sophisticated weighting based on conversation depth
        return combineSemanticAnalysis(
            semanticMood: semanticMood,
            contextualMood: contextualMood,
            personalizedMood: personalizedMood,
            emotionalProgression: emotionalProgression,
            conversationDepth: messageHistory.count
        )
    }
    
    private func getAppleSentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentimentValue = sentiment?.rawValue, let score = Double(sentimentValue) {
            sentimentHistory.append(score)
            if sentimentHistory.count > maxHistorySize {
                sentimentHistory.removeFirst()
            }
            return score
        }
        
        return 0.0
    }
    
    private func analyzeSemanticMeaning(text: String) async -> Mood {
        // Use NLTagger for comprehensive linguistic analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass, .nameType])
        tagger.string = text
        
        // Get overall sentiment
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let sentimentScore = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        // Analyze sentence structure and meaning
        let semanticAnalysis = analyzeSemanticStructure(text: text, sentimentScore: sentimentScore)
        
        // Consider negations and context modifiers
        let contextAdjustedMood = adjustForContextualModifiers(text: text, baseMood: semanticAnalysis)
        
        // Learn from user's communication style
        learnUserPattern(text: text, detectedMood: contextAdjustedMood)
        
        return contextAdjustedMood
    }
    
    private func analyzeSemanticStructure(text: String, sentimentScore: Double) -> Mood {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var totalEmotionalWeight: Double = 0
        var emotionalIndicators: [Mood: Double] = [:]
        
        // First, analyze the overall positivity/negativity of the entire message
        let overallPositivity = analyzeOverallPositivity(text: text, sentimentScore: sentimentScore)
        
        for sentence in sentences {
            let analysis = analyzeSentenceStructure(sentence: sentence, sentimentScore: sentimentScore)
            emotionalIndicators[analysis.mood, default: 0] += analysis.weight
            totalEmotionalWeight += analysis.weight
        }
        
        // Apply overall positivity boost to the analysis
        if overallPositivity.isPositive && overallPositivity.confidence > 0.6 {
            emotionalIndicators[overallPositivity.mood, default: 0] += overallPositivity.confidence * 2.0
            totalEmotionalWeight += overallPositivity.confidence * 2.0
        } else if overallPositivity.isNegative && overallPositivity.confidence > 0.6 {
            emotionalIndicators[overallPositivity.mood, default: 0] += overallPositivity.confidence * 1.5
            totalEmotionalWeight += overallPositivity.confidence * 1.5
        }
        
        // Find the dominant emotion with highest weighted score
        let dominantMood = emotionalIndicators.max(by: { $0.value < $1.value })?.key ?? .neutral
        
        // Adjust based on overall sentiment intensity
        return adjustMoodIntensity(mood: dominantMood, intensity: abs(sentimentScore), totalWeight: totalEmotionalWeight)
    }
    
    private func analyzeOverallPositivity(text: String, sentimentScore: Double) -> (isPositive: Bool, isNegative: Bool, mood: Mood, confidence: Double) {
        let lowercased = text.lowercased()
        
        // Strong positive indicators
        let positiveWords = [
            "good", "great", "beautiful", "wonderful", "amazing", "fantastic", "excellent", "perfect",
            "happy", "joy", "love", "nice", "awesome", "brilliant", "superb", "terrific",
            "shining", "bright", "lovely", "pleasant", "delightful", "marvelous", "outstanding",
            "fabulous", "incredible", "spectacular", "magnificent", "gorgeous", "stunning"
        ]
        
        // Strong negative indicators
        let negativeWords = [
            "terrible", "awful", "horrible", "bad", "worst", "hate", "disgusting", "pathetic",
            "miserable", "depressing", "tragic", "devastating", "nightmare", "disaster"
        ]
        
        // Positive phrases and expressions
        let positiveExpressions = [
            "pretty good", "going well", "not bad", "doing great", "feeling good",
            "sun is shining", "life is beautiful", "having a good", "things are good",
            "pretty nice", "looking good", "going great", "quite good", "really good"
        ]
        
        // Count positive and negative indicators
        var positiveScore = 0.0
        var negativeScore = 0.0
        
        // Check positive words
        for word in positiveWords {
            if lowercased.contains(word) {
                positiveScore += 1.0
            }
        }
        
        // Check negative words
        for word in negativeWords {
            if lowercased.contains(word) {
                negativeScore += 1.0
            }
        }
        
        // Check positive expressions (these are worth more)
        for expression in positiveExpressions {
            if lowercased.contains(expression) {
                positiveScore += 2.0
            }
        }
        
        // Check for common greeting patterns that indicate good mood
        if lowercased.contains("how is it going") || lowercased.contains("how are you") {
            if positiveScore > 0 {
                positiveScore += 1.0 // Boost if combined with positive words
            }
        }
        
        // Determine overall sentiment
        let totalScore = positiveScore + negativeScore
        let confidence = min(totalScore / 5.0, 1.0) // Normalize confidence
        
        if positiveScore > negativeScore && positiveScore >= 1.0 {
            // Determine intensity of positive mood
            if positiveScore >= 3.0 {
                return (true, false, .excited, confidence)
            } else if positiveScore >= 2.0 {
                return (true, false, .happy, confidence)
            } else {
                return (true, false, .peaceful, confidence)
            }
        } else if negativeScore > positiveScore && negativeScore >= 1.0 {
            // Determine intensity of negative mood
            if negativeScore >= 3.0 {
                return (false, true, .angry, confidence)
            } else if negativeScore >= 2.0 {
                return (false, true, .sad, confidence)
            } else {
                return (false, true, .anxious, confidence)
            }
        }
        
        // If sentiment score is strong, use that
        if abs(sentimentScore) > 0.3 {
            if sentimentScore > 0.3 {
                return (true, false, .happy, abs(sentimentScore))
            } else {
                return (false, true, .sad, abs(sentimentScore))
            }
        }
        
        return (false, false, .neutral, 0.2)
    }
    
    private func analyzeSentenceStructure(sentence: String, sentimentScore: Double) -> (mood: Mood, weight: Double) {
        let lowercased = sentence.lowercased()
        
        // Analyze sentence patterns and emotional context
        if containsNegation(sentence: lowercased) {
            return analyzeNegativeSentiment(sentence: lowercased, baseScore: sentimentScore)
        }
        
        if containsQuestions(sentence: sentence) {
            return analyzeQuestioningTone(sentence: lowercased, baseScore: sentimentScore)
        }
        
        if containsExclamations(sentence: sentence) {
            return analyzeExcitedTone(sentence: lowercased, baseScore: sentimentScore)
        }
        
        // Analyze statement tone and content
        return analyzeStatementTone(sentence: lowercased, baseScore: sentimentScore)
    }
    
    private func containsNegation(sentence: String) -> Bool {
        let negationWords = ["not", "no", "never", "nothing", "nobody", "nowhere", "neither", "nor", "can't", "won't", "don't", "isn't", "aren't"]
        return negationWords.contains { sentence.contains($0) }
    }
    
    private func containsQuestions(sentence: String) -> Bool {
        return sentence.contains("?") || sentence.lowercased().hasPrefix("what") || 
               sentence.lowercased().hasPrefix("how") || sentence.lowercased().hasPrefix("why") ||
               sentence.lowercased().hasPrefix("when") || sentence.lowercased().hasPrefix("where")
    }
    
    private func containsExclamations(sentence: String) -> Bool {
        return sentence.contains("!") || sentence.filter { $0.isUppercase }.count > sentence.count / 2
    }
    
    private func analyzeNegativeSentiment(sentence: String, baseScore: Double) -> (mood: Mood, weight: Double) {
        if sentence.contains("stressed") || sentence.contains("overwhelmed") || sentence.contains("pressure") {
            return (.anxious, 0.8)
        }
        if sentence.contains("tired") || sentence.contains("exhausted") || sentence.contains("drained") {
            return (.sad, 0.7)
        }
        if sentence.contains("frustrated") || sentence.contains("annoying") {
            return (.angry, 0.7)
        }
        
        // Default negative sentiment analysis
        return baseScore < -0.3 ? (.sad, 0.6) : (.neutral, 0.3)
    }
    
    private func analyzeQuestioningTone(sentence: String, baseScore: Double) -> (mood: Mood, weight: Double) {
        // Check for positive rhetorical questions
        if sentence.contains("isn't it") || sentence.contains("right?") || sentence.contains("don't you think") {
            // These are often used in positive contexts - check surrounding words
            if sentence.contains("good") || sentence.contains("nice") || sentence.contains("beautiful") || sentence.contains("great") {
                return (.happy, 0.7)
            }
            return (.peaceful, 0.4)
        }
        
        // Casual greetings
        if sentence.contains("how are") || sentence.contains("how is") {
            return (.neutral, 0.1) // Very low weight for greetings
        }
        
        // Concerned questions
        if sentence.contains("what's wrong") || sentence.contains("what happened") {
            return (.anxious, 0.6)
        }
        
        return baseScore < 0 ? (.confused, 0.3) : (.neutral, 0.2)
    }
    
    private func analyzeExcitedTone(sentence: String, baseScore: Double) -> (mood: Mood, weight: Double) {
        let exclamationCount = sentence.filter { $0 == "!" }.count
        
        if baseScore > 0.3 {
            return exclamationCount > 1 ? (.excited, 0.9) : (.happy, 0.7)
        } else if baseScore < -0.3 {
            return exclamationCount > 2 ? (.angry, 0.8) : (.frustrated, 0.6)
        }
        
        return (.excited, 0.5)
    }
    
    private func analyzeStatementTone(sentence: String, baseScore: Double) -> (mood: Mood, weight: Double) {
        let lowercased = sentence.lowercased()
        
        // Check for specific positive patterns in statements
        let positivePatterns = [
            "pretty good": 0.8,
            "going well": 0.7,
            "not bad": 0.6,
            "doing great": 0.9,
            "feeling good": 0.8,
            "things are good": 0.7,
            "life is beautiful": 1.0,
            "sun is shining": 0.9
        ]
        
        for (pattern, weight) in positivePatterns {
            if lowercased.contains(pattern) {
                if weight >= 0.9 {
                    return (.excited, weight)
                } else if weight >= 0.7 {
                    return (.happy, weight)
                } else {
                    return (.peaceful, weight)
                }
            }
        }
        
        // Analyze based on sentiment score and sentence length/complexity
        let wordCount = sentence.components(separatedBy: .whitespaces).count
        let complexity = Double(wordCount) / 10.0
        
        // Be more sensitive to positive sentiment scores
        switch baseScore {
        case 0.3...1.0: // Lowered threshold for positive detection
            return complexity > 0.8 ? (.loving, 0.8) : (.happy, 0.7)
        case 0.1..<0.3: // Slightly positive should be peaceful, not neutral
            return (.peaceful, 0.6)
        case -0.1...0.1:
            return (.neutral, 0.3) // Lower weight for truly neutral
        case -0.3..<(-0.1):
            return (.confused, 0.4)
        case -0.5..<(-0.3):
            return complexity > 0.6 ? (.anxious, 0.7) : (.sad, 0.6)
        case -1.0..<(-0.5):
            return complexity > 0.8 ? (.angry, 0.8) : (.sad, 0.7)
        default:
            return (.neutral, 0.2)
        }
    }
    
    private func adjustForContextualModifiers(text: String, baseMood: Mood) -> Mood {
        // Consider the context of previous messages
        if messageHistory.count >= 2 {
            let recentContext = Array(messageHistory.suffix(3)).joined(separator: " ")
            return adjustMoodBasedOnContext(currentMood: baseMood, context: recentContext)
        }
        
        return baseMood
    }
    
    private func adjustMoodBasedOnContext(currentMood: Mood, context: String) -> Mood {
        // If previous messages show a pattern, adjust current mood accordingly
        let contextSentiment = getContextualSentiment(context: context)
        
        // Smooth transitions between emotional states
        if let lastMood = moodHistory.last {
            return blendMoods(previous: lastMood, current: currentMood, contextInfluence: contextSentiment)
        }
        
        return currentMood
    }
    
    private func getContextualSentiment(context: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = context
        let (sentiment, _) = tagger.tag(at: context.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0") ?? 0.0
    }
    
    private func blendMoods(previous: Mood, current: Mood, contextInfluence: Double) -> Mood {
        // Create smooth emotional transitions
        if abs(contextInfluence) < 0.3 {
            return previous // Maintain previous mood if context is neutral
        }
        
        // Allow mood change if there's strong contextual evidence
        return current
    }
    
    private func adjustMoodIntensity(mood: Mood, intensity: Double, totalWeight: Double) -> Mood {
        // Adjust mood based on emotional intensity
        if intensity > 0.7 && totalWeight > 0.6 {
            return enhanceMoodIntensity(mood: mood)
        }
        
        return mood
    }
    
    private func enhanceMoodIntensity(mood: Mood) -> Mood {
        switch mood {
        case .happy: return .excited
        case .sad: return .sad // Keep sad as is, but could be .devastated if we had more levels
        case .neutral: return .peaceful
        case .anxious: return .anxious // Already intense
        default: return mood
        }
    }
    
    private func learnUserPattern(text: String, detectedMood: Mood) {
        // Learn user's communication patterns
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        userCommunicationPatterns[normalizedText] = detectedMood
        
        // Update emotional baseline
        let moodValue = moodToNumericalValue(mood: detectedMood)
        userEmotionalBaseline = (userEmotionalBaseline * 0.9) + (moodValue * 0.1)
        
        // Store for pattern analysis
        conversationContext.append(text)
        if conversationContext.count > 20 {
            conversationContext.removeFirst()
        }
    }
    
    private func moodToNumericalValue(mood: Mood) -> Double {
        switch mood {
        case .excited: return 1.0
        case .happy: return 0.7
        case .loving: return 0.8
        case .peaceful: return 0.3
        case .neutral: return 0.0
        case .confused: return -0.2
        case .anxious: return -0.5
        case .frustrated: return -0.6
        case .sad: return -0.7
        case .angry: return -0.8
        }
    }
    
    private func analyzeConversationalFlow() -> Mood {
        guard moodHistory.count >= 3 else { return .neutral }
        
        // Analyze recent mood progression
        let recentMoods = Array(moodHistory.suffix(5))
        let moodProgression = analyzeMoodProgression(moods: recentMoods)
        
        return moodProgression.dominantMood
    }
    
    private func analyzePersonalCommunicationPatterns(text: String) -> Mood {
        // Check if we've seen similar phrases from this user before
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let learnedMood = userCommunicationPatterns[normalizedText] {
            return learnedMood
        }
        
        // Check for similar patterns using fuzzy matching
        for (pattern, mood) in userCommunicationPatterns {
            if textSimilarity(text1: normalizedText, text2: pattern) > 0.7 {
                return mood
            }
        }
        
        return .neutral
    }
    
    private func analyzeEmotionalProgression() -> Mood {
        guard moodHistory.count >= 3 else { return .neutral }
        
        let progression = analyzeMoodProgression(moods: Array(moodHistory.suffix(5)))
        
        // Predict next emotional state based on progression
        if progression.isImproving {
            return enhanceMood(mood: progression.dominantMood)
        } else if progression.isDeclining {
            return dampenMood(mood: progression.dominantMood)
        }
        
        return progression.dominantMood
    }
    
    private func combineSemanticAnalysis(
        semanticMood: Mood,
        contextualMood: Mood,
        personalizedMood: Mood,
        emotionalProgression: Mood,
        conversationDepth: Int
    ) -> Mood {
        
        // Weight based on conversation depth and confidence
        var moodScores: [Mood: Double] = [:]
        
        // Semantic analysis gets highest weight
        moodScores[semanticMood, default: 0] += 0.4
        
        // Contextual analysis weight increases with conversation depth
        let contextWeight = min(Double(conversationDepth) / 15.0, 0.3)
        moodScores[contextualMood, default: 0] += contextWeight
        
        // Personalized patterns weight increases as we learn more about the user
        let personalWeight = min(Double(userCommunicationPatterns.count) / 50.0, 0.2)
        moodScores[personalizedMood, default: 0] += personalWeight
        
        // Emotional progression provides stability
        let progressionWeight = 0.1
        moodScores[emotionalProgression, default: 0] += progressionWeight
        
        return moodScores.max(by: { $0.value < $1.value })?.key ?? semanticMood
    }
    
    private func analyzeMoodProgression(moods: [Mood]) -> (dominantMood: Mood, isImproving: Bool, isDeclining: Bool) {
        let moodValues = moods.map { moodToNumericalValue(mood: $0) }
        
        // Calculate trend
        let firstHalf = Array(moodValues.prefix(moodValues.count / 2))
        let secondHalf = Array(moodValues.suffix(moodValues.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let trend = secondAvg - firstAvg
        
        // Find dominant mood
        var moodCounts: [Mood: Int] = [:]
        moods.forEach { moodCounts[$0, default: 0] += 1 }
        let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
        
        return (
            dominantMood: dominantMood,
            isImproving: trend > 0.2,
            isDeclining: trend < -0.2
        )
    }
    
    private func textSimilarity(text1: String, text2: String) -> Double {
        let words1 = Set(text1.components(separatedBy: .whitespaces))
        let words2 = Set(text2.components(separatedBy: .whitespaces))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func enhanceMood(mood: Mood) -> Mood {
        switch mood {
        case .neutral: return .peaceful
        case .peaceful: return .happy
        case .happy: return .excited
        case .confused: return .neutral
        case .anxious: return .confused
        default: return mood
        }
    }
    
    private func dampenMood(mood: Mood) -> Mood {
        switch mood {
        case .excited: return .happy
        case .happy: return .peaceful
        case .peaceful: return .neutral
        case .neutral: return .confused
        default: return mood
        }
    }
    
    private func analyzeLinguisticPatterns(text: String) -> Mood {
        let lowercased = text.lowercased()
        
        // Analyze punctuation patterns
        let exclamationCount = text.filter { $0 == "!" }.count
        let questionCount = text.filter { $0 == "?" }.count
        let capsCount = text.filter { $0.isUppercase }.count
        
        // Analyze sentence structure
        let words = lowercased.components(separatedBy: .whitespaces)
        let wordCount = words.count
        
        // Pattern-based mood detection
        if exclamationCount >= 2 || (capsCount > wordCount / 2 && wordCount > 3) {
            return exclamationCount > 3 ? .angry : .excited
        }
        
        if questionCount >= 2 {
            return .anxious
        }
        
        // Short, abrupt messages might indicate different moods
        if wordCount <= 2 {
            return .confused
        }
        
        return .neutral
    }
    
    private func analyzeConversationalContext() -> Mood {
        guard messageHistory.count >= 3 else { return .neutral }
        
        // Analyze sentiment progression over recent messages
        let recentSentiments = Array(sentimentHistory.suffix(5))
        let averageSentiment = recentSentiments.reduce(0, +) / Double(recentSentiments.count)
        
        // Look for sentiment trends
        let trend = calculateSentimentTrend(recentSentiments)
        
        // Convert average sentiment to mood with trend consideration
        switch (averageSentiment, trend) {
        case (0.6...1.0, _):
            return trend > 0 ? .excited : .happy
        case (0.2..<0.6, let t) where t > 0.1:
            return .happy
        case (0.2..<0.6, _):
            return .peaceful
        case (-0.2...0.2, _):
            return .neutral
        case (-0.6..<(-0.2), let t) where t < -0.1:
            return .sad
        case (-0.6..<(-0.2), _):
            return .anxious
        case (-1.0..<(-0.6), _):
            return trend < 0 ? .angry : .sad
        default:
            return .neutral
        }
    }
    
    private func calculateSentimentTrend(_ sentiments: [Double]) -> Double {
        guard sentiments.count >= 2 else { return 0 }
        
        let recent = sentiments.suffix(3)
        let older = sentiments.prefix(sentiments.count - 2)
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        return recentAvg - olderAvg
    }
    
    private func combineAnalysisResults(
        appleScore: Double,
        keywordMood: Mood,
        linguisticMood: Mood,
        contextualMood: Mood,
        messageCount: Int
    ) -> Mood {
        
        // Early messages have lower confidence, rely more on keywords
        if messageCount < 3 {
            return keywordMood != .neutral ? keywordMood : mapAppleScoreToMood(appleScore)
        }
        
        // With more context, weight contextual analysis more heavily
        let contextWeight = min(Double(messageCount) / 10.0, 0.6)
        let keywordWeight = 0.3
        let linguisticWeight = 0.1
        
        // Create mood scores
        var moodScores: [Mood: Double] = [:]
        
        // Add contextual mood score
        moodScores[contextualMood, default: 0] += contextWeight
        
        // Add keyword mood score
        if keywordMood != .neutral {
            moodScores[keywordMood, default: 0] += keywordWeight
        }
        
        // Add linguistic mood score
        if linguisticMood != .neutral {
            moodScores[linguisticMood, default: 0] += linguisticWeight
        }
        
        // Add Apple sentiment score
        let appleMood = mapAppleScoreToMood(appleScore)
        moodScores[appleMood, default: 0] += (1.0 - contextWeight - keywordWeight - linguisticWeight)
        
        return moodScores.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
    
    private func mapAppleScoreToMood(_ score: Double) -> Mood {
        switch score {
        case 0.6...1.0:
            return .happy
        case 0.2..<0.6:
            return .peaceful
        case -0.2...0.2:
            return .neutral
        case -0.6..<(-0.2):
            return .anxious
        case -1.0..<(-0.6):
            return .sad
        default:
            return .neutral
        }
    }
    
    private func calculateAdvancedConfidence(for text: String, mood: Mood) -> Double {
        let baseConfidence: Double
        
        // Confidence based on message history - but don't penalize early messages too much
        if messageHistory.count < 3 {
            baseConfidence = 0.6 // Reasonable confidence for early messages if they're clear
        } else if messageHistory.count < 6 {
            baseConfidence = 0.7 // Medium confidence
        } else {
            baseConfidence = 0.8 // High confidence with enough context
        }
        
        // Boost confidence for clear emotional expressions
        let lowercased = text.lowercased()
        var emotionalClarityBoost = 0.0
        
        // Strong positive expressions boost confidence
        if lowercased.contains("life is beautiful") || lowercased.contains("sun is shining") {
            emotionalClarityBoost += 0.3
        } else if lowercased.contains("pretty good") || lowercased.contains("doing great") {
            emotionalClarityBoost += 0.2
        } else if lowercased.contains("good") || lowercased.contains("great") || lowercased.contains("beautiful") {
            emotionalClarityBoost += 0.1
        }
        
        // Strong negative expressions also boost confidence
        if lowercased.contains("terrible") || lowercased.contains("awful") || lowercased.contains("hate") {
            emotionalClarityBoost += 0.2
        } else if lowercased.contains("stressed") || lowercased.contains("angry") || lowercased.contains("sad") {
            emotionalClarityBoost += 0.15
        }
        
        // Adjust based on text characteristics
        let textLength = text.count
        let lengthFactor = min(Double(textLength) / 100.0, 0.1) // Longer messages get slight boost
        
        // Adjust based on sentiment consistency (only if we have history)
        let consistencyFactor = messageHistory.count >= 3 ? calculateSentimentConsistency() : 0.0
        
        return min(baseConfidence + emotionalClarityBoost + lengthFactor + consistencyFactor, 0.95)
    }
    
    private func calculateSentimentConsistency() -> Double {
        guard sentimentHistory.count >= 3 else { return 0 }
        
        let recent = Array(sentimentHistory.suffix(5))
        let variance = calculateVariance(recent)
        
        // Lower variance = higher consistency = higher confidence
        return max(0, 0.2 - variance * 0.5)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    // Reset conversation context (useful for new conversations)
    func resetConversationContext() {
        messageHistory.removeAll()
        sentimentHistory.removeAll()
        moodHistory.removeAll()
        conversationContext.removeAll()
        // Keep user patterns for learning across conversations
    }
    
    // Get current analysis confidence based on message history
    func getCurrentAnalysisStrength() -> String {
        switch messageHistory.count {
        case 0...2:
            return "Learning..."
        case 3...5:
            return "Building confidence"
        case 6...9:
            return "Good understanding"
        default:
            return "High confidence"
        }
    }
    
    // Mock analysis for development - provides variety of moods for testing
    func mockAnalyzeSentiment(for text: String) -> SentimentResult {
        let lowercased = text.lowercased()
        
        let moodKeywords: [Mood: [String]] = [
            .happy: ["happy", "great", "awesome", "wonderful", "amazing", "love", "excited", "joy", "😊", "😄", "🎉"],
            .sad: ["sad", "down", "depressed", "unhappy", "cry", "terrible", "awful", "😢", "😭", "💔"],
            .excited: ["excited", "amazing", "wow", "incredible", "fantastic", "awesome", "🤩", "🎉", "🚀"],
            .angry: ["angry", "mad", "furious", "hate", "annoyed", "frustrated", "😠", "😡", "🤬"],
            .anxious: ["worried", "nervous", "anxious", "scared", "afraid", "stress", "😰", "😨", "😱"],
            .loving: ["love", "adore", "care", "affection", "heart", "kiss", "🥰", "❤️", "💕"],
            .peaceful: ["calm", "peaceful", "serene", "relaxed", "zen", "tranquil", "😌", "🧘", "☮️"]
        ]
        
        var scores: [Mood: Int] = [:]
        
        for (mood, keywords) in moodKeywords {
            let matches = keywords.filter { lowercased.contains($0) }.count
            if matches > 0 {
                scores[mood] = matches
            }
        }
        
        let detectedMood = scores.max(by: { $0.value < $1.value })?.key ?? .neutral
        let confidence = Double.random(in: 0.6...0.95)
        
        return SentimentResult(mood: detectedMood, confidence: confidence)
    }
}