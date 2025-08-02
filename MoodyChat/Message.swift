//
//  Message.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let isFromUser: Bool
    var sentiment: SentimentResult?
    
    init(text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    var messages: [Message]
    let createdAt: Date
    var title: String
    var overallMood: Mood?
    
    init(title: String = "New Conversation") {
        self.id = UUID()
        self.messages = []
        self.createdAt = Date()
        self.title = title
    }
    
    var lastMessage: Message? {
        messages.last
    }
    
    var moodDistribution: [Mood: Int] {
        var distribution: [Mood: Int] = [:]
        messages.compactMap { $0.sentiment?.mood }.forEach { mood in
            distribution[mood, default: 0] += 1
        }
        return distribution
    }
}