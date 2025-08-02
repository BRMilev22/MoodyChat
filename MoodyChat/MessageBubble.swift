//
//  MessageBubble.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                userMessage
            } else {
                assistantMessage
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
    
    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: message.sentiment?.mood.gradientColors.map { $0.opacity(0.8) } ?? [Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(.white)
                
                if let sentiment = message.sentiment {
                    Text(sentiment.mood.emoji)
                        .font(.caption)
                        .opacity(0.8)
                }
            }
            
            HStack(spacing: 4) {
                if let sentiment = message.sentiment {
                    Text("\(sentiment.mood.displayName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(sentiment.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var assistantMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("🤖")
                    .font(.body)
                
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                    )
            }
            
            HStack(spacing: 4) {
                Text("Assistant")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 32) // Align with message content
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MoodIndicator: View {
    let mood: Mood
    
    var body: some View {
        HStack(spacing: 6) {
            Text(mood.emoji)
                .font(.title3)
            
            Circle()
                .fill(mood.primaryColor)
                .frame(width: 8, height: 8)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: mood)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(mood.primaryColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(mood.primaryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageBubble(
            message: Message(
                text: "Hello! I'm feeling great today! 😊",
                isFromUser: true
            )
        )
        
        MessageBubble(
            message: Message(
                text: "That's wonderful to hear! I'm glad you're having a good day.",
                isFromUser: false
            )
        )
        
        MoodIndicator(mood: .happy)
    }
    .padding()
}