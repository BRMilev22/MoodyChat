//
//  AdaptiveUISystem.swift
//  MoodyChat
//
//  Created by Boris Milev on 2.08.25.
//

import SwiftUI

struct AdaptiveUISystem {
    static func backgroundGradient(for intensity: UIIntensity) -> some View {
        switch intensity {
        case .neutral:
            return AnyView(neutralBackground)
        case .subtle(let mood):
            return AnyView(subtleBackground(mood: mood))
        case .confident(let mood):
            return AnyView(confidentBackground(mood: mood))
        case .dramatic(let mood):
            return AnyView(dramaticBackground(mood: mood))
        }
    }
    
    static func cardStyle(for intensity: UIIntensity) -> some View {
        switch intensity {
        case .neutral:
            return AnyView(neutralCard)
        case .subtle(let mood):
            return AnyView(subtleCard(mood: mood))
        case .confident(let mood):
            return AnyView(confidentCard(mood: mood))
        case .dramatic(let mood):
            return AnyView(dramaticCard(mood: mood))
        }
    }
    
    static func glassIntensity(for intensity: UIIntensity) -> Material {
        switch intensity {
        case .neutral:
            return .ultraThinMaterial
        case .subtle:
            return .thinMaterial
        case .confident:
            return .regularMaterial
        case .dramatic:
            return .thickMaterial
        }
    }
}

// MARK: - Neutral State (Animated Default)

private var neutralBackground: some View {
    ZStack {
        // Constantly flowing animated gradient with deeper movement
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [
                    Color(.systemGray6).opacity(0.4),
                    Color(.systemBackground).opacity(0.9),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .init(
                    x: 0.1 + sin(time * 0.4) * 0.5,
                    y: 0.1 + cos(time * 0.3) * 0.5
                ),
                endPoint: .init(
                    x: 0.9 + sin(time * 0.5) * 0.4,
                    y: 0.9 + cos(time * 0.4) * 0.4
                )
            )
        }
        
        // Animated floating elements that drift
        ForEach(0..<10, id: \.self) { index in
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: CGFloat.random(in: 30...100))
                .offset(
                    x: CGFloat.random(in: -200...200) + sin(Date().timeIntervalSinceReferenceDate * 0.5 + Double(index)) * 30,
                    y: CGFloat.random(in: -400...400) + cos(Date().timeIntervalSinceReferenceDate * 0.3 + Double(index)) * 20
                )
                .blur(radius: 15)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Gentle pulsing overlay
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        .clear,
                        Color(.systemGray5).opacity(0.1),
                        .clear
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 300
                )
            )
            .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 0.8) * 0.1)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: Date().timeIntervalSinceReferenceDate)
    }
}

private var neutralCard: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
}

// MARK: - Subtle State (First Hints)

private func subtleBackground(mood: Mood) -> some View {
    ZStack {
        // Constantly flowing mood gradient with deep liquid movement
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [
                    mood.primaryColor.opacity(0.4),
                    Color(.systemBackground).opacity(0.6),
                    mood.gradientColors.last?.opacity(0.35) ?? mood.primaryColor.opacity(0.35)
                ],
                startPoint: .init(
                    x: 0.0 + sin(time * 0.6) * 0.6,
                    y: 0.0 + cos(time * 0.4) * 0.6
                ),
                endPoint: .init(
                    x: 1.0 + sin(time * 0.7) * 0.5,
                    y: 1.0 + cos(time * 0.5) * 0.5
                )
            )
        }
        
        // Animated mood particles that float and pulse
        ForEach(0..<12, id: \.self) { index in
            Circle()
                .fill(mood.primaryColor.opacity(0.15))
                .frame(width: CGFloat.random(in: 40...100))
                .offset(
                    x: CGFloat.random(in: -150...150) + sin(Date().timeIntervalSinceReferenceDate * 0.4 + Double(index)) * 40,
                    y: CGFloat.random(in: -300...300) + cos(Date().timeIntervalSinceReferenceDate * 0.6 + Double(index)) * 30
                )
                .blur(radius: 20)
                .scaleEffect(0.8 + sin(Date().timeIntervalSinceReferenceDate * 1.2 + Double(index)) * 0.3)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Flowing gradient overlay
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        mood.primaryColor.opacity(0.1),
                        .clear,
                        mood.primaryColor.opacity(0.08),
                        .clear
                    ],
                    startPoint: .init(x: -0.5 + sin(Date().timeIntervalSinceReferenceDate * 0.5), y: 0),
                    endPoint: .init(x: 0.5 + sin(Date().timeIntervalSinceReferenceDate * 0.5), y: 1)
                )
            )
            .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: Date().timeIntervalSinceReferenceDate)
    }
}

