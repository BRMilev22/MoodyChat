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
    
    init() {
        loadConversations()
    }
    
    func startNewConversation(title: String = "New Conversation") {
        let conversation = Conversation(title: title)
        conversations.append(conversation)
        currentConversation = conversation
        
        // Reset sentiment analysis context for new conversation
        sentimentService.resetConversationContext()
        
        saveConversations()
    }
    
    func addMessage(_ text: String, isFromUser: Bool) async {
        guard var conversation = currentConversation else { return }
        
        var message = Message(text: text, isFromUser: isFromUser)
        
        // Analyze sentiment for the message
        message.sentiment = await sentimentService.analyzeSentiment(for: text)
        
        conversation.messages.append(message)
        
        // Update overall conversation mood based on recent messages
        updateConversationMood(&conversation)
        
        // Update the conversation in the array
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            currentConversation = conversations[index]
        }
        
        saveConversations()
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