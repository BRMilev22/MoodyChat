//
//  ChatView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var conversationManager = ConversationManager()
    @State private var messageText = ""
    @State private var currentMood: Mood = .neutral
    @State private var keyboardHeight: CGFloat = 0
    @State private var isTyping = false
    @Namespace private var messagesNamespace
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background that responds to mood
                GlassmorphismBackground(mood: currentMood)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    customNavigationHeader
                    
                    // Messages container with perfect spacing
                    messagesContainer(geometry: geometry)
                    
                    // Input area with liquid glass design
                    inputContainer
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentMood)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupConversation()
            observeKeyboard()
        }
    }
    
    private var customNavigationHeader: some View {
        HStack {
            // Back button with glass effect
            Button(action: { /* Navigate back */ }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: currentMood.primaryColor.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
            }
            
            Spacer()
            
            // Center title with mood indicator
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text("MoodyChat")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Animated mood emoji
                    Text(currentMood.emoji)
                        .font(.title3)
                        .scaleEffect(isTyping ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(2), value: isTyping)
                }
                
                // Subtle mood indicator
                Text(SentimentAnalysisService.shared.getCurrentAnalysisStrength())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
            
            Spacer()
            
            // Settings/menu button
            Button(action: { /* Show menu */ }) {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: currentMood.primaryColor.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    private func messagesContainer(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Top padding for visual breathing room
                    Color.clear.frame(height: 24)
                    
                    if let conversation = conversationManager.currentConversation {
                        ForEach(conversation.messages) { message in
                            MessageBubbleView(
                                message: message,
                                currentMood: currentMood,
                                namespace: messagesNamespace
                            )
                            .id(message.id)
                        }
                    } else {
                        welcomeMessage
                    }
                    
                    // Bottom padding to ensure last message is visible
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .onChange(of: conversationManager.currentConversation?.messages.count) { oldValue, newValue in
                if let lastMessage = conversationManager.currentConversation?.messages.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 24) {
            // Animated welcome icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [currentMood.primaryColor.opacity(0.2), currentMood.primaryColor.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text("🎭")
                    .font(.system(size: 56))
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: currentMood)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to MoodyChat")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your emotions shape every conversation. Start typing to see the magic unfold as your mood transforms the entire experience.")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    currentMood.primaryColor.opacity(0.3),
                                    currentMood.primaryColor.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: currentMood.primaryColor.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.top, 60)
    }
    
    private var inputContainer: some View {
        VStack(spacing: 0) {
            // Subtle divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, currentMood.primaryColor.opacity(0.2), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // Input area
            ProfessionalMessageInput(
                messageText: $messageText,
                currentMood: $currentMood,
                isTyping: $isTyping,
                onSend: sendMessage
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Set typing state
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isTyping = true
        }
        
        Task {
            await conversationManager.addMessage(messageText, isFromUser: true)
            
            // Update current mood with smooth animation
            if let lastMessage = conversationManager.currentConversation?.messages.last,
               let sentiment = lastMessage.sentiment,
               sentiment.confidence > 0.6 {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    currentMood = sentiment.mood
                }
            }
            
            // Clear the input with animation
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    messageText = ""
                    isTyping = false
                }
            }
            
            // Simulate AI response with realistic delay
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_500_000_000))
            await generateAIResponse()
        }
    }
    
    private func generateAIResponse() async {
        let moodBasedResponses: [Mood: [String]] = [
            .happy: [
                "Your positive energy is contagious! What's been bringing you joy lately?",
                "I love hearing the happiness in your message! Tell me more about what's going well.",
                "That wonderful mood of yours is shining through! What's made your day so bright?"
            ],
            .excited: [
                "Your excitement is electric! I can feel the energy in your words!",
                "Wow, you sound absolutely thrilled! What's got you so pumped up?",
                "That enthusiasm is amazing! Share more about what's getting you so excited!"
            ],
            .sad: [
                "I can sense you're going through something difficult. I'm here to listen.",
                "Your feelings are completely valid. Would you like to talk about what's weighing on you?",
                "I'm here for you. Sometimes sharing what's on our hearts can help."
            ],
            .anxious: [
                "I can feel the tension in your message. Take a deep breath - you're not alone in this.",
                "Anxiety can be overwhelming. What's been on your mind lately?",
                "I hear the worry in your words. Let's talk through what's causing you stress."
            ],
            .peaceful: [
                "There's such a calm, centered energy in your message. How are you finding this peace?",
                "Your tranquil mood is beautiful. What's helping you feel so balanced today?",
                "I love the serene vibe you're sharing. Tell me about this peaceful moment."
            ]
        ]
        
        let responses = moodBasedResponses[currentMood] ?? [
            "I'm here to listen and understand. What's on your mind?",
            "Thanks for sharing that with me. How are you feeling right now?",
            "I appreciate you opening up. What would you like to talk about?"
        ]
        
        let selectedResponse = responses.randomElement() ?? "I'm here to chat with you!"
        await conversationManager.addMessage(selectedResponse, isFromUser: false)
    }
    
    private func setupConversation() {
        if conversationManager.currentConversation == nil {
            conversationManager.startNewConversation(title: "Emotional Journey")
        }
    }
    
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}