private func subtleCard(mood: Mood) -> some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            mood.primaryColor.opacity(0.1),
                            .clear,
                            mood.primaryColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: mood.primaryColor.opacity(0.05), radius: 12, x: 0, y: 6)
}

// MARK: - Confident State (Clear Mood Detection)

private func confidentBackground(mood: Mood) -> some View {
    ZStack {
        // EXTREMELY flowing mood gradient with intense liquid movement
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [
                    mood.primaryColor.opacity(0.7),
                    mood.gradientColors.first?.opacity(0.5) ?? mood.primaryColor.opacity(0.5),
                    Color(.systemBackground).opacity(0.2),
                    mood.gradientColors.last?.opacity(0.45) ?? mood.primaryColor.opacity(0.45),
                    mood.primaryColor.opacity(0.6)
                ],
                startPoint: .init(
                    x: -0.2 + sin(time * 0.8) * 0.7,
                    y: -0.2 + cos(time * 0.6) * 0.7
                ),
                endPoint: .init(
                    x: 1.2 + sin(time * 0.9) * 0.6,
                    y: 1.2 + cos(time * 0.7) * 0.6
                )
            )
        }
        
        // Mood-specific patterns (much more visible)
        moodSpecificPattern(mood: mood, intensity: 0.8)
        
        // Dynamic animated particles with stronger colors and movement
        ForEach(0..<20, id: \.self) { index in
            Circle()
                .fill(mood.primaryColor.opacity(0.3))
                .frame(width: CGFloat.random(in: 30...80))
                .offset(
                    x: CGFloat.random(in: -200...200) + sin(Date().timeIntervalSinceReferenceDate * 0.8 + Double(index)) * 60,
                    y: CGFloat.random(in: -400...400) + cos(Date().timeIntervalSinceReferenceDate * 0.6 + Double(index)) * 40
                )
                .blur(radius: 10)
                .scaleEffect(0.7 + sin(Date().timeIntervalSinceReferenceDate * 1.5 + Double(index)) * 0.4)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.05), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Flowing energy waves
        ForEach(0..<3, id: \.self) { waveIndex in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            mood.primaryColor.opacity(0.2),
                            mood.gradientColors.first?.opacity(0.15) ?? mood.primaryColor.opacity(0.15),
                            .clear
                        ],
                        startPoint: .init(
                            x: -1.0 + sin(Date().timeIntervalSinceReferenceDate * 0.7 + Double(waveIndex)), 
                            y: CGFloat.random(in: -0.5...0.5)
                        ),
                        endPoint: .init(
                            x: 1.0 + sin(Date().timeIntervalSinceReferenceDate * 0.7 + Double(waveIndex)), 
                            y: CGFloat.random(in: -0.5...0.5)
                        )
                    )
                )
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Additional immersive overlay
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        mood.primaryColor.opacity(0.1),
                        .clear,
                        mood.primaryColor.opacity(0.05)
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
            )
    }
}

private func confidentCard(mood: Mood) -> some View {
    RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: mood.gradientColors.map { $0.opacity(0.2) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: mood.primaryColor.opacity(0.1), radius: 15, x: 0, y: 8)
        .overlay(
            // Inner glow
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(mood.primaryColor.opacity(0.1), lineWidth: 0.5)
                .padding(1)
        )
}

// MARK: - Dramatic State (Full Mood Expression)

