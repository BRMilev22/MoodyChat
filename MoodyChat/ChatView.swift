//
//  ChatView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var aiService = AIEnhancedSentimentService.shared
    @StateObject private var moodDetector = ProgressiveMoodDetector.shared
    @State private var messageText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isTyping = false
    @State private var showAnalytics = false
    @State private var showCoaching = false
    @State private var showJournal = false
    @Namespace private var messagesNamespace
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Progressive mood-responsive background
                Color.clear
                    .adaptiveMoodBackground(moodDetector.uiIntensity)
                    .ignoresSafeArea()
                    .onChange(of: moodDetector.uiIntensity) { oldValue, newValue in
                        print("🎨 Background changed from \(oldValue.description) to \(newValue.description)")
                    }
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    customNavigationHeader
                    
                    // Messages container with perfect spacing
                    messagesContainer(geometry: geometry)
                    
                    // Dynamic mood-responsive input
                    DynamicInputField(
                        messageText: $messageText,
                        isTyping: $isTyping,
                        currentMood: moodDetector.currentMood,
                        moodConfidence: moodDetector.moodConfidence,
                        onSend: sendMessage
                    )
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: moodDetector.uiIntensity.description)
                
                // Stunning mood transition overlay with clean animation
                if moodDetector.transitionCoordinator.isShowingTransition {
                    MoodTransitionAnimator(
                        fromMood: moodDetector.transitionCoordinator.transitionFromMood,
                        toMood: moodDetector.transitionCoordinator.transitionToMood,
                        confidence: moodDetector.transitionCoordinator.transitionConfidence,
                        isVisible: moodDetector.transitionCoordinator.isShowingTransition,
                        onComplete: {
                            print("🎬 Transition animation completed!")
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if let (newMood, newConfidence) = moodDetector.transitionCoordinator.completeTransition() {
                                    print("🎭 Applying final mood: \(newMood.displayName) with confidence: \(newConfidence)")
                                    moodDetector.applyMoodTransition(mood: newMood, confidence: newConfidence)
                                }
                            }
                        }
                    )
                    .zIndex(1000)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9, anchor: .center).combined(with: .opacity),
                        removal: .scale(scale: 1.1, anchor: .center).combined(with: .opacity)
                    ))
                    .onAppear {
                        print("🎬 ChatView: MoodTransitionAnimator added to view hierarchy")
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAnalytics) {
            MoodAnalyticsView()
        }
        .sheet(isPresented: $showCoaching) {
            EmotionalCoachingView()
        }
        .sheet(isPresented: $showJournal) {
            MoodJournalView()
        }
        .onAppear {
            setupConversation()
            observeKeyboard()
        }
    }
    
    private var customNavigationHeader: some View {
        HStack {
            // Back button with adaptive glass effect
            Button(action: { /* Navigate back */ }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AdaptiveUISystem.glassIntensity(for: moodDetector.uiIntensity))
                            .shadow(color: moodDetector.currentMood.primaryColor.opacity(moodDetector.moodConfidence * 0.3), radius: 8, x: 0, y: 4)
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
                    
                    // Progressive mood indicator with AI analysis status
                    HStack(spacing: 4) {
                        Text(moodDetector.currentMood.emoji)
                            .font(.title3)
                            .scaleEffect(isTyping ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(2), value: isTyping)
                        
                        // AI analysis indicator
                        if moodDetector.transitionCoordinator.isShowingTransition {
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(moodDetector.currentMood.primaryColor)
                                        .frame(width: 3, height: 3)
                                        .scaleEffect(0.5)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                            value: moodDetector.transitionCoordinator.isShowingTransition
                                        )
                                }
                            }
                        } else if moodDetector.moodConfidence > 0.1 {
                            // Confidence indicator
                            Circle()
                                .fill(moodDetector.currentMood.primaryColor)
                                .frame(width: 6, height: 6)
                                .opacity(moodDetector.moodConfidence)
                                .scaleEffect(moodDetector.moodConfidence > 0.8 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5), value: moodDetector.moodConfidence)
                        }
                    }
                }
                
                // Progressive mood status
                Text(moodDetector.uiIntensity.description)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.3), value: moodDetector.uiIntensity)
            }
            
            Spacer()
            
            // AI Features menu
            Menu {
                Button(action: { showAnalytics = true }) {
                    Label("Mood Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                
                Button(action: { showCoaching = true }) {
                    Label("Emotional Coach", systemImage: "brain.head.profile")
                }
                
                Button(action: { showJournal = true }) {
                    Label("Mood Journal", systemImage: "book.closed")
                }
                
                Divider()
                
                Button(action: { /* Settings */ }) {
                    Label("Settings", systemImage: "gear")
                }
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AdaptiveUISystem.glassIntensity(for: moodDetector.uiIntensity))
                            .shadow(color: moodDetector.currentMood.primaryColor.opacity(moodDetector.moodConfidence * 0.3), radius: 8, x: 0, y: 4)
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
                            DynamicMessageBubble(
                                message: message,
                                currentMood: moodDetector.currentMood,
                                moodConfidence: moodDetector.moodConfidence,
                                namespace: messagesNamespace
                            )
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
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
        VStack(spacing: 32) {
            // Dynamic animated icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            moodDetector.currentMood.primaryColor.opacity(0.1 - Double(index) * 0.03),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(140 + index * 30))
                        .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate + Double(index)) * 0.1)
                }
                
                // Main background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                moodDetector.currentMood.primaryColor.opacity(0.3),
                                moodDetector.currentMood.primaryColor.opacity(0.1),
                                moodDetector.currentMood.primaryColor.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // Emoji with subtle animation
                Text("🎭")
                    .font(.system(size: 64))
                    .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 2) * 0.05)
                    .rotationEffect(.degrees(sin(Date().timeIntervalSinceReferenceDate) * 2))
            }
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: moodDetector.currentMood)
            
            VStack(spacing: 20) {
                Text("Welcome to MoodyChat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .primary,
                                moodDetector.currentMood.primaryColor.opacity(0.8),
                                .primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your emotions shape every conversation. Start typing to see the magic unfold as your mood transforms the entire experience.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                
                // Feature highlights
                VStack(spacing: 12) {
                    FeatureRow(icon: "brain.head.profile", title: "AI Mood Detection", description: "Powered by OLLAMA")
                    FeatureRow(icon: "sparkles", title: "Dynamic UI", description: "Liquid glass iOS 26 design")
                    FeatureRow(icon: "heart.fill", title: "Emotional Intelligence", description: "Context-aware responses")
                }
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .adaptiveMoodCard(moodDetector.uiIntensity)
        .padding(.top, 40)
    }
    
    private func FeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(moodDetector.currentMood.primaryColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var inputContainer: some View {
        VStack(spacing: 0) {
            // Subtle divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, moodDetector.currentMood.primaryColor.opacity(moodDetector.moodConfidence * 0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // Input area
            ProfessionalMessageInput(
                messageText: $messageText,
                currentMood: .constant(moodDetector.currentMood),
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
        
        let currentMessage = messageText
        
        // STEP 1: Immediately display message and clear input
        withAnimation(.easeOut(duration: 0.2)) {
            messageText = ""
            isTyping = false
        }
        
        Task {
            // STEP 2: Add message to conversation immediately (instant display)
            await MainActor.run {
                conversationManager.addMessageInstantly(currentMessage, isFromUser: true)
            }
            
            // STEP 3: Analyze mood in background (progressive learning)
            await moodDetector.analyzeMessage(currentMessage)
        }
    }
    
    private func generateAIResponse() async {
        // Use the AI-enhanced service to generate contextual responses
        let smartResponse = await conversationManager.generateSmartResponse(for: moodDetector.currentMood)
        await conversationManager.addMessage(smartResponse, isFromUser: false)
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