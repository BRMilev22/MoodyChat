//
//  ContentView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct ContentView: View {
    @State private var animationProgress: CGFloat = 0
    @State private var showSecondaryElements = false
    @State private var currentMoodDemo: Mood = .peaceful
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Dynamic background
                    GlassmorphismBackground(mood: currentMoodDemo)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero section
                            heroSection(geometry: geometry)
                            
                            // Feature showcase
                            featureShowcase
                            
                            // Call to action
                            callToActionSection
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startWelcomeAnimation()
                startMoodCycling()
            }
        }
    }
    
    private func heroSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 60)
            
            // App icon with animated mood ring
            ZStack {
                // Outer ring with mood colors
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: currentMoodDemo.gradientColors + [currentMoodDemo.gradientColors.first!],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(animationProgress * 360))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: animationProgress)
                
                // Inner circle with app icon
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("🎭")
                            .font(.system(size: 56))
                            .scaleEffect(1.0 + sin(animationProgress * .pi * 2) * 0.1)
                    )
                    .shadow(color: currentMoodDemo.primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .scaleEffect(showSecondaryElements ? 1.0 : 0.8)
            .opacity(showSecondaryElements ? 1.0 : 0.0)
            
            // Title and tagline
            VStack(spacing: 16) {
                Text("MoodyChat")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: currentMoodDemo.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showSecondaryElements ? 1.0 : 0.9)
                    .opacity(showSecondaryElements ? 1.0 : 0.0)
                
                Text("Where emotions shape every conversation")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .scaleEffect(showSecondaryElements ? 1.0 : 0.9)
                    .opacity(showSecondaryElements ? 1.0 : 0.0)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 40)
        }
        .frame(height: geometry.size.height * 0.7)
    }
    
    private var featureShowcase: some View {
        VStack(spacing: 24) {
            // Section title
            Text("Experience Emotional Intelligence")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(showSecondaryElements ? 1.0 : 0.0)
            
            // Feature cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "AI Understanding",
                    description: "Advanced sentiment analysis that truly gets you",
                    mood: .peaceful
                )
                
                FeatureCard(
                    icon: "paintbrush.pointed.fill",
                    title: "Dynamic UI",
                    description: "Interface transforms with your emotions",
                    mood: .excited
                )
                
                FeatureCard(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "All processing happens on your device",
                    mood: .loving
                )
                
                FeatureCard(
                    icon: "sparkles",
                    title: "Liquid Glass",
                    description: "Beautiful iOS 26 design language",
                    mood: .happy
                )
            }
            .padding(.horizontal, 20)
            .opacity(showSecondaryElements ? 1.0 : 0.0)
        }
        .padding(.vertical, 32)
    }
    
    private var callToActionSection: some View {
        VStack(spacing: 24) {
            // Demo mood cycling
            VStack(spacing: 16) {
                Text("Currently feeling")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text(currentMoodDemo.emoji)
                        .font(.system(size: 32))
                        .scaleEffect(1.1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentMoodDemo)
                    
                    VStack(alignment: .leading) {
                        Text(currentMoodDemo.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(currentMoodDemo.primaryColor)
                        
                        Text("UI adapts in real-time")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            currentMoodDemo.primaryColor.opacity(0.4),
                                            currentMoodDemo.primaryColor.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: currentMoodDemo.primaryColor.opacity(0.2), radius: 12, x: 0, y: 6)
                )
            }
            
            // Primary CTA button
            NavigationLink(destination: ChatView()) {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Start Your Emotional Journey")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: currentMoodDemo.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: currentMoodDemo.primaryColor.opacity(0.4), radius: 16, x: 0, y: 8)
                )
            }
            .scaleEffect(showSecondaryElements ? 1.0 : 0.95)
            .opacity(showSecondaryElements ? 1.0 : 0.0)
            
            // Secondary button
            Button(action: { /* Demo mode */ }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle")
                        .font(.title3)
                    
                    Text("Watch Demo")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(currentMoodDemo.primaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(currentMoodDemo.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .scaleEffect(showSecondaryElements ? 1.0 : 0.95)
            .opacity(showSecondaryElements ? 1.0 : 0.0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private func startWelcomeAnimation() {
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3)) {
            showSecondaryElements = true
        }
        
        withAnimation(.linear(duration: 1.0)) {
            animationProgress = 1.0
        }
    }
    
    private func startMoodCycling() {
        let moods: [Mood] = [.peaceful, .happy, .excited, .loving, .peaceful]
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                currentMoodDemo = moods[currentIndex]
                currentIndex = (currentIndex + 1) % moods.count
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let mood: Mood
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(mood.primaryColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(mood.primaryColor.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(mood.primaryColor.opacity(0.2), lineWidth: 1)
                        )
                )
            
            // Content
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    mood.primaryColor.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: mood.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView()
}
