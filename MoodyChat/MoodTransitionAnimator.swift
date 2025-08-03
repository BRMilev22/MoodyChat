//
//  MoodTransitionAnimator.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import SwiftUI

struct MoodTransitionAnimator: View {
    let fromMood: Mood
    let toMood: Mood
    let confidence: Double
    let isVisible: Bool
    let onComplete: () -> Void
    
    @State private var animationProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rippleScale: CGFloat = 0.1
    @State private var glowOpacity: Double = 0
    @State private var particleOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    private var intensityLevel: String {
        switch confidence {
        case 0.0..<0.3: return "Detecting..."
        case 0.3..<0.6: return "Subtle"
        case 0.6..<0.8: return "Confident"
        default: return "Strong"
        }
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                // Fullscreen overlay with blur effect
                Rectangle()
                    .fill(.black.opacity(0.3))
                    .ignoresSafeArea()
                    .onTapGesture {
                        completeAnimation()
                    }
                
                // Main transition container
                VStack(spacing: 24) {
                    moodTransitionVisual
                    moodChangeText
                }
                .padding(32)
                .background(transitionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: toMood.primaryColor.opacity(0.3), radius: 30, x: 0, y: 15)
                .scaleEffect(pulseScale)
                .opacity(glowOpacity)
            }
            .onAppear {
                print("🎬 MoodTransitionAnimator appeared! From: \(fromMood.displayName) → To: \(toMood.displayName)")
                startTransitionAnimation()
            }
        }
    }
    
    private var moodTransitionVisual: some View {
        ZStack {
            // Background ripple effects
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .stroke(
                        toMood.primaryColor.opacity(0.2 - Double(index) * 0.03),
                        lineWidth: 3
                    )
                    .frame(width: 150 + CGFloat(index) * 30)
                    .scaleEffect(rippleScale + CGFloat(index) * 0.1)
                    .opacity(1.0 - Double(index) * 0.15)
            }
            
            // Central mood visualization
            ZStack {
                // Morphing background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                fromMood.primaryColor.opacity(1.0 - animationProgress),
                                toMood.primaryColor.opacity(animationProgress),
                                toMood.gradientColors.first?.opacity(animationProgress * 0.8) ?? toMood.primaryColor.opacity(animationProgress * 0.8)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // Particle system overlay
                ForEach(0..<12, id: \.self) { index in
                    moodParticle(index: index)
                }
                
                // Central emoji with morphing
                VStack(spacing: 8) {
                    Text(toMood.emoji)
                        .font(.system(size: 48))
                        .scaleEffect(1.0 + sin(animationProgress * .pi * 2) * 0.2)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // Mood name with typewriter effect
                    Text(toMood.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animationProgress > 0.7 ? 1.0 : 0.0)
                }
            }
            
            // Outer glow ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            toMood.primaryColor.opacity(0.8),
                            toMood.primaryColor.opacity(0.4),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(rotationAngle * 2))
                .opacity(glowOpacity)
        }
    }
    
    private var moodChangeText: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                // AI brain icon with pulse
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(toMood.primaryColor)
                    .scaleEffect(1.0 + sin(animationProgress * .pi * 4) * 0.1)
                
                Text("Mood Detected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .opacity(animationProgress > 0.3 ? 1.0 : 0.0)
            
            // Confidence level indicator
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            index < Int(confidence * 4) ?
                            toMood.primaryColor :
                            Color(.systemGray4)
                        )
                        .frame(width: 30, height: 4)
                        .animation(
                            .easeInOut(duration: 0.3)
                            .delay(Double(index) * 0.1),
                            value: animationProgress
                        )
                }
                
                Text(intensityLevel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .opacity(animationProgress > 0.5 ? 1.0 : 0.0)
            
            // Transformation message
            Text("UI adapting to your emotional state")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(animationProgress > 0.7 ? 1.0 : 0.0)
        }
    }
    
    private var transitionBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Mood-responsive gradient overlay
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            toMood.primaryColor.opacity(0.1 * animationProgress),
                            toMood.gradientColors.first?.opacity(0.05 * animationProgress) ?? toMood.primaryColor.opacity(0.05 * animationProgress),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Animated shimmer effect
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            toMood.primaryColor.opacity(0.1),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .init(x: -0.5 + particleOffset, y: -0.5),
                        endPoint: .init(x: 0.5 + particleOffset, y: 0.5)
                    )
                )
            
            // Border highlight
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            toMood.primaryColor.opacity(0.3 * animationProgress),
                            .clear,
                            toMood.primaryColor.opacity(0.2 * animationProgress)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
    }
    
    private func moodParticle(index: Int) -> some View {
        let angle = Double(index) * 30.0
        let radius: CGFloat = 60 + CGFloat(index % 3) * 10
        
        return Circle()
            .fill(toMood.primaryColor.opacity(0.6))
            .frame(width: 4, height: 4)
            .offset(
                x: cos(angle * .pi / 180) * radius * animationProgress,
                y: sin(angle * .pi / 180) * radius * animationProgress
            )
            .scaleEffect(1.0 + sin(animationProgress * .pi * 3 + Double(index)) * 0.5)
            .opacity(animationProgress > 0.2 ? 0.8 : 0.0)
            .blur(radius: 1)
    }
    
    // MARK: - Animations
    
    private func startTransitionAnimation() {
        // Haptic feedback at start
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Initial appearance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            glowOpacity = 1.0
            pulseScale = 1.0
        }
        
        // Main transition animation
        withAnimation(.easeInOut(duration: 2.5)) {
            animationProgress = 1.0
        }
        
        // Continuous animations
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            rippleScale = 1.2
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            particleOffset = 1.0
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
        
        // Auto-complete after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            completeAnimation()
        }
    }
    
    private func completeAnimation() {
        // Final haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            glowOpacity = 0.0
            pulseScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Mood Transition Coordinator

class MoodTransitionCoordinator: ObservableObject {
    @Published var isShowingTransition = false {
        didSet {
            print("🎭 isShowingTransition changed to: \(isShowingTransition)")
        }
    }
    @Published var transitionFromMood: Mood = .neutral
    @Published var transitionToMood: Mood = .neutral
    @Published var transitionConfidence: Double = 0.0
    
    private var pendingMoodChange: (Mood, Double)?
    
    func triggerMoodTransition(from: Mood, to: Mood, confidence: Double) {
        print("🎬 Transition triggered: \(from.displayName) → \(to.displayName) (confidence: \(confidence))")
        
        // Only show transition for significant mood changes (lower threshold)
        guard from != to && confidence > 0.2 else {
            print("❌ Transition rejected: same mood or low confidence")
            return
        }
        
        // Don't show new transition if one is already showing
        guard !isShowingTransition else {
            print("❌ Transition already in progress, skipping")
            return
        }
        
        print("✅ Transition approved - showing animation!")
        
        // Store the pending change
        pendingMoodChange = (to, confidence)
        
        // Set up transition
        transitionFromMood = from
        transitionToMood = to
        transitionConfidence = confidence
        
        // Show transition animation on main thread with proper timing
        DispatchQueue.main.async {
            print("🎭 Setting isShowingTransition to true on main thread")
            // Ensure clean animation state
            self.isShowingTransition = true
            print("🎬 Animation state is now: \(self.isShowingTransition)")
        }
    }
    
    func completeTransition() -> (Mood, Double)? {
        isShowingTransition = false
        let result = pendingMoodChange
        pendingMoodChange = nil
        return result
    }
}

#Preview {
    @State var isVisible = true
    
    return ZStack {
        Color.black.ignoresSafeArea()
        
        MoodTransitionAnimator(
            fromMood: .neutral,
            toMood: .excited,
            confidence: 0.9,
            isVisible: isVisible,
            onComplete: {
                isVisible = false
            }
        )
    }
}