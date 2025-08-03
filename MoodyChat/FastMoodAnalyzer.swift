//
//  FastMoodAnalyzer.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import Foundation

struct TimeoutError: Error {}

class FastMoodAnalyzer: ObservableObject {
    static let shared = FastMoodAnalyzer()
    
    private let ollamaService = OllamaService.shared
    private let basicSentiment = SentimentAnalysisService.shared
    
    // Context caching with memory management
    private var conversationContext: [String] = []
    private var moodCache: [String: Mood] = [:]
    private let maxContextMessages = 10 // Prevent memory leaks
    private let maxCacheSize = 50
    
    private init() {}
    
    // Fast mood analysis with context awareness and conservative detection
    func analyzeMoodFast(text: String) async -> Mood {
        print("🔍 Starting mood analysis for: '\(text)'")
        
        // Add to conversation context with memory management
        addToContext(text)
        
        // Check cache first for performance
        if let cachedMood = moodCache[text] {
            print("💾 Using cached mood: \(cachedMood.displayName)")
            return cachedMood
        }
        
        // Always start with basic sentiment analysis (instant and reliable)
        let basicResult = await basicSentiment.analyzeSentiment(for: text)
        print("📊 Basic sentiment result: \(basicResult.mood.displayName) (confidence: \(basicResult.confidence))")
        
        // Smart conservative approach: block greetings/questions, but allow emotional statements
        let isQuestion = text.contains("?") || text.lowercased().contains("how") || text.lowercased().contains("what") || text.lowercased().contains("when") || text.lowercased().contains("where") || text.lowercased().contains("why")
        let isGreeting = text.lowercased().contains("hello") || text.lowercased().contains("hi ") || text.lowercased().contains("hey")
        
        // Block obvious non-emotional content
        if isQuestion || isGreeting {
            print("🛡️ Question/greeting detected, staying neutral")
            cacheResult(text: text, mood: .neutral)
            return .neutral
        }
        
        // Try OLLAMA first - it's much smarter than basic sentiment
        let connectionAvailable = await checkConnectionQuickly()
        print("🌐 OLLAMA connection available: \(connectionAvailable)")
        
        if connectionAvailable {
            do {
                // OLLAMA is primary - use it whenever possible
                let aiMood = try await withTimeout(seconds: 15.0) {
                    try await self.contextAwareMoodAnalysis(text: text)
                }
                print("🧠 AI mood analysis result: \(aiMood?.displayName ?? "nil")")
                
                if let mood = aiMood {
                    print("✅ Using OLLAMA result: \(mood.displayName)")
                    cacheResult(text: text, mood: mood)
                    return mood
                }
            } catch {
                print("❌ AI mood analysis failed: \(error)")
            }
        } else {
            print("⚡ OLLAMA unavailable")
        }
        
        // Fallback to basic sentiment only when OLLAMA fails
        print("🔄 Falling back to basic sentiment analysis")
        
        // For basic sentiment, be more conservative about wrong results
        if basicResult.mood == .angry && !text.lowercased().contains("angry") && !text.lowercased().contains("mad") && !text.lowercased().contains("hate") {
            print("🤔 Basic sentiment says angry but no anger words detected - using neutral instead")
            cacheResult(text: text, mood: .neutral)
            return .neutral
        }
        
        // Use basic sentiment if confidence is reasonable
        let finalMood = basicResult.confidence >= 0.7 ? basicResult.mood : .neutral
        print("✅ Basic sentiment result: \(finalMood.displayName)")
        cacheResult(text: text, mood: finalMood)
        return finalMood
    }
    
    private func checkConnectionQuickly() async -> Bool {
        do {
            return try await withTimeout(seconds: 0.5) {
                await self.ollamaService.checkOllamaConnection()
            }
        } catch {
            return false
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Return the first result (either success or timeout)
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Context Management
    
    private func addToContext(_ text: String) {
        conversationContext.append(text)
        
        // Memory management: keep only recent messages
        if conversationContext.count > maxContextMessages {
            conversationContext.removeFirst()
        }
        
        print("💬 Context messages: \(conversationContext.count)")
    }
    
    private func cacheResult(text: String, mood: Mood) {
        moodCache[text] = mood
        
        // Memory management: prevent unlimited cache growth
        if moodCache.count > maxCacheSize {
            let oldestKey = moodCache.keys.first // Remove oldest
            if let key = oldestKey {
                moodCache.removeValue(forKey: key)
            }
        }
        
        print("💾 Cached result. Cache size: \(moodCache.count)")
    }
    
    private func contextAwareMoodAnalysis(text: String) async throws -> Mood? {
        let context = conversationContext.joined(separator: " → ")
        
        let prompt = """
        You are analyzing the emotional state of the person writing the message. BE VERY CONSERVATIVE - only detect strong emotions when the person is clearly expressing their own feelings.
        
        Conversation flow: \(context)
        Current message: "\(text)"
        
        IMPORTANT RULES:
        - Questions, greetings, and polite conversation = neutral
        - Only detect emotions when person expresses THEIR OWN feelings
        - "How are you?" = neutral (asking, not expressing)
        - "I'm sad" = sad (expressing own feeling)
        - "Hello" = neutral (greeting)
        - "I love this!" = happy (expressing own feeling)
        
        Respond with EXACTLY ONE WORD only:
        
        happy (only when clearly expressing joy/happiness)
        sad (only when clearly expressing sadness)
        excited (only when clearly expressing excitement)
        angry (only when clearly expressing anger)
        neutral (for questions, greetings, neutral statements)
        anxious (only when clearly expressing worry/anxiety)
        loving (only when clearly expressing love/affection)
        frustrated (only when clearly expressing frustration)
        peaceful (only when clearly expressing calm/peace)
        confused (only when clearly expressing confusion)
        
        Examples:
        "Hello" → neutral
        "How are you?" → neutral  
        "How is your day going?" → neutral
        "I'm having a great day!" → happy
        "I feel terrible" → sad
        "This is amazing!" → excited
        
        Your response (one word only):
        """
        
        print("🤖 Sending context-aware analysis to OLLAMA")
        let response = try await ollamaService.callOllama(prompt: prompt, model: "llama2:latest")
        print("🤖 OLLAMA response: '\(response.prefix(100))'")
        
        // Clean the response aggressively
        let cleanResponse = response
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
        
        print("🎯 Cleaned response: '\(cleanResponse)'")
        return parseMoodString(cleanResponse)
    }
    
    private func quickAIMoodAnalysis(text: String) async throws -> Mood? {
        let prompt = """
        You are a mood detector. Analyze the text and respond with EXACTLY ONE WORD only.
        
        Text: "\(text)"
        
        Respond with only one of these words (nothing else):
        happy
        sad  
        excited
        angry
        neutral
        anxious
        loving
        frustrated
        peaceful
        confused
        
        Examples:
        "I got promoted!" → excited
        "My dog died" → sad
        "I love you" → loving
        "Traffic is terrible" → frustrated
        
        Your response (one word only):
        """
        
        print("🤖 Sending to OLLAMA: '\(text)'")
        let response = try await ollamaService.callOllama(prompt: prompt, model: "llama2:latest")
        print("🤖 OLLAMA response: '\(response.prefix(100))'") // Show first 100 chars
        
        // Clean the response aggressively
        let cleanResponse = response
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression) // Keep only letters
        
        print("🎯 Cleaned response: '\(cleanResponse)'")
        return parseMoodString(cleanResponse)
    }
    
    private func parseMoodString(_ mood: String) -> Mood? {
        switch mood {
        case "happy": return .happy
        case "sad": return .sad
        case "excited": return .excited
        case "angry": return .angry
        case "neutral": return .neutral
        case "anxious": return .anxious
        case "loving": return .loving
        case "frustrated": return .frustrated
        case "peaceful": return .peaceful
        case "confused": return .confused
        default: return nil
        }
    }
    
    // MARK: - Public Methods
    
    func resetContext() {
        conversationContext.removeAll()
        moodCache.removeAll()
        print("🔄 Context and cache cleared")
    }
    
    func clearCache() {
        moodCache.removeAll()
        print("🗑️ Cache cleared for testing")
    }
}