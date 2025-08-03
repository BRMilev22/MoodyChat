//
//  OllamaService.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation

class OllamaService: ObservableObject {
    static let shared = OllamaService()
    
    private let baseURL = "http://localhost:11434" // Use localhost for simulator, change to your Mac's IP for device testing
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Mood Analysis with AI
    
    func analyzeConversationMood(messages: [Message]) async throws -> ConversationInsights {
        let conversationText = messages.map { "\($0.isFromUser ? "User" : "Assistant"): \($0.text)" }.joined(separator: "\n")
        
        let prompt = """
        Analyze this conversation for emotional intelligence insights. Be specific and actionable.
        
        Conversation:
        \(conversationText)
        
        Provide analysis in this JSON format:
        {
            "dominantMood": "happy/sad/anxious/excited/angry/peaceful/loving/frustrated/confused/neutral",
            "moodProgression": "improving/declining/stable/fluctuating",
            "emotionalIntensity": 0.0-1.0,
            "keyEmotionalTriggers": ["trigger1", "trigger2"],
            "personalityTraits": ["trait1", "trait2", "trait3"],
            "communicationStyle": "direct/expressive/reserved/analytical/emotional",
            "moodPatterns": ["pattern1", "pattern2"],
            "recommendations": ["suggestion1", "suggestion2", "suggestion3"],
            "supportiveResponse": "A caring, contextual response that acknowledges their emotional state"
        }
        
        Focus on:
        - Deep emotional understanding beyond surface words
        - Personality insights from communication patterns
        - Actionable recommendations for emotional wellbeing
        - Empathetic response that shows genuine understanding
        """
        
        let response = try await callOllama(prompt: prompt, model: "llama2:latest")
        return try parseConversationInsights(from: response)
    }
    
    func generateEmotionalCoaching(for mood: Mood, context: String, userHistory: [Message]) async throws -> EmotionalCoaching {
        let recentMessages = userHistory.suffix(5).map { $0.text }.joined(separator: " ")
        
        let prompt = """
        You are an expert emotional intelligence coach. The user is feeling \(mood.displayName.lowercased()).
        
        Current context: \(context)
        Recent conversation patterns: \(recentMessages)
        
        Provide personalized emotional coaching in JSON format:
        {
            "understanding": "Show deep understanding of their emotional state",
            "validation": "Validate their feelings without judgment", 
            "insights": "Psychological insights about this emotional pattern",
            "copingStrategies": ["strategy1", "strategy2", "strategy3"],
            "reframingTechniques": ["technique1", "technique2"],
            "actionableSteps": ["step1", "step2", "step3"],
            "affirmations": ["affirmation1", "affirmation2"],
            "followUpQuestions": ["question1", "question2"],
            "moodBoostSuggestions": ["suggestion1", "suggestion2"]
        }
        
        Be compassionate, evidence-based, and practical. Tailor advice to their specific situation.
        """
        
        let response = try await callOllama(prompt: prompt, model: "llama2:latest")
        return try parseEmotionalCoaching(from: response)
    }
    
    func analyzeMoodPatterns(conversations: [Conversation]) async throws -> MoodPatternAnalysis {
        let conversationSummaries = conversations.prefix(10).map { conversation in
            let moodCounts = conversation.moodDistribution
            let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
            return "Date: \(formatDate(conversation.createdAt)), Mood: \(dominantMood.displayName), Messages: \(conversation.messages.count)"
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze these conversation patterns for emotional intelligence insights:
        
        \(conversationSummaries)
        
        Provide deep pattern analysis in JSON format:
        {
            "overallTrend": "improving/declining/stable/cyclical",
            "mostFrequentMoods": ["mood1", "mood2", "mood3"],
            "emotionalVolatility": 0.0-1.0,
            "communicationEvolution": "How their communication style has evolved",
            "triggerPatterns": ["What seems to trigger certain moods"],
            "resilenceIndicators": ["Signs of emotional growth"],
            "concernAreas": ["Areas that might need attention"],
            "strengthAreas": ["Emotional strengths to build on"],
            "personalizedInsights": "Deep, personalized emotional intelligence insights",
            "longTermRecommendations": ["Long-term emotional development suggestions"]
        }
        
        Focus on growth, patterns, and actionable insights for emotional development.
        """
        
        let response = try await callOllama(prompt: prompt, model: "llama2:latest")
        return try parseMoodPatternAnalysis(from: response)
    }
    
    // MARK: - Core OLLAMA Integration
    
    func callOllama(prompt: String, model: String = "llama2:latest") async throws -> String {
        let url = URL(string: "\(baseURL)/api/generate")!
        
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.1,
                "top_p": 0.5,
                "num_predict": 10
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.networkError("Failed to connect to OLLAMA")
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = jsonObject["response"] as? String else {
            throw OllamaError.parseError("Invalid response format")
        }
        
        return responseText
    }
    
    // MARK: - Response Parsing
    
    private func parseConversationInsights(from response: String) throws -> ConversationInsights {
        guard let data = response.data(using: .utf8) else {
            throw OllamaError.parseError("Failed to encode response")
        }
        
        do {
            return try JSONDecoder().decode(ConversationInsights.self, from: data)
        } catch {
            // Fallback parsing if JSON is malformed
            return ConversationInsights.fallback()
        }
    }
    
    private func parseEmotionalCoaching(from response: String) throws -> EmotionalCoaching {
        guard let data = response.data(using: .utf8) else {
            throw OllamaError.parseError("Failed to encode response")
        }
        
        do {
            return try JSONDecoder().decode(EmotionalCoaching.self, from: data)
        } catch {
            return EmotionalCoaching.fallback()
        }
    }
    
    private func parseMoodPatternAnalysis(from response: String) throws -> MoodPatternAnalysis {
        guard let data = response.data(using: .utf8) else {
            throw OllamaError.parseError("Failed to encode response")
        }
        
        do {
            return try JSONDecoder().decode(MoodPatternAnalysis.self, from: data)
        } catch {
            return MoodPatternAnalysis.fallback()
        }
    }
    
    // MARK: - Utility
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Health Check
    
    func checkOllamaConnection() async -> Bool {
        do {
            let url = URL(string: "\(baseURL)/api/tags")!
            print("🔗 Checking OLLAMA connection at: \(url)")
            let (_, response) = try await session.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("📡 OLLAMA response status: \(statusCode)")
            return statusCode == 200
        } catch {
            print("❌ OLLAMA connection failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Error Handling

enum OllamaError: Error, LocalizedError {
    case networkError(String)
    case parseError(String)
    case modelNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .parseError(let message):
            return "Parse Error: \(message)"
        case .modelNotAvailable:
            return "AI model is not available"
        }
    }
}

// MARK: - Data Models

struct ConversationInsights: Codable {
    let dominantMood: String
    let moodProgression: String
    let emotionalIntensity: Double
    let keyEmotionalTriggers: [String]
    let personalityTraits: [String]
    let communicationStyle: String
    let moodPatterns: [String]
    let recommendations: [String]
    let supportiveResponse: String
    
    static func fallback() -> ConversationInsights {
        return ConversationInsights(
            dominantMood: "neutral",
            moodProgression: "stable",
            emotionalIntensity: 0.5,
            keyEmotionalTriggers: ["Daily interactions", "Work stress"],
            personalityTraits: ["Thoughtful", "Expressive", "Caring"],
            communicationStyle: "expressive",
            moodPatterns: ["Variable throughout day", "Responsive to environment"],
            recommendations: ["Practice mindfulness", "Express feelings openly", "Take regular breaks"],
            supportiveResponse: "I can see you're sharing thoughtfully with me. Your feelings are completely valid, and I'm here to support you."
        )
    }
}

struct EmotionalCoaching: Codable {
    let understanding: String
    let validation: String
    let insights: String
    let copingStrategies: [String]
    let reframingTechniques: [String]
    let actionableSteps: [String]
    let affirmations: [String]
    let followUpQuestions: [String]
    let moodBoostSuggestions: [String]
    
    static func fallback() -> EmotionalCoaching {
        return EmotionalCoaching(
            understanding: "I can sense the depth of what you're experiencing right now.",
            validation: "Your feelings are completely valid and it's natural to feel this way.",
            insights: "This emotional state often reflects our need for connection and understanding.",
            copingStrategies: ["Deep breathing exercises", "Grounding techniques", "Gentle self-compassion"],
            reframingTechniques: ["Focus on what you can control", "Look for small positive moments"],
            actionableSteps: ["Take three deep breaths", "Write down one thing you're grateful for", "Reach out to someone you trust"],
            affirmations: ["I am worthy of care and understanding", "This feeling will pass", "I have strength within me"],
            followUpQuestions: ["What would help you feel more supported right now?", "Is there something specific on your mind?"],
            moodBoostSuggestions: ["Listen to uplifting music", "Step outside for fresh air", "Do something creative for 10 minutes"]
        )
    }
}

struct MoodPatternAnalysis: Codable {
    let overallTrend: String
    let mostFrequentMoods: [String]
    let emotionalVolatility: Double
    let communicationEvolution: String
    let triggerPatterns: [String]
    let resilenceIndicators: [String]
    let concernAreas: [String]
    let strengthAreas: [String]
    let personalizedInsights: String
    let longTermRecommendations: [String]
    
    static func fallback() -> MoodPatternAnalysis {
        return MoodPatternAnalysis(
            overallTrend: "stable",
            mostFrequentMoods: ["neutral", "peaceful", "happy"],
            emotionalVolatility: 0.4,
            communicationEvolution: "Becoming more open and expressive over time",
            triggerPatterns: ["Stress from daily routine", "Positive social interactions"],
            resilenceIndicators: ["Quick recovery from setbacks", "Maintains optimism"],
            concernAreas: ["Occasional stress spikes", "Self-care consistency"],
            strengthAreas: ["Emotional awareness", "Communication skills", "Empathy"],
            personalizedInsights: "You show strong emotional intelligence and a genuine desire for growth and connection.",
            longTermRecommendations: ["Develop consistent self-care routine", "Practice emotional regulation techniques", "Build support network"]
        )
    }
}