private func dramaticBackground(mood: Mood) -> some View {
    ZStack {
        // ULTRA-EXTREME flowing liquid gradient with maximum liquid movement
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            LinearGradient(
                colors: [
                    mood.primaryColor.opacity(0.9),
                    mood.gradientColors.first?.opacity(0.8) ?? mood.primaryColor.opacity(0.8),
                    mood.gradientColors.last?.opacity(0.7) ?? mood.primaryColor.opacity(0.7),
                    Color(.systemBackground).opacity(0.05),
                    mood.primaryColor.opacity(0.85)
                ],
                startPoint: .init(
                    x: -0.5 + sin(time * 1.2) * 1.0,
                    y: -0.5 + cos(time * 1.0) * 1.0
                ),
                endPoint: .init(
                    x: 1.5 + sin(time * 1.4) * 0.8,
                    y: 1.5 + cos(time * 1.1) * 0.8
                )
            )
        }
        
        // Multiple overlapping gradients for depth
        RadialGradient(
            colors: [
                mood.primaryColor.opacity(0.3),
                mood.gradientColors.first?.opacity(0.2) ?? mood.primaryColor.opacity(0.2),
                .clear,
                mood.primaryColor.opacity(0.15)
            ],
            center: .topLeading,
            startRadius: 50,
            endRadius: 300
        )
        
        RadialGradient(
            colors: [
                mood.gradientColors.last?.opacity(0.25) ?? mood.primaryColor.opacity(0.25),
                .clear,
                mood.primaryColor.opacity(0.2)
            ],
            center: .bottomTrailing,
            startRadius: 80,
            endRadius: 350
        )
        
        // Dramatic mood-specific patterns (full intensity)
        moodSpecificPattern(mood: mood, intensity: 1.5)
        
        // MASSIVE animated particle system with complex movement
        ForEach(0..<30, id: \.self) { index in
            let baseSize = CGFloat.random(in: 20...60)
            let baseOpacity = Double.random(in: 0.2...0.4)
            
            Circle()
                .fill(mood.primaryColor.opacity(baseOpacity))
                .frame(
                    width: baseSize + sin(Date().timeIntervalSinceReferenceDate * 2 + Double(index)) * 15,
                    height: baseSize + sin(Date().timeIntervalSinceReferenceDate * 2 + Double(index)) * 15
                )
                .offset(
                    x: CGFloat.random(in: -250...250) + sin(Date().timeIntervalSinceReferenceDate * 1.2 + Double(index)) * 80,
                    y: CGFloat.random(in: -500...500) + cos(Date().timeIntervalSinceReferenceDate * 0.9 + Double(index)) * 60
                )
                .blur(radius: 8 + sin(Date().timeIntervalSinceReferenceDate * 1.8 + Double(index)) * 5)
                .rotationEffect(.degrees(Date().timeIntervalSinceReferenceDate * 30 + Double(index) * 15))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(index) * 0.03), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Intense flowing energy streams
        ForEach(0..<5, id: \.self) { streamIndex in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            mood.primaryColor.opacity(0.4),
                            mood.gradientColors.first?.opacity(0.3) ?? mood.primaryColor.opacity(0.3),
                            mood.gradientColors.last?.opacity(0.25) ?? mood.primaryColor.opacity(0.25),
                            .clear
                        ],
                        startPoint: .init(
                            x: -1.5 + sin(Date().timeIntervalSinceReferenceDate * 1.2 + Double(streamIndex)), 
                            y: -1.0 + cos(Date().timeIntervalSinceReferenceDate * 0.8 + Double(streamIndex))
                        ),
                        endPoint: .init(
                            x: 1.5 + sin(Date().timeIntervalSinceReferenceDate * 1.2 + Double(streamIndex)), 
                            y: 1.0 + cos(Date().timeIntervalSinceReferenceDate * 0.8 + Double(streamIndex))
                        )
                    )
                )
                .rotationEffect(.degrees(Date().timeIntervalSinceReferenceDate * 20 + Double(streamIndex) * 10))
                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: Date().timeIntervalSinceReferenceDate)
        }
        
        // Multiple ambient light effects
        ForEach(0..<5, id: \.self) { index in
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            mood.primaryColor.opacity(0.2),
                            mood.gradientColors.first?.opacity(0.15) ?? mood.primaryColor.opacity(0.15),
                            mood.primaryColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 400)
                .offset(
                    x: CGFloat.random(in: -150...150),
                    y: CGFloat.random(in: -300...300)
                )
                .blur(radius: 25)
                .rotationEffect(.degrees(Double.random(in: 0...360)))
        }
        
        // Screen-wide mood wash
        Rectangle()
            .fill(mood.primaryColor.opacity(0.08))
            .blendMode(.overlay)
    }
}

private func dramaticCard(mood: Mood) -> some View {
    RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.thickMaterial)
        .overlay(
            // Outer border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            mood.primaryColor.opacity(0.4),
                            mood.gradientColors.first?.opacity(0.3) ?? mood.primaryColor.opacity(0.3),
                            mood.gradientColors.last?.opacity(0.2) ?? mood.primaryColor.opacity(0.2),
                            mood.primaryColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: mood.primaryColor.opacity(0.2), radius: 20, x: 0, y: 10)
        .overlay(
            // Inner highlight
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(2)
        )
        .overlay(
            // Mood-specific inner glow
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(mood.primaryColor.opacity(0.05))
                .padding(4)
        )
}

// MARK: - Mood-Specific Patterns

private func moodSpecificPattern(mood: Mood, intensity: Double) -> some View {
    Group {
        switch mood {
        case .happy, .excited:
            // Much more dramatic radiating rays
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(mood.primaryColor.opacity(0.15 * intensity))
                    .frame(width: 6, height: 250)
                    .offset(y: -125)
                    .rotationEffect(.degrees(Double(index) * 18))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: intensity)
            }
            
            // Additional sunburst effect
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(mood.gradientColors.first?.opacity(0.1 * intensity) ?? mood.primaryColor.opacity(0.1 * intensity))
                    .frame(width: 2, height: 400)
                    .offset(y: -200)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
        case .sad, .frustrated:
            // Realistic falling rain drops with continuous animation
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ForEach(0..<20, id: \.self) { index in
                    let delay = Double(index) * 0.2
                    let speed = Double.random(in: 1.0...2.5)
                    let xOffset = CGFloat(index * 25 - 250)
                    let fallProgress = ((time * speed + delay).truncatingRemainder(dividingBy: 3.0)) / 3.0
                    
                    Capsule()
                        .fill(mood.primaryColor.opacity(0.3 * intensity * (1.0 - fallProgress * 0.5)))
                        .frame(
                            width: CGFloat.random(in: 6...12),
                            height: CGFloat.random(in: 80...200)
                        )
                        .offset(
                            x: xOffset + sin(time * 0.3 + Double(index)) * 15, // Gentle sway
                            y: -400 + CGFloat(fallProgress * 800) // Continuous falling
                        )
                        .rotationEffect(.degrees(CGFloat.random(in: -8...8)))
                        .opacity(fallProgress < 0.9 ? 1.0 : (1.0 - (fallProgress - 0.9) * 10)) // Fade out at bottom
                }
            }
            
        case .anxious:
            // More turbulent waves
            ForEach(0..<10, id: \.self) { index in
                Wave(amplitude: 25, frequency: 0.02, phase: Double(index) * 0.5)
                    .stroke(mood.primaryColor.opacity(0.15 * intensity), lineWidth: 3)
                    .offset(y: CGFloat(index * 40 - 200))
            }
            
        case .peaceful:
            // Larger gentle ripples
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .stroke(mood.primaryColor.opacity(0.1 * intensity), lineWidth: 2)
                    .frame(width: CGFloat(80 + index * 60))
                    .offset(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -150...150)
                    )
                    .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate + Double(index)) * 0.1)
            }
            
        case .loving:
            // Many more heart particles
            ForEach(0..<12, id: \.self) { index in
                HeartShape()
                    .fill(mood.primaryColor.opacity(0.15 * intensity))
                    .frame(width: 30, height: 30)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
                    .scaleEffect(0.8 + sin(Date().timeIntervalSinceReferenceDate * 2 + Double(index)) * 0.3)
            }
            
        default:
            // Even neutral has some subtle pattern
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .stroke(Color.gray.opacity(0.05 * intensity), lineWidth: 1)
                    .frame(width: CGFloat(60 + index * 40))
                    .offset(
                        x: CGFloat.random(in: -80...80),
                        y: CGFloat.random(in: -120...120)
                    )
            }
        }
    }
}

private func moodParticle(mood: Mood, index: Int) -> some View {
    let size = CGFloat.random(in: 8...30)
    let opacity = Double.random(in: 0.05...0.15)
    
    return Circle()
        .fill(mood.primaryColor.opacity(opacity))
        .frame(width: size, height: size)
        .offset(
            x: CGFloat.random(in: -250...250),
            y: CGFloat.random(in: -500...500)
        )
        .blur(radius: CGFloat.random(in: 5...20))
}

// MARK: - UI Modifiers

struct AdaptiveMoodModifier: ViewModifier {
    let intensity: UIIntensity
    
    func body(content: Content) -> some View {
        content
            .background(
                AdaptiveUISystem.backgroundGradient(for: intensity)
                    .id(intensity.description) // Force complete recreation on mood change
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.9), value: intensity)
    }
}

struct AdaptiveCardModifier: ViewModifier {
    let intensity: UIIntensity
    
    func body(content: Content) -> some View {
        content
            .background(
                AdaptiveUISystem.cardStyle(for: intensity)
                    .id(intensity.description) // Force complete recreation on mood change
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.9), value: intensity)
    }
}

extension View {
    func adaptiveMoodBackground(_ intensity: UIIntensity) -> some View {
        modifier(AdaptiveMoodModifier(intensity: intensity))
    }
    
    func adaptiveMoodCard(_ intensity: UIIntensity) -> some View {
        modifier(AdaptiveCardModifier(intensity: intensity))
    }
}

