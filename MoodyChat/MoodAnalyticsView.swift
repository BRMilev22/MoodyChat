//
//  MoodAnalyticsView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI
import Charts

struct MoodAnalyticsView: View {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var aiService = AIEnhancedSentimentService.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var moodPatternAnalysis: MoodPatternAnalysis?
    @State private var isLoadingAnalysis = false
    @State private var showInsights = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with time range selector
                    analyticsHeader
                    
                    // Mood trend chart
                    moodTrendChart
                    
                    // Mood distribution pie chart
                    moodDistributionChart
                    
                    // Emotional insights cards
                    if let analysis = moodPatternAnalysis {
                        emotionalInsightsSection(analysis: analysis)
                    }
                    
                    // AI-powered recommendations
                    aiRecommendationsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Mood Analytics")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onAppear {
                loadAnalytics()
            }
        }
    }
    
    private var analyticsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Emotional Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showInsights.toggle() }) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeRange) { oldValue, newValue in
                loadAnalytics()
            }
        }
        .padding(.top, 8)
    }
    
    private var moodTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Chart(getMoodTrendData()) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood Score", dataPoint.moodScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood Score", dataPoint.moodScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYScale(domain: -1...1)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var moodDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Distribution")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Pie chart
                Chart(getMoodDistributionData()) { dataPoint in
                    SectorMark(
                        angle: .value("Count", dataPoint.count),
                        innerRadius: .ratio(0.4),
                        angularInset: 2
                    )
                    .foregroundStyle(dataPoint.mood.primaryColor)
                    .opacity(0.8)
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getMoodDistributionData(), id: \.mood) { dataPoint in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(dataPoint.mood.primaryColor)
                                .frame(width: 12, height: 12)
                            
                            Text(dataPoint.mood.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(dataPoint.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func emotionalInsightsSection(analysis: MoodPatternAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightCard(
                    icon: "arrow.up.right",
                    title: "Trend",
                    value: analysis.overallTrend.capitalized,
                    color: getTrendColor(analysis.overallTrend)
                )
                
                InsightCard(
                    icon: "waveform.path",
                    title: "Volatility",
                    value: String(format: "%.1f", analysis.emotionalVolatility * 10),
                    color: .orange
                )
                
                InsightCard(
                    icon: "heart.fill",
                    title: "Top Mood",
                    value: analysis.mostFrequentMoods.first?.capitalized ?? "Mixed",
                    color: .pink
                )
                
                InsightCard(
                    icon: "shield.checkered",
                    title: "Resilience",
                    value: "\(analysis.resilenceIndicators.count) signs",
                    color: .green
                )
            }
            
            // Detailed insights
            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Insights")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(analysis.personalizedInsights)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("AI Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            if let analysis = moodPatternAnalysis {
                VStack(spacing: 12) {
                    ForEach(analysis.longTermRecommendations.prefix(3), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(.purple.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            
                            Text(recommendation)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            } else if isLoadingAnalysis {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing your patterns...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Data Methods
    
    private func loadAnalytics() {
        Task {
            isLoadingAnalysis = true
            defer { isLoadingAnalysis = false }
            
            do {
                let analysis = try await OllamaService.shared.analyzeMoodPatterns(
                    conversations: conversationManager.conversations
                )
                await MainActor.run {
                    self.moodPatternAnalysis = analysis
                }
            } catch {
                print("Failed to load mood pattern analysis: \(error)")
            }
        }
    }
    
    private func getMoodTrendData() -> [MoodTrendDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: selectedTimeRange.calendarComponent, value: -selectedTimeRange.value, to: now) ?? now
        
        var dataPoints: [MoodTrendDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= now {
            let dayConversations = conversationManager.conversations.filter {
                calendar.isDate($0.createdAt, inSameDayAs: currentDate)
            }
            
            let averageMoodScore = calculateAverageMoodScore(for: dayConversations)
            dataPoints.append(MoodTrendDataPoint(date: currentDate, moodScore: averageMoodScore))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    private func getMoodDistributionData() -> [MoodDistributionDataPoint] {
        let allMessages = conversationManager.conversations.flatMap { $0.messages }
        let moodCounts = Dictionary(grouping: allMessages.compactMap { $0.sentiment?.mood }) { $0 }
            .mapValues { $0.count }
        
        return moodCounts.map { mood, count in
            MoodDistributionDataPoint(mood: mood, count: count)
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateAverageMoodScore(for conversations: [Conversation]) -> Double {
        guard !conversations.isEmpty else { return 0 }
        
        let allMoods = conversations.flatMap { $0.messages.compactMap { $0.sentiment?.mood } }
        guard !allMoods.isEmpty else { return 0 }
        
        let totalScore = allMoods.reduce(0.0) { sum, mood in
            sum + moodToScore(mood)
        }
        
        return totalScore / Double(allMoods.count)
    }
    
    private func moodToScore(_ mood: Mood) -> Double {
        switch mood {
        case .excited: return 1.0
        case .happy: return 0.7
        case .loving: return 0.8
        case .peaceful: return 0.3
        case .neutral: return 0.0
        case .confused: return -0.2
        case .anxious: return -0.5
        case .frustrated: return -0.6
        case .sad: return -0.7
        case .angry: return -0.8
        }
    }
    
    private func getTrendColor(_ trend: String) -> Color {
        switch trend.lowercased() {
        case "improving": return .green
        case "declining": return .red
        case "stable": return .blue
        case "cyclical": return .orange
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Data Models

struct MoodTrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let moodScore: Double
}

struct MoodDistributionDataPoint: Identifiable {
    let id = UUID()
    let mood: Mood
    let count: Int
}

enum TimeRange: CaseIterable {
    case week
    case month
    case threeMonths
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .threeMonths: return .month
        case .year: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .week: return 1
        case .month: return 1
        case .threeMonths: return 3
        case .year: return 1
        }
    }
}

#Preview {
    MoodAnalyticsView()
}