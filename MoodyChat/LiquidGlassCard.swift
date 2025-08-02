//
//  LiquidGlassCard.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    let mood: Mood
    let content: Content
    
    init(mood: Mood, @ViewBuilder content: () -> Content) {
        self.mood = mood
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: mood.gradientColors.map { $0.opacity(0.1) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: mood.gradientColors.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: mood.primaryColor.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct GlassmorphismBackground: View {
    let mood: Mood
    @State private var animationOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dynamic background based on mood
            backgroundLayer
            
            // Mood-specific animated elements
            moodSpecificElements
            
            // Floating particles
            particleLayer
        }
        .ignoresSafeArea()
        .onAppear {
            startMoodAnimation()
        }
        .onChange(of: mood) { oldValue, newValue in
            startMoodAnimation()
        }
    }
    
    private var backgroundLayer: some View {
        Group {
            switch mood {
            case .angry:
                angryBackground
            case .sad:
                sadBackground
            case .excited:
                excitedBackground
            case .anxious:
                anxiousBackground
            case .peaceful:
                peacefulBackground
            case .loving:
                lovingBackground
            default:
                defaultBackground
            }
        }
    }
    
    private var angryBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.red.opacity(0.3), .orange.opacity(0.2), .black.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ForEach(0..<8, id: \.self) { _ in
                Rectangle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 200, height: 4)
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .offset(x: animationOffset * 2, y: animationOffset)
            }
        }
    }
    
    private var sadBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.2), .indigo.opacity(0.3), .gray.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 8, height: CGFloat.random(in: 30...100))
                    .offset(
                        x: CGFloat(index * 30 - 150),
                        y: animationOffset + CGFloat(index * 20)
                    )
            }
        }
    }
    
    private var excitedBackground: some View {
        ZStack {
            RadialGradient(
                colors: [.orange.opacity(0.3), .yellow.opacity(0.2), .red.opacity(0.1)],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            
            ForEach(0..<16, id: \.self) { index in
                Rectangle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 4, height: 150)
                    .offset(y: -75)
                    .rotationEffect(.degrees(Double(index) * 22.5 + rotationAngle))
                    .scaleEffect(scaleEffect)
            }
        }
    }
    
    private var anxiousBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.2), .blue.opacity(0.15), .gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: CGFloat.random(in: 10...40))
                    .offset(
                        x: sin(animationOffset + Double(index)) * 100,
                        y: cos(animationOffset + Double(index)) * 150
                    )
            }
        }
    }
    
    private var peacefulBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.green.opacity(0.1), .mint.opacity(0.15), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ForEach(0..<5, id: \.self) { index in
                Wave(amplitude: 20, frequency: 0.02, phase: animationOffset + Double(index))
                    .stroke(Color.green.opacity(0.1), lineWidth: 2)
                    .offset(y: CGFloat(index * 50 - 100))
            }
        }
    }
    
    private var lovingBackground: some View {
        ZStack {
            RadialGradient(
                colors: [.pink.opacity(0.2), .red.opacity(0.1), .orange.opacity(0.05)],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            
            ForEach(0..<8, id: \.self) { index in
                HeartShape()
                    .fill(Color.pink.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .offset(
                        x: sin(animationOffset + Double(index)) * 80,
                        y: cos(animationOffset + Double(index) * 1.5) * 120
                    )
                    .scaleEffect(scaleEffect * 0.8)
            }
        }
    }
    
    private var defaultBackground: some View {
        LinearGradient(
            colors: mood.gradientColors.map { $0.opacity(0.05) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var moodSpecificElements: some View {
        Group {
            switch mood {
            case .angry:
                // Lightning bolts
                ForEach(0..<3, id: \.self) { index in
                    ZigzagShape()
                        .stroke(Color.red.opacity(0.3), lineWidth: 3)
                        .frame(height: 200)
                        .offset(x: CGFloat(index * 100 - 100))
                        .opacity(scaleEffect > 1.0 ? 1.0 : 0.0)
                }
                
            case .excited:
                // Starbursts
                ForEach(0..<5, id: \.self) { index in
                    StarburstShape()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .offset(
                            x: CGFloat.random(in: -150...150),
                            y: CGFloat.random(in: -200...200)
                        )
                        .rotationEffect(.degrees(rotationAngle * Double(index + 1)))
                        .scaleEffect(scaleEffect)
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    private var particleLayer: some View {
        ForEach(0..<getParticleCount(), id: \.self) { index in
            Circle()
                .fill(mood.primaryColor.opacity(getParticleOpacity()))
                .frame(width: getParticleSize(), height: getParticleSize())
                .offset(
                    x: getParticleOffset(index: index).x,
                    y: getParticleOffset(index: index).y
                )
                .animation(
                    .easeInOut(duration: getAnimationDuration())
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1),
                    value: animationOffset
                )
        }
    }
    
    private func startMoodAnimation() {
        withAnimation(.linear(duration: getAnimationDuration()).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: getAnimationDuration()).repeatForever(autoreverses: true)) {
            animationOffset = getAnimationRange()
            scaleEffect = getScaleRange()
        }
    }
    
    private func getParticleCount() -> Int {
        switch mood {
        case .excited: return 15
        case .angry: return 20
        case .anxious: return 25
        case .happy: return 12
        case .loving: return 10
        default: return 8
        }
    }
    
    private func getParticleOpacity() -> Double {
        switch mood {
        case .excited, .angry: return 0.3
        case .anxious: return 0.15
        case .peaceful: return 0.1
        default: return 0.2
        }
    }
    
    private func getParticleSize() -> CGFloat {
        switch mood {
        case .excited: return CGFloat.random(in: 8...20)
        case .angry: return CGFloat.random(in: 6...15)
        case .peaceful: return CGFloat.random(in: 4...12)
        default: return CGFloat.random(in: 5...15)
        }
    }
    
    private func getParticleOffset(index: Int) -> CGPoint {
        let baseX = CGFloat.random(in: -200...200)
        let baseY = CGFloat.random(in: -300...300)
        
        switch mood {
        case .angry:
            return CGPoint(
                x: baseX + sin(animationOffset + Double(index)) * 50,
                y: baseY + cos(animationOffset + Double(index)) * 30
            )
        case .anxious:
            return CGPoint(
                x: baseX + sin(animationOffset * 2 + Double(index)) * 80,
                y: baseY + cos(animationOffset * 1.5 + Double(index)) * 100
            )
        case .peaceful:
            return CGPoint(
                x: baseX + sin(animationOffset * 0.5 + Double(index)) * 30,
                y: baseY + cos(animationOffset * 0.3 + Double(index)) * 40
            )
        default:
            return CGPoint(
                x: baseX + sin(animationOffset + Double(index)) * 40,
                y: baseY + cos(animationOffset + Double(index)) * 60
            )
        }
    }
    
    private func getAnimationDuration() -> Double {
        switch mood {
        case .excited: return 1.0
        case .angry: return 0.8
        case .anxious: return 0.6
        case .peaceful: return 4.0
        case .loving: return 3.0
        default: return 2.0
        }
    }
    
    private func getAnimationRange() -> CGFloat {
        switch mood {
        case .excited: return 100
        case .angry: return 80
        case .anxious: return 60
        case .peaceful: return 30
        default: return 50
        }
    }
    
    private func getScaleRange() -> CGFloat {
        switch mood {
        case .excited: return 1.3
        case .angry: return 1.2
        case .loving: return 1.1
        default: return 1.05
        }
    }
}

// Custom shapes for different moods
struct Wave: Shape {
    let amplitude: Double
    let frequency: Double
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let y = midHeight + amplitude * sin(frequency * x + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct ZigzagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let segments = 8
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for i in 1...segments {
            let x = (width / CGFloat(segments)) * CGFloat(i)
            let y = i % 2 == 0 ? height : 0
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct StarburstShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let points = 8
        
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi) / Double(points)
            let currentRadius = i % 2 == 0 ? radius : radius * 0.5
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.25),
            control1: CGPoint(x: width * 0.5, y: height * 0.1),
            control2: CGPoint(x: width * 0.1, y: height * 0.1)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.75),
            control1: CGPoint(x: width * 0.1, y: height * 0.4),
            control2: CGPoint(x: width * 0.5, y: height * 0.6)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.25),
            control1: CGPoint(x: width * 0.5, y: height * 0.6),
            control2: CGPoint(x: width * 0.9, y: height * 0.4)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.25),
            control1: CGPoint(x: width * 0.9, y: height * 0.1),
            control2: CGPoint(x: width * 0.5, y: height * 0.1)
        )
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        LiquidGlassCard(mood: .happy) {
            VStack {
                Text("Happy Message")
                    .font(.headline)
                Text("This is a happy message with liquid glass styling!")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
        
        LiquidGlassCard(mood: .sad) {
            VStack {
                Text("Sad Message")
                    .font(.headline)
                Text("This is a sad message with different styling.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
    }
    .padding()
    .background(GlassmorphismBackground(mood: .happy))
}