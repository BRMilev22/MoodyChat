//
//  MessageInputView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var currentMood: Mood
    let onSend: () -> Void
    
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Mood prediction preview
            if isTyping && !messageText.isEmpty {
                moodPreview
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Input field
            HStack(spacing: 12) {
                // Text input
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        isTextFieldFocused ? currentMood.primaryColor.opacity(0.5) : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                    .focused($isTextFieldFocused)
                    .onChange(of: messageText) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTyping = !newValue.isEmpty
                        }
                        
                        // Mock real-time sentiment analysis
                        if !newValue.isEmpty {
                            predictMoodFromText(newValue)
                        }
                    }
                    .onSubmit {
                        if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .secondary
                            : currentMood.primaryColor
                        )
                        .scaleEffect(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? 1.0
                            : 1.1
                        )
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
            )
        }
    }
    
    private var moodPreview: some View {
        HStack(spacing: 8) {
            Text("Detected mood:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(currentMood.emoji)
                    .font(.caption)
                
                Text(currentMood.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(currentMood.primaryColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(currentMood.primaryColor.opacity(0.1))
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
    }
    
    private func predictMoodFromText(_ text: String) {
        // Simple mood prediction based on keywords
        // In a real app, this would use the CoreML service
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
        
        if let predictedMood = scores.max(by: { $0.value < $1.value })?.key {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMood = predictedMood
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(
            messageText: .constant("I'm feeling great today!"),
            currentMood: .constant(.happy),
            onSend: {}
        )
    }
}