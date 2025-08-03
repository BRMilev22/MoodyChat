//
//  ConversationManager.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation
import Combine

class ConversationManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    
    private let sentimentService = SentimentAnalysisService.shared
    private let aiSentimentService = AIEnhancedSentimentService.shared
    private let fastMoodAnalyzer = FastMoodAnalyzer.shared
    
    init() {
        loadConversations()
    }
    
    func startNewConversation(title: String = "New Conversation") {
        let conversation = Conversation(title: title)
        conversations.append(conversation)
        currentConversation = conversation
        
        // Reset sentiment analysis context for new conversation
        sentimentService.resetConversationContext()
        
        // Reset mood analyzer context and cache
        fastMoodAnalyzer.resetContext()
        
        saveConversations()
    }
    
    func generateSmartResponse(for userMood: Mood) async -> String {
        guard let conversation = currentConversation else {
            return "I'm here to listen. How are you feeling?"
        }
        
        return await aiSentimentService.generateSmartResponse(
            for: conversation,
            userMood: userMood
        )
    }
    
    // INSTANT: Add message immediately to UI without any analysis delays
    @MainActor
    func addMessageInstantly(_ text: String, isFromUser: Bool) {
        guard var conversation = currentConversation else { return }
        
        var message = Message(text: text, isFromUser: isFromUser)
        
        // Add with neutral sentiment initially (for instant display)
        message.sentiment = SentimentResult(mood: .neutral, confidence: 0.1)
        
        conversation.messages.append(message)
        
        // Update the conversation in the array immediately
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            currentConversation = conversations[index]
        }
        
        saveConversations()
    }
    
    // LEGACY: Keep this for non-user messages or when mood analysis is needed upfront
    func addMessage(_ text: String, isFromUser: Bool) async {
        guard var conversation = currentConversation else { return }
        
        var message = Message(text: text, isFromUser: isFromUser)
        
        // Super fast mood analysis for immediate UI updates
        if isFromUser {
            let quickMood = await fastMoodAnalyzer.analyzeMoodFast(text: text)
            message.sentiment = SentimentResult(mood: quickMood, confidence: 0.8)
        } else {
            message.sentiment = await sentimentService.analyzeSentiment(for: text)
        }
        
        conversation.messages.append(message)
        
        // Update overall conversation mood based on recent messages
        updateConversationMood(&conversation)
        
        // Update the conversation in the array
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            currentConversation = conversations[index]
        }
        
        saveConversations()
        
        // Optional: Run AI analysis in background (don't await - let it run async)
        if isFromUser {
            Task.detached(priority: .background) {
                await self.performBackgroundAIAnalysis(for: text, conversation: conversation)
            }
        }
    }
    
    private func performBackgroundAIAnalysis(for text: String, conversation: Conversation) async {
        // This runs in background without blocking the UI
        await aiSentimentService.generateConversationInsights(for: conversation)
        await aiSentimentService.generateEmotionalCoaching(
            for: conversation.overallMood ?? .neutral,
            message: text,
            userHistory: conversation.messages.filter { $0.isFromUser }
        )
    }
    
    private func updateConversationMood(_ conversation: inout Conversation) {
        let recentMessages = Array(conversation.messages.suffix(5))
        let moodCounts = recentMessages.compactMap { $0.sentiment?.mood }
            .reduce(into: [Mood: Int]()) { counts, mood in
                counts[mood, default: 0] += 1
            }
        
        conversation.overallMood = moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func saveConversations() {
        // TODO: Implement persistence (UserDefaults, Core Data, or file system)
    }
    
    private func loadConversations() {
        // TODO: Load conversations from persistent storage
        // For now, create a sample conversation
        createSampleConversation()
    }
    
    private func createSampleConversation() {
        let sample = Conversation(title: "Welcome to MoodyChat")
        conversations.append(sample)
    }
}