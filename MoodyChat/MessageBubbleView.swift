//
//  MessageBubbleView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let currentMood: Mood
    let namespace: Namespace.ID
    
    @State private var isVisible = false
    @State private var showDetails = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 60)
                userMessageBubble
            } else {
                assistantMessageBubble
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Message content
            HStack(alignment: .bottom, spacing: 8) {
                // Message text
                Text(message.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: message.sentiment?.mood.gradientColors ?? currentMood.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: (message.sentiment?.mood ?? currentMood).primaryColor.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
                    .matchedGeometryEffect(id: "message-\(message.id)", in: namespace)
                
                // Mood emoji with animation
                if let sentiment = message.sentiment {
                    VStack(spacing: 4) {
                        Text(sentiment.mood.emoji)
                            .font(.title2)
                            .scaleEffect(showDetails ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showDetails)
                        
                        // Confidence indicator
                        Circle()
                            .fill(sentiment.mood.primaryColor)
                            .frame(width: 6, height: 6)
                            .opacity(sentiment.confidence)
                            .scaleEffect(1.0 + sentiment.confidence * 0.5)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showDetails.toggle()
                        }
                    }
                }
            }
            
            // Message metadata
            HStack(spacing: 8) {
                if let sentiment = message.sentiment {
                    // Sentiment details
                    if showDetails {
                        HStack(spacing: 4) {
                            Text(sentiment.mood.displayName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(sentiment.mood.primaryColor)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(sentiment.confidence * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(sentiment.mood.primaryColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Time stamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
        }
    }
    
    private var assistantMessageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message content with assistant styling
            HStack(alignment: .bottom, spacing: 12) {
                // Assistant avatar
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    currentMood.primaryColor.opacity(0.2),
                                    currentMood.primaryColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("🤖")
                        .font(.system(size: 18))
                }
                .shadow(color: currentMood.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Message text with glass morphism
                Text(message.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.primary.opacity(0.1),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .matchedGeometryEffect(id: "assistant-message-\(message.id)", in: namespace)
            }
            
            // Assistant metadata
            HStack(spacing: 8) {
                Text("MoodyBot")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(currentMood.primaryColor)
                
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
                
                Spacer()
                
                // Response indicator
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(currentMood.primaryColor.opacity(0.6))
                            .frame(width: 3, height: 3)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: currentMood
                            )
                    }
                }
            }
            .padding(.leading, 44) // Align with message content
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// Enhanced mood indicator with professional styling
struct EnhancedMoodIndicator: View {
    let mood: Mood
    let confidence: Double
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Mood emoji with subtle animation
            Text(mood.emoji)
                .font(.title3)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Confidence ring
            ZStack {
                Circle()
                    .stroke(mood.primaryColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(
                        AngularGradient(
                            colors: mood.gradientColors,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * confidence)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: confidence)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [mood.primaryColor.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: mood.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            MessageBubbleView(
                message: Message(text: "Hello! I'm feeling absolutely wonderful today! The sun is shining and life is beautiful!", isFromUser: true),
                currentMood: .happy,
                namespace: Namespace().wrappedValue
            )
            
            MessageBubbleView(
                message: Message(text: "That's amazing to hear! Your positive energy is really shining through. What's been bringing you so much joy today?", isFromUser: false),
                currentMood: .happy,
                namespace: Namespace().wrappedValue
            )
            
            EnhancedMoodIndicator(mood: .happy, confidence: 0.87)
        }
        .padding()
    }
    .background(GlassmorphismBackground(mood: .happy))
}