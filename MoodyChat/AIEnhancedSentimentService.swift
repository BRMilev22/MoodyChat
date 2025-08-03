//
//  AIEnhancedSentimentService.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation

class AIEnhancedSentimentService: ObservableObject {
    static let shared = AIEnhancedSentimentService()
    
    private let ollamaService = OllamaService.shared
    private let baseSentimentService = SentimentAnalysisService.shared
    
    @Published var currentInsights: ConversationInsights?
    @Published var isAnalyzing = false
    @Published var emotionalCoaching: EmotionalCoaching?
    
    private init() {}
    
    // MARK: - Enhanced Analysis
    
    func performDeepSentimentAnalysis(for message: String, conversationHistory: [Message]) async -> EnhancedSentimentResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Get base sentiment analysis
        let baseSentiment = await baseSentimentService.analyzeSentiment(for: message)
        
        // Enhanced analysis with AI if OLLAMA is available
        if await ollamaService.checkOllamaConnection() {
            do {
                let aiInsights = try await analyzeWithAI(message: message, history: conversationHistory)
                return EnhancedSentimentResult(
                    baseSentiment: baseSentiment,
                    aiInsights: aiInsights,
                    isAIEnhanced: true
                )
            } catch {
                print("AI analysis failed, using base sentiment: \(error)")
                return EnhancedSentimentResult(
                    baseSentiment: baseSentiment,
                    aiInsights: nil,
                    isAIEnhanced: false
                )
            }
        } else {
            return EnhancedSentimentResult(
                baseSentiment: baseSentiment,
                aiInsights: nil,
                isAIEnhanced: false
            )
        }
    }
    
    private func analyzeWithAI(message: String, history: [Message]) async throws -> AIEmotionalInsights {
        let conversationContext = history.suffix(5).map { $0.text }.joined(separator: " ")
        
        let prompt = """
        Analyze this message for deep emotional intelligence insights:
        
        Current message: "\(message)"
        Recent context: \(conversationContext)
        
        Provide detailed emotional analysis in JSON format:
        {
            "emotionalLayers": ["surface emotion", "underlying emotion", "core need"],
            "communicationPatterns": ["pattern1", "pattern2"],
            "emotionalComplexity": 0.0-1.0,
            "subconscious_indicators": ["indicator1", "indicator2"],
            "emotional_growth_opportunities": ["opportunity1", "opportunity2"],
            "contextual_mood_shift": "description of how mood is shifting in context",
            "personality_insights": ["insight1", "insight2"],
            "response_suggestions": ["suggestion1", "suggestion2", "suggestion3"],
            "empathy_level": 0.0-1.0,
            "authenticity_score": 0.0-1.0,
            "emotional_intelligence_indicators": ["indicator1", "indicator2"]
        }
        
        Focus on nuanced understanding beyond surface-level emotions.
        """
        
        let response = try await ollamaService.callOllama(prompt: prompt, model: "llama2:latest")
        return try parseAIEmotionalInsights(from: response)
    }
    
    // MARK: - Conversation Insights
    
    func generateConversationInsights(for conversation: Conversation) async {
        guard await ollamaService.checkOllamaConnection() else { return }
        
        do {
            let insights = try await ollamaService.analyzeConversationMood(messages: conversation.messages)
            await MainActor.run {
                self.currentInsights = insights
            }
        } catch {
            print("Failed to generate conversation insights: \(error)")
        }
    }
    
    // MARK: - Emotional Coaching
    
    func generateEmotionalCoaching(for mood: Mood, message: String, userHistory: [Message]) async {
        guard await ollamaService.checkOllamaConnection() else { 
            // Provide fallback coaching
            await MainActor.run {
                self.emotionalCoaching = EmotionalCoaching.fallback()
            }
            return
        }
        
        do {
            let coaching = try await ollamaService.generateEmotionalCoaching(
                for: mood,
                context: message,
                userHistory: userHistory
            )
            await MainActor.run {
                self.emotionalCoaching = coaching
            }
        } catch {
            print("Failed to generate emotional coaching: \(error)")
            await MainActor.run {
                self.emotionalCoaching = EmotionalCoaching.fallback()
            }
        }
    }
    
    // MARK: - Smart Response Generation
    
    func generateSmartResponse(for conversation: Conversation, userMood: Mood) async -> String {
        guard await ollamaService.checkOllamaConnection() else {
            return generateFallbackResponse(for: userMood)
        }
        
        let recentMessages = Array(conversation.messages.suffix(3))
        let conversationText = recentMessages.map { 
            "\($0.isFromUser ? "User" : "Assistant"): \($0.text)" 
        }.joined(separator: "\n")
        
        let prompt = """
        You are an emotionally intelligent AI companion. Generate a caring, contextual response.
        
        Current conversation:
        \(conversationText)
        
        User's current mood: \(userMood.displayName)
        
        Generate a response that:
        - Shows genuine understanding and empathy
        - Responds to their emotional state appropriately
        - Offers support without being pushy
        - Asks thoughtful follow-up questions
        - Feels natural and conversational
        - Is 1-2 sentences long
        
        Just return the response text, no JSON format needed.
        """
        
        do {
            let response = try await ollamaService.callOllama(prompt: prompt, model: "llama2:latest")
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            return generateFallbackResponse(for: userMood)
        }
    }
    
    private func generateFallbackResponse(for mood: Mood) -> String {
        let responses: [Mood: [String]] = [
            .happy: [
                "Your joy is absolutely infectious! What's been the highlight of your day?",
                "I love seeing you so upbeat! Tell me more about what's bringing you this happiness.",
                "Your positive energy is wonderful! What's putting that smile in your voice?"
            ],
            .sad: [
                "I can hear the weight in your words. Would you like to share what's been on your heart?",
                "I'm here with you in this moment. Sometimes it helps to talk about what's bringing you down.",
                "Your feelings are completely valid. I'm listening if you'd like to tell me more."
            ],
            .anxious: [
                "I can sense the tension you're carrying. Let's take this one step at a time - what's your biggest worry right now?",
                "Anxiety can feel overwhelming, but you're not alone in this. What's been causing you the most stress?",
                "I hear the concern in your message. Would it help to talk through what's making you feel anxious?"
            ],
            .excited: [
                "Your excitement is electric! I can practically feel your energy through the screen - what's got you so pumped?",
                "This enthusiasm is amazing! I'm dying to know what's got you feeling so energized!",
                "Your excitement is contagious! Share the good news - what's happening?"
            ]
        ]
        
        return responses[mood]?.randomElement() ?? "I hear you, and I'm here to listen. What's on your mind right now?"
    }
    
    // MARK: - Parsing Helpers
    
    private func parseAIEmotionalInsights(from response: String) throws -> AIEmotionalInsights {
        guard let data = response.data(using: .utf8) else {
            throw OllamaError.parseError("Failed to encode response")
        }
        
        do {
            return try JSONDecoder().decode(AIEmotionalInsights.self, from: data)
        } catch {
            return AIEmotionalInsights.fallback()
        }
    }
}

// MARK: - Enhanced Data Models

struct EnhancedSentimentResult {
    let baseSentiment: SentimentResult
    let aiInsights: AIEmotionalInsights?
    let isAIEnhanced: Bool
    
    var finalMood: Mood {
        return aiInsights?.refinedMood ?? baseSentiment.mood
    }
    
    var finalConfidence: Double {
        if let aiInsights = aiInsights {
            return (baseSentiment.confidence + aiInsights.authenticity_score) / 2.0
        }
        return baseSentiment.confidence
    }
}

struct AIEmotionalInsights: Codable {
    let emotionalLayers: [String]
    let communicationPatterns: [String]
    let emotionalComplexity: Double
    let subconscious_indicators: [String]
    let emotional_growth_opportunities: [String]
    let contextual_mood_shift: String
    let personality_insights: [String]
    let response_suggestions: [String]
    let empathy_level: Double
    let authenticity_score: Double
    let emotional_intelligence_indicators: [String]
    
    var refinedMood: Mood? {
        // Logic to determine refined mood based on AI insights
        if emotionalLayers.contains("underlying sadness") || subconscious_indicators.contains("hidden grief") {
            return .sad
        } else if emotionalLayers.contains("masked anxiety") || subconscious_indicators.contains("stress patterns") {
            return .anxious
        } else if empathy_level > 0.7 && authenticity_score > 0.8 {
            return .loving
        }
        return nil
    }
    
    static func fallback() -> AIEmotionalInsights {
        return AIEmotionalInsights(
            emotionalLayers: ["Surface emotion", "Core feeling"],
            communicationPatterns: ["Direct communication", "Emotional expressiveness"],
            emotionalComplexity: 0.6,
            subconscious_indicators: ["Seeking connection", "Desire for understanding"],
            emotional_growth_opportunities: ["Deeper self-awareness", "Emotional regulation"],
            contextual_mood_shift: "Gradual shift toward openness",
            personality_insights: ["Thoughtful communicator", "Emotionally aware"],
            response_suggestions: ["Show empathy", "Ask follow-up questions", "Validate feelings"],
            empathy_level: 0.7,
            authenticity_score: 0.8,
            emotional_intelligence_indicators: ["Self-awareness", "Emotional expression"]
        )
    }
}