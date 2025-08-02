//
//  Mood.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import Foundation
import SwiftUI

enum Mood: String, CaseIterable, Codable {
    case happy = "happy"
    case sad = "sad"
    case excited = "excited"
    case angry = "angry"
    case neutral = "neutral"
    case anxious = "anxious"
    case loving = "loving"
    case frustrated = "frustrated"
    case peaceful = "peaceful"
    case confused = "confused"
    
    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .sad: return "Sad"
        case .excited: return "Excited"
        case .angry: return "Angry"
        case .neutral: return "Neutral"
        case .anxious: return "Anxious"
        case .loving: return "Loving"
        case .frustrated: return "Frustrated"
        case .peaceful: return "Peaceful"
        case .confused: return "Confused"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .excited: return "🤩"
        case .angry: return "😠"
        case .neutral: return "😐"
        case .anxious: return "😰"
        case .loving: return "🥰"
        case .frustrated: return "😤"
        case .peaceful: return "😌"
        case .confused: return "🤔"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .happy: return .yellow
        case .sad: return .blue
        case .excited: return .orange
        case .angry: return .red
        case .neutral: return .gray
        case .anxious: return .purple
        case .loving: return .pink
        case .frustrated: return .red
        case .peaceful: return .green
        case .confused: return .gray
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .happy: return [.yellow, .orange]
        case .sad: return [.blue, .indigo]
        case .excited: return [.orange, .red]
        case .angry: return [.red, .pink]
        case .neutral: return [.gray, .secondary]
        case .anxious: return [.purple, .blue]
        case .loving: return [.pink, .red]
        case .frustrated: return [.red, .orange]
        case .peaceful: return [.green, .mint]
        case .confused: return [.gray, .brown]
        }
    }
}

struct SentimentResult: Codable {
    let mood: Mood
    let confidence: Double
    let timestamp: Date
    
    init(mood: Mood, confidence: Double, timestamp: Date = Date()) {
        self.mood = mood
        self.confidence = confidence
        self.timestamp = timestamp
    }
}