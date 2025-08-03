//
//  DynamicInputField.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import SwiftUI

struct DynamicInputField: View {
    @Binding var messageText: String
    @Binding var isTyping: Bool
    let currentMood: Mood
    let moodConfidence: Double
    let onSend: () -> Void
    
    @State private var isExpanded = false
    @State private var glowAnimation: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private var inputIntensity: UIIntensity {
        switch moodConfidence {
        case 0.0..<0.3: return .neutral
        case 0.3..<0.6: return .subtle(currentMood)
        case 0.6..<0.8: return .confident(currentMood)
        default: return .dramatic(currentMood)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            inputField
            sendButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(inputBackground)
        .onChange(of: messageText) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.2)) {
                isTyping = !newValue.isEmpty
                isExpanded = !newValue.isEmpty
            }
        }
        .onChange(of: currentMood) { oldMood, newMood in
            startMoodTransition()
        }
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private var inputField: some View {
        TextField("Type your message...", text: $messageText, axis: .vertical)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .focused($isTextFieldFocused)
            .lineLimit(1...6)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(textFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous)
                    .stroke(borderGradient, lineWidth: borderWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous)
                    .stroke(glowGradient, lineWidth: 2)
                    .blur(radius: 4)
                    .opacity(glowOpacity)
            )
            .scaleEffect(inputScale)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: inputIntensity)
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isExpanded)
    }
    
    private var sendButton: some View {
        Button(action: {
            guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                onSend()
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(sendButtonGradient)
                .frame(width: 44, height: 44)
                .background(sendButtonBackground)
                .clipShape(Circle())
                .shadow(color: sendButtonShadow, radius: sendButtonShadowRadius, x: 0, y: 4)
                .scaleEffect(sendButtonScale)
                .opacity(sendButtonOpacity)
        }
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isTyping)
        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: inputIntensity)
    }
    
    // MARK: - Styling
    
    private var textFieldBackground: some View {
        Group {
            switch inputIntensity {
            case .neutral:
                Color(.systemGray6).opacity(0.8)
                
            case .subtle(let mood):
                ZStack {
                    Color(.systemGray6).opacity(0.7)
                    mood.primaryColor.opacity(0.05)
                }
                
            case .confident(let mood):
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(.systemGray6).opacity(0.6),
                            mood.primaryColor.opacity(0.08),
                            Color(.systemGray6).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .init(x: -0.3 + glowAnimation, y: 0),
                        endPoint: .init(x: 0.3 + glowAnimation, y: 0)
                    )
                }
                
            case .dramatic(let mood):
                ZStack {
                    LinearGradient(
                        colors: [
                            mood.primaryColor.opacity(0.12),
                            Color(.systemGray6).opacity(0.5),
                            mood.primaryColor.opacity(0.15),
                            Color(.systemGray6).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.2),
                            mood.primaryColor.opacity(0.1),
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .init(x: -0.5 + glowAnimation, y: -0.3),
                        endPoint: .init(x: 0.5 + glowAnimation, y: 0.3)
                    )
                }
            }
        }
    }
    
    private var inputBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                currentMood.primaryColor.opacity(moodConfidence * 0.1),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Dynamic Properties
    
    private var dynamicCornerRadius: CGFloat {
        switch inputIntensity {
        case .neutral: return 22
        case .subtle: return 24
        case .confident: return 26
        case .dramatic: return 28
        }
    }
    
    private var inputScale: CGFloat {
        switch inputIntensity {
        case .neutral: return 1.0
        case .subtle: return 1.01
        case .confident: return 1.02
        case .dramatic: return 1.03
        }
    }
    
    private var borderGradient: LinearGradient {
        switch inputIntensity {
        case .neutral:
            return LinearGradient(
                colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .subtle(let mood):
            return LinearGradient(
                colors: [
                    mood.primaryColor.opacity(0.2),
                    .gray.opacity(0.1),
                    mood.primaryColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .confident(let mood):
            return LinearGradient(
                colors: mood.gradientColors.map { $0.opacity(0.3) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dramatic(let mood):
            return LinearGradient(
                colors: [
                    mood.primaryColor.opacity(0.5),
                    mood.gradientColors.first?.opacity(0.4) ?? mood.primaryColor.opacity(0.4),
                    mood.gradientColors.last?.opacity(0.3) ?? mood.primaryColor.opacity(0.3),
                    mood.primaryColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderWidth: CGFloat {
        switch inputIntensity {
        case .neutral: return 1
        case .subtle: return 1.5
        case .confident: return 2
        case .dramatic: return 2.5
        }
    }
    
    private var glowGradient: LinearGradient {
        LinearGradient(
            colors: [currentMood.primaryColor.opacity(0.6), currentMood.primaryColor.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glowOpacity: Double {
        switch inputIntensity {
        case .neutral: return 0
        case .subtle: return glowAnimation * 0.3
        case .confident: return glowAnimation * 0.5
        case .dramatic: return glowAnimation * 0.8
        }
    }
    
    // MARK: - Send Button Styling
    
    private var sendButtonGradient: LinearGradient {
        switch inputIntensity {
        case .neutral:
            return LinearGradient(
                colors: [.white, .white],
                startPoint: .top,
                endPoint: .bottom
            )
        case .subtle(let mood):
            return LinearGradient(
                colors: [.white, mood.primaryColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .confident(let mood):
            return LinearGradient(
                colors: [.white, mood.primaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dramatic(let mood):
            return LinearGradient(
                colors: [
                    .white,
                    mood.primaryColor.opacity(0.9),
                    mood.primaryColor,
                    mood.gradientColors.last?.opacity(0.8) ?? mood.primaryColor.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var sendButtonBackground: some View {
        Group {
            switch inputIntensity {
            case .neutral:
                Circle()
                    .fill(.blue)
                
            case .subtle(let mood):
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [mood.primaryColor.opacity(0.8), mood.primaryColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
            case .confident(let mood):
                Circle()
                    .fill(
                        LinearGradient(
                            colors: mood.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
            case .dramatic(let mood):
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    mood.primaryColor.opacity(0.9),
                                    mood.primaryColor,
                                    mood.gradientColors.last ?? mood.primaryColor
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear,
                                    mood.primaryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            }
        }
    }
    
    private var sendButtonScale: CGFloat {
        isTyping ? 1.0 : 0.8
    }
    
    private var sendButtonOpacity: Double {
        isTyping ? 1.0 : 0.6
    }
    
    private var sendButtonShadow: Color {
        switch inputIntensity {
        case .neutral: return .blue.opacity(0.3)
        case .subtle(let mood): return mood.primaryColor.opacity(0.4)
        case .confident(let mood): return mood.primaryColor.opacity(0.5)
        case .dramatic(let mood): return mood.primaryColor.opacity(0.7)
        }
    }
    
    private var sendButtonShadowRadius: CGFloat {
        switch inputIntensity {
        case .neutral: return 8
        case .subtle: return 12
        case .confident: return 16
        case .dramatic: return 20
        }
    }
    
    // MARK: - Animations
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowAnimation = 1.0
        }
    }
    
    private func startMoodTransition() {
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            glowAnimation = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAnimation = 1.0
            }
        }
    }
}