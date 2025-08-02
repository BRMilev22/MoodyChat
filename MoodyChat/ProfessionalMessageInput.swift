//
//  ProfessionalMessageInput.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct ProfessionalMessageInput: View {
    @Binding var messageText: String
    @Binding var currentMood: Mood
    @Binding var isTyping: Bool
    let onSend: () -> Void
    
    @State private var isTextFieldFocused = false
    @State private var predictedMood: Mood = .neutral
    @State private var showMoodPreview = false
    @State private var textFieldHeight: CGFloat = 44
    @FocusState private var textFieldFocus: Bool
    
    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 44
    
    var body: some View {
        VStack(spacing: 0) {
            // Mood prediction preview
            if showMoodPreview {
                moodPreviewBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Main input container
            HStack(alignment: .bottom, spacing: 12) {
                // Dynamic text input with glass morphism
                textInputField
                
                // Send button with mood-responsive design
                sendButton
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMoodPreview)
        .onChange(of: messageText) { oldValue, newValue in
            updateMoodPrediction(text: newValue)
            updateTextFieldHeight()
        }
        .onChange(of: textFieldFocus) { oldValue, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isTextFieldFocused = newValue
            }
        }
    }
    
    private var moodPreviewBar: some View {
        HStack(spacing: 12) {
            // Animated mood indicator
            HStack(spacing: 8) {
                Text(predictedMood.emoji)
                    .font(.title3)
                    .scaleEffect(1.1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: predictedMood)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detecting mood...")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(predictedMood.displayName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(predictedMood.primaryColor)
                }
            }
            
            Spacer()
            
            // Confidence indicator
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(predictedMood.primaryColor)
                        .frame(width: 4, height: 4)
                        .opacity(Double(index) < 2.5 ? 1.0 : 0.3)
                        .scaleEffect(Double(index) < 2.5 ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: predictedMood
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    predictedMood.primaryColor.opacity(0.4),
                                    predictedMood.primaryColor.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.bottom, 8)
    }
    
    private var textInputField: some View {
        ZStack(alignment: .topLeading) {
            // Background with liquid glass effect
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isTextFieldFocused ? [
                                    currentMood.primaryColor.opacity(0.5),
                                    currentMood.primaryColor.opacity(0.2),
                                    Color.clear
                                ] : [
                                    Color.primary.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isTextFieldFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isTextFieldFocused ? currentMood.primaryColor.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isTextFieldFocused ? 12 : 6,
                    x: 0,
                    y: isTextFieldFocused ? 6 : 3
                )
            
            // Text input
            HStack(alignment: .top, spacing: 12) {
                // Text field
                ScrollView(.vertical, showsIndicators: false) {
                    TextField("Share your thoughts...", text: $messageText, axis: .vertical)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .focused($textFieldFocus)
                        .textFieldStyle(.plain)
                        .lineLimit(1...6)
                        .onSubmit {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSend()
                            }
                        }
                }
                .fixedSize(horizontal: false, vertical: true)
                
                // Attach button (optional feature)
                if !messageText.isEmpty {
                    Button(action: { /* Future: Add attachment */ }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minHeight: minHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isTextFieldFocused)
    }
    
    private var sendButton: some View {
        Button(action: onSend) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ] : currentMood.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: messageText.isEmpty ? Color.clear : currentMood.primaryColor.opacity(0.3),
                        radius: messageText.isEmpty ? 0 : 8,
                        x: 0,
                        y: messageText.isEmpty ? 0 : 4
                    )
                
                // Send icon
                Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                      "circle" : "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(messageText.isEmpty ? .secondary : .white)
                    .scaleEffect(messageText.isEmpty ? 0.8 : 1.0)
            }
        }
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: messageText.isEmpty)
    }
    
    private func updateMoodPrediction(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if trimmedText.isEmpty {
                showMoodPreview = false
                isTyping = false
            } else {
                showMoodPreview = true
                isTyping = true
                predictedMood = predictMoodFromText(text: trimmedText)
            }
        }
    }
    
    private func predictMoodFromText(text: String) -> Mood {
        let lowercased = text.lowercased()
        
        // Enhanced real-time mood prediction
        let moodIndicators: [Mood: ([String], Double)] = [
            .happy: (["good", "great", "awesome", "wonderful", "amazing", "fantastic", "excellent", "brilliant", "lovely", "nice", "beautiful", "perfect", "delighted", "pleased", "glad"], 1.0),
            .excited: (["excited", "thrilled", "amazing", "incredible", "fantastic", "wow", "awesome", "unbelievable", "spectacular", "outstanding"], 1.2),
            .loving: (["love", "adore", "cherish", "care", "affection", "heart", "sweet", "tender", "devoted", "precious"], 1.1),
            .peaceful: (["calm", "peaceful", "serene", "relaxed", "tranquil", "zen", "balanced", "centered", "quiet", "still"], 0.9),
            .sad: (["sad", "down", "depressed", "blue", "miserable", "unhappy", "devastated", "heartbroken", "crying", "tears"], 1.0),
            .angry: (["angry", "mad", "furious", "rage", "hate", "pissed", "livid", "irritated", "annoyed", "frustrated"], 1.1),
            .anxious: (["anxious", "worried", "nervous", "scared", "afraid", "panic", "stress", "overwhelmed", "tension", "pressure"], 1.0),
            .confused: (["confused", "lost", "unsure", "puzzled", "uncertain", "bewildered", "perplexed", "unclear", "mixed"], 0.8)
        ]
        
        var highestScore = 0.0
        var detectedMood: Mood = .neutral
        
        for (mood, (keywords, multiplier)) in moodIndicators {
            let matches = keywords.filter { lowercased.contains($0) }
            let score = Double(matches.count) * multiplier
            
            if score > highestScore {
                highestScore = score
                detectedMood = mood
            }
        }
        
        return highestScore > 0 ? detectedMood : .neutral
    }
    
    private func updateTextFieldHeight() {
        // This would be implemented with UITextView delegate in a real app
        // For now, we'll use a simple estimation
        let estimatedHeight = max(minHeight, min(maxHeight, CGFloat(messageText.count / 30 + 1) * 20 + 24))
        textFieldHeight = estimatedHeight
    }
}

#Preview {
    VStack {
        Spacer()
        ProfessionalMessageInput(
            messageText: .constant("Hello! I'm feeling great today! The sun is shining and life is beautiful!"),
            currentMood: .constant(.happy),
            isTyping: .constant(true),
            onSend: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}