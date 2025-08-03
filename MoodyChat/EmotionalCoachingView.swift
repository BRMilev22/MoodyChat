//
//  EmotionalCoachingView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct EmotionalCoachingView: View {
    @StateObject private var aiService = AIEnhancedSentimentService.shared
    @StateObject private var conversationManager = ConversationManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCoachingTab: CoachingTab = .insights
    @State private var showMoodPicker = false
    @State private var selectedMood: Mood = .neutral
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with mood selector
                coachingHeader
                
                // Tab picker
                coachingTabPicker
                
                // Content based on selected tab
                ScrollView {
                    LazyVStack(spacing: 20) {
                        switch selectedCoachingTab {
                        case .insights:
                            conversationInsightsSection
                        case .coaching:
                            emotionalCoachingSection
                        case .responses:
                            smartResponsesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Emotional Coach")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        selectedMood.primaryColor.opacity(0.05),
                        selectedMood.gradientColors.last?.opacity(0.03) ?? Color(.systemBackground),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
    
    private var coachingHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Emotional Intelligence Companion")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AI-powered insights and personalized coaching")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showMoodPicker.toggle() }) {
                    HStack(spacing: 8) {
                        Text(selectedMood.emoji)
                            .font(.title2)
                        
                        Text(selectedMood.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMood.primaryColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(selectedMood.primaryColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(selectedMood.primaryColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .sheet(isPresented: $showMoodPicker) {
                    moodPickerSheet
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .horizontal)
        )
    }
    
    private var coachingTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(CoachingTab.allCases, id: \.self) { tab in
                Button(action: { selectedCoachingTab = tab }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedCoachingTab == tab ? selectedMood.primaryColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(selectedCoachingTab == tab ? selectedMood.primaryColor.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .background(.thinMaterial)
    }
    
    private var conversationInsightsSection: some View {
        VStack(spacing: 20) {
            if let insights = aiService.currentInsights {
                // Dominant mood card
                CoachingInsightCard(
                    title: "Current Emotional State",
                    icon: "brain.head.profile",
                    color: selectedMood.primaryColor
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Dominant Mood:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(insights.dominantMood.capitalized)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Emotional Intensity:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            EmotionalIntensityBar(intensity: insights.emotionalIntensity)
                        }
                        
                        Text("Progression: \(insights.moodProgression.capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Personality insights
                CoachingInsightCard(
                    title: "Personality Traits",
                    icon: "person.crop.circle",
                    color: .blue
                ) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(insights.personalityTraits, id: \.self) { trait in
                            Text(trait)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.blue.opacity(0.1))
                                )
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Communication style
                CoachingInsightCard(
                    title: "Communication Style",
                    icon: "bubble.left.and.bubble.right",
                    color: .green
                ) {
                    Text(insights.communicationStyle.capitalized)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                }
                
                // Emotional triggers
                if !insights.keyEmotionalTriggers.isEmpty {
                    CoachingInsightCard(
                        title: "Emotional Triggers",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(insights.keyEmotionalTriggers, id: \.self) { trigger in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(.orange.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    
                                    Text(trigger)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "No Insights Yet",
                    subtitle: "Start a conversation to receive AI-powered emotional insights"
                )
            }
        }
    }
    
    private var emotionalCoachingSection: some View {
        VStack(spacing: 20) {
            if let coaching = aiService.emotionalCoaching {
                // Understanding & validation
                CoachingCard(
                    title: "Understanding",
                    icon: "heart",
                    color: .pink,
                    content: coaching.understanding
                )
                
                CoachingCard(
                    title: "Validation",
                    icon: "checkmark.seal",
                    color: .green,
                    content: coaching.validation
                )
                
                // Insights
                CoachingCard(
                    title: "Psychological Insights",
                    icon: "brain",
                    color: .purple,
                    content: coaching.insights
                )
                
                // Coping strategies
                ActionCard(
                    title: "Coping Strategies",
                    icon: "shield",
                    color: .blue,
                    items: coaching.copingStrategies
                )
                
                // Reframing techniques
                ActionCard(
                    title: "Reframing Techniques",
                    icon: "arrow.clockwise",
                    color: .indigo,
                    items: coaching.reframingTechniques
                )
                
                // Actionable steps
                ActionCard(
                    title: "Actionable Steps",
                    icon: "list.bullet",
                    color: .orange,
                    items: coaching.actionableSteps
                )
                
                // Affirmations
                AffirmationsCard(affirmations: coaching.affirmations)
                
                // Mood boost suggestions
                ActionCard(
                    title: "Mood Boosters",
                    icon: "sun.max",
                    color: .yellow,
                    items: coaching.moodBoostSuggestions
                )
                
            } else if aiService.isAnalyzing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Generating personalized coaching...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                EmptyStateView(
                    icon: "graduationcap",
                    title: "No Coaching Available",
                    subtitle: "Share your thoughts to receive personalized emotional coaching"
                )
            }
        }
    }
    
    private var smartResponsesSection: some View {
        VStack(spacing: 20) {
            // AI response suggestions
            if let coaching = aiService.emotionalCoaching {
                CoachingInsightCard(
                    title: "Thoughtful Follow-up Questions",
                    icon: "questionmark.bubble",
                    color: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(coaching.followUpQuestions, id: \.self) { question in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "quote.bubble")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 2)
                                
                                Text(question)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Response suggestions based on current insights
                if let insights = aiService.currentInsights {
                    CoachingInsightCard(
                        title: "Supportive Response",
                        icon: "heart.text.square",
                        color: .pink
                    ) {
                        Text(insights.supportiveResponse)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // AI recommendations
                    ActionCard(
                        title: "AI Recommendations",
                        icon: "lightbulb",
                        color: .yellow,
                        items: insights.recommendations
                    )
                }
                
            } else {
                EmptyStateView(
                    icon: "message.badge",
                    title: "Smart Responses",
                    subtitle: "Continue your conversation to unlock AI-powered response suggestions"
                )
            }
        }
    }
    
    private var moodPickerSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("How are you feeling right now?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button(action: {
                            selectedMood = mood
                            showMoodPicker = false
                            
                            // Generate coaching for selected mood
                            Task {
                                await aiService.generateEmotionalCoaching(
                                    for: mood,
                                    message: "I'm feeling \(mood.displayName.lowercased())",
                                    userHistory: conversationManager.currentConversation?.messages.filter { $0.isFromUser } ?? []
                                )
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(mood.emoji)
                                    .font(.system(size: 32))
                                
                                Text(mood.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                moodButtonBackground(mood: mood, isSelected: mood == selectedMood)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Select Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showMoodPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func moodButtonBackground(mood: Mood, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isSelected ? mood.primaryColor.opacity(0.2) : Color(.systemGray5).opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? mood.primaryColor : .clear, lineWidth: 2)
            )
    }
}

// MARK: - Supporting Views

struct EmotionalIntensityBar: View {
    let intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 6)
                    .cornerRadius(3)
                
                Rectangle()
                    .fill(intensityColor)
                    .frame(width: geometry.size.width * intensity, height: 6)
                    .cornerRadius(3)
            }
        }
        .frame(height: 6)
    }
    
    private var intensityColor: Color {
        switch intensity {
        case 0.0..<0.3: return .green
        case 0.3..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct CoachingCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                        }
                        
                        Text(item)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct AffirmationsCard: View {
    let affirmations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.circle")
                    .font(.title3)
                    .foregroundColor(.pink)
                
                Text("Positive Affirmations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(affirmations, id: \.self) { affirmation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundColor(.pink)
                            .padding(.top, 2)
                        
                        Text(affirmation)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.pink.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct CoachingInsightCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Supporting Types

enum CoachingTab: String, CaseIterable {
    case insights = "Insights"
    case coaching = "Coaching"
    case responses = "Responses"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .insights: return "brain.head.profile"
        case .coaching: return "graduationcap"
        case .responses: return "message.badge"
        }
    }
}

#Preview {
    EmotionalCoachingView()
}