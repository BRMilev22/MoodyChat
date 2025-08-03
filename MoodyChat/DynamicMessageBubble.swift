//
//  DynamicMessageBubble.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import SwiftUI

struct DynamicMessageBubble: View {
    let message: Message
    let currentMood: Mood
    let moodConfidence: Double
    let namespace: Namespace.ID
    
    @State private var animationOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    
    private var bubbleIntensity: UIIntensity {
        switch moodConfidence {
        case 0.0..<0.3: return .neutral
        case 0.3..<0.6: return .subtle(currentMood)
        case 0.6..<0.8: return .confident(currentMood)
        default: return .dramatic(currentMood)
        }
    }
    
    private var isUserMessage: Bool {
        message.isFromUser
    }
    
    var body: some View {
        HStack {
            if isUserMessage {
                Spacer()
                userMessageBubble
            } else {
                assistantMessageBubble
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            startAnimations()
        }
        .onChange(of: currentMood) { oldMood, newMood in
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                glowIntensity = moodConfidence * 0.8
            }
        }
    }
    
    private var userMessageBubble: some View {
        Text(message.text)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(userBubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .overlay(
                RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous)
                    .stroke(glowColor, lineWidth: glowLineWidth)
                    .blur(radius: 3)
                    .opacity(glowIntensity)
            )
            .scaleEffect(bubbleScale)
            .matchedGeometryEffect(id: "message-\(message.id)", in: namespace)
            .animation(.spring(response: 0.6, dampingFraction: 0.9), value: bubbleIntensity)
    }
    
    private var assistantMessageBubble: some View {
        Text(message.text)
            .font(.body)
            .fontWeight(.regular)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .scaleEffect(0.98)
            .matchedGeometryEffect(id: "message-\(message.id)", in: namespace)
    }
    
    // MARK: - User Message Styling
    
    private var userBubbleBackground: some View {
        Group {
            switch bubbleIntensity {
            case .neutral:
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.8),
                        Color.blue.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .subtle(let mood):
                LinearGradient(
                    colors: [
                        mood.primaryColor.opacity(0.7),
                        mood.primaryColor.opacity(0.85),
                        mood.gradientColors.last?.opacity(0.8) ?? mood.primaryColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .confident(let mood):
                ZStack {
                    LinearGradient(
                        colors: mood.gradientColors.map { $0.opacity(0.9) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .clear,
                            mood.primaryColor.opacity(0.1),
                            .clear,
                            .white.opacity(0.15)
                        ],
                        startPoint: .init(x: -0.3 + animationOffset, y: -0.3 + animationOffset),
                        endPoint: .init(x: 0.3 + animationOffset, y: 0.3 + animationOffset)
                    )
                }
                
            case .dramatic(let mood):
                ZStack {
                    LinearGradient(
                        colors: [
                            mood.primaryColor.opacity(0.95),
                            mood.gradientColors.first?.opacity(0.9) ?? mood.primaryColor.opacity(0.9),
                            mood.gradientColors.last?.opacity(0.85) ?? mood.primaryColor.opacity(0.85),
                            mood.primaryColor.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            mood.primaryColor.opacity(0.2),
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .init(x: -0.5 + animationOffset, y: -0.5 + animationOffset),
                        endPoint: .init(x: 0.5 + animationOffset, y: 0.5 + animationOffset)
                    )
                }
            }
        }
    }
    
    // MARK: - Dynamic Properties
    
    private var dynamicCornerRadius: CGFloat {
        switch bubbleIntensity {
        case .neutral: return 18
        case .subtle: return 20
        case .confident: return 22
        case .dramatic: return 25
        }
    }
    
    private var bubbleScale: CGFloat {
        switch bubbleIntensity {
        case .neutral: return 1.0
        case .subtle: return 1.02
        case .confident: return 1.04
        case .dramatic: return 1.06
        }
    }
    
    private var glowColor: Color {
        switch bubbleIntensity {
        case .neutral: return .clear
        case .subtle(let mood): return mood.primaryColor.opacity(0.3)
        case .confident(let mood): return mood.primaryColor.opacity(0.5)
        case .dramatic(let mood): return mood.primaryColor.opacity(0.8)
        }
    }
    
    private var glowLineWidth: CGFloat {
        switch bubbleIntensity {
        case .neutral: return 0
        case .subtle: return 0.5
        case .confident: return 1.0
        case .dramatic: return 1.5
        }
    }
    
    private var shadowColor: Color {
        switch bubbleIntensity {
        case .neutral: return .black.opacity(0.1)
        case .subtle(let mood): return mood.primaryColor.opacity(0.15)
        case .confident(let mood): return mood.primaryColor.opacity(0.25)
        case .dramatic(let mood): return mood.primaryColor.opacity(0.4)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch bubbleIntensity {
        case .neutral: return 8
        case .subtle: return 12
        case .confident: return 16
        case .dramatic: return 24
        }
    }
    
    private var shadowOffset: CGFloat {
        switch bubbleIntensity {
        case .neutral: return 4
        case .subtle: return 6
        case .confident: return 8
        case .dramatic: return 12
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            animationOffset = 1.0
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = moodConfidence * 0.8
        }
    }
}