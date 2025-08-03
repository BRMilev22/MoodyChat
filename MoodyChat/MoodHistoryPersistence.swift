//
//  MoodHistoryPersistence.swift
//  MoodyChat
//
//  Created by Boris Milev on 3.08.25.
//

import Foundation
import SwiftUI

// MARK: - Mood History Persistence Manager

class MoodHistoryPersistence: ObservableObject {
    static let shared = MoodHistoryPersistence()
    
    @Published var moodHistoryEntries: [MoodHistoryEntry] = []
    @Published var dailyMoodSummaries: [DailyMoodSummary] = []
    @Published var weeklyInsights: [WeeklyMoodInsight] = []
    @Published var moodStreaks: [MoodStreak] = []
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let moodHistoryFile: URL
    private let dailySummariesFile: URL
    private let weeklyInsightsFile: URL
    private let streaksFile: URL
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        moodHistoryFile = documentsDirectory.appendingPathComponent("moodHistory.json")
        dailySummariesFile = documentsDirectory.appendingPathComponent("dailySummaries.json")
        weeklyInsightsFile = documentsDirectory.appendingPathComponent("weeklyInsights.json")
        streaksFile = documentsDirectory.appendingPathComponent("moodStreaks.json")
        
        loadAllData()
        
        // Set up automatic daily summaries
        scheduleDailySummaryGeneration()
    }
    
    // MARK: - Core Persistence Functions
    
    func recordMoodEntry(mood: Mood, confidence: Double, context: String, triggers: [String] = []) {
        let entry = MoodHistoryEntry(
            id: UUID(),
            mood: mood,
            confidence: confidence,
            timestamp: Date(),
            context: context,
            triggers: triggers,
            conversationId: UUID() // This should be passed from the conversation
        )
        
        moodHistoryEntries.append(entry)
        saveMoodHistory()
        
        // Update daily summary for today
        updateDailySummary(with: entry)
        
        // Check and update mood streaks
        updateMoodStreaks(with: entry)
        
        // Generate insights if enough data
        if shouldGenerateWeeklyInsight() {
            generateWeeklyInsight()
        }
    }
    
    func getMoodHistory(for timeRange: MoodTimeRange) -> [MoodHistoryEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return moodHistoryEntries.filter { entry in
            switch timeRange {
            case .today:
                return calendar.isDateInToday(entry.timestamp)
            case .week:
                return calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .month)
            case .threeMonths:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                return entry.timestamp >= threeMonthsAgo
            case .year:
                return calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getMoodStatistics(for timeRange: MoodTimeRange) -> MoodStatistics {
        let entries = getMoodHistory(for: timeRange)
        guard !entries.isEmpty else {
            return MoodStatistics(
                totalEntries: 0,
                moodDistribution: [:],
                averageConfidence: 0.0,
                mostFrequentMood: .neutral,
                moodVariability: 0.0,
                positiveRatio: 0.0,
                trendDirection: .stable,
                commonTriggers: []
            )
        }
        
        // Calculate mood distribution
        let moodCounts = Dictionary(grouping: entries) { $0.mood }
            .mapValues { $0.count }
        let totalEntries = entries.count
        let moodDistribution = moodCounts.mapValues { Double($0) / Double(totalEntries) }
        
        // Calculate average confidence
        let averageConfidence = entries.map { $0.confidence }.reduce(0, +) / Double(totalEntries)
        
        // Find most frequent mood
        let mostFrequentMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
        
        // Calculate mood variability (how much moods change)
        let moodVariability = calculateMoodVariability(entries: entries)
        
        // Calculate positive emotion ratio
        let positiveMoods: Set<Mood> = [.happy, .excited, .loving, .peaceful]
        let positiveCount = entries.filter { positiveMoods.contains($0.mood) }.count
        let positiveRatio = Double(positiveCount) / Double(totalEntries)
        
        // Determine trend direction
        let trendDirection = calculateMoodTrend(entries: entries)
        
        // Find common triggers
        let allTriggers = entries.flatMap { $0.triggers }
        let triggerCounts = Dictionary(grouping: allTriggers) { $0 }
            .mapValues { $0.count }
            .filter { $0.value > 1 }
        let commonTriggers = Array(triggerCounts.keys.prefix(5))
        
        return MoodStatistics(
            totalEntries: totalEntries,
            moodDistribution: moodDistribution,
            averageConfidence: averageConfidence,
            mostFrequentMood: mostFrequentMood,
            moodVariability: moodVariability,
            positiveRatio: positiveRatio,
            trendDirection: trendDirection,
            commonTriggers: commonTriggers
        )
    }
    
    func getDailyMoodSummary(for date: Date) -> DailyMoodSummary? {
        let calendar = Calendar.current
        return dailyMoodSummaries.first { summary in
            calendar.isDate(summary.date, inSameDayAs: date)
        }
    }
    
    func getWeeklyInsights(for weekCount: Int = 4) -> [WeeklyMoodInsight] {
        return Array(weeklyInsights.suffix(weekCount))
    }
    
    func getCurrentMoodStreak() -> MoodStreak? {
        return moodStreaks.first { $0.isActive }
    }
    
    func getLongestMoodStreak() -> MoodStreak? {
        return moodStreaks.max(by: { $0.currentLength < $1.currentLength })
    }
    
    // MARK: - Daily Summary Generation
    
    private func updateDailySummary(with entry: MoodHistoryEntry) {
        let calendar = Calendar.current
        let today = Date()
        
        // Find or create today's summary
        if let existingSummaryIndex = dailyMoodSummaries.firstIndex(where: { 
            calendar.isDate($0.date, inSameDayAs: today) 
        }) {
            // Update existing summary
            var summary = dailyMoodSummaries[existingSummaryIndex]
            summary.addEntry(entry)
            dailyMoodSummaries[existingSummaryIndex] = summary
        } else {
            // Create new summary
            let summary = DailyMoodSummary(date: today, entries: [entry])
            dailyMoodSummaries.append(summary)
        }
        
        saveDailySummaries()
    }
    
    private func scheduleDailySummaryGeneration() {
        // In a real app, this would use a background task or notification
        // For now, we'll generate summaries when the app is active
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.generateDailySummaryIfNeeded()
        }
    }
    
    private func generateDailySummaryIfNeeded() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        // Check if we have a summary for yesterday
        let hasYesterdaySummary = dailyMoodSummaries.contains { summary in
            calendar.isDate(summary.date, inSameDayAs: yesterday)
        }
        
        if !hasYesterdaySummary {
            let yesterdayEntries = moodHistoryEntries.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: yesterday)
            }
            
            if !yesterdayEntries.isEmpty {
                let summary = DailyMoodSummary(date: yesterday, entries: yesterdayEntries)
                dailyMoodSummaries.append(summary)
                saveDailySummaries()
            }
        }
    }
    
    // MARK: - Weekly Insights Generation
    
    private func shouldGenerateWeeklyInsight() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's been a week since last insight
        if let lastInsight = weeklyInsights.last {
            let daysSinceLastInsight = calendar.dateComponents([.day], from: lastInsight.weekStartDate, to: now).day ?? 0
            return daysSinceLastInsight >= 7
        }
        
        // Generate first insight if we have at least 7 days of data
        let oldestEntry = moodHistoryEntries.min(by: { $0.timestamp < $1.timestamp })
        if let oldest = oldestEntry {
            let daysSinceFirst = calendar.dateComponents([.day], from: oldest.timestamp, to: now).day ?? 0
            return daysSinceFirst >= 7
        }
        
        return false
    }
    
    private func generateWeeklyInsight() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let weekEntries = moodHistoryEntries.filter { entry in
            calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .weekOfYear)
        }
        
        guard !weekEntries.isEmpty else { return }
        
        // Calculate weekly statistics
        let moodCounts = Dictionary(grouping: weekEntries) { $0.mood }
            .mapValues { $0.count }
        let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
        
        let averageConfidence = weekEntries.map { $0.confidence }.reduce(0, +) / Double(weekEntries.count)
        
        // Identify mood patterns
        let patterns = identifyWeeklyMoodPatterns(entries: weekEntries)
        
        // Generate insights text
        let insights = generateWeeklyInsightsText(
            dominantMood: dominantMood,
            entries: weekEntries,
            patterns: patterns
        )
        
        // Compare with previous week
        let previousWeekComparison = compareWithPreviousWeek(currentWeekEntries: weekEntries)
        
        let weeklyInsight = WeeklyMoodInsight(
            weekStartDate: weekStart,
            dominantMood: dominantMood,
            moodDistribution: moodCounts.mapValues { Double($0) / Double(weekEntries.count) },
            averageConfidence: averageConfidence,
            totalEntries: weekEntries.count,
            patterns: patterns,
            insights: insights,
            previousWeekComparison: previousWeekComparison
        )
        
        weeklyInsights.append(weeklyInsight)
        
        // Keep only last 12 weeks
        if weeklyInsights.count > 12 {
            weeklyInsights.removeFirst()
        }
        
        saveWeeklyInsights()
    }
    
    // MARK: - Mood Streaks Management
    
    private func updateMoodStreaks(with entry: MoodHistoryEntry) {
        let calendar = Calendar.current
        let today = Date()
        
        // Check for positive mood streak
        let positiveMoods: Set<Mood> = [.happy, .excited, .loving, .peaceful]
        if positiveMoods.contains(entry.mood) {
            updateStreak(for: .positive, on: today)
        } else {
            endStreak(for: .positive)
        }
        
        // Check for consistent mood streak (same mood multiple days)
        let yesterdayEntries = moodHistoryEntries.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        }
        
        if let dominantYesterday = getDominantMood(from: yesterdayEntries),
           dominantYesterday == entry.mood {
            updateStreak(for: .consistent(entry.mood), on: today)
        } else {
            endStreak(for: .consistent(entry.mood))
        }
        
        saveMoodStreaks()
    }
    
    private func updateStreak(for type: MoodStreakType, on date: Date) {
        if let existingStreakIndex = moodStreaks.firstIndex(where: { $0.type == type && $0.isActive }) {
            moodStreaks[existingStreakIndex].extendStreak(to: date)
        } else {
            let newStreak = MoodStreak(type: type, startDate: date)
            moodStreaks.append(newStreak)
        }
    }
    
    private func endStreak(for type: MoodStreakType) {
        if let streakIndex = moodStreaks.firstIndex(where: { $0.type == type && $0.isActive }) {
            moodStreaks[streakIndex].endStreak()
        }
    }
    
    // MARK: - Analysis Helper Methods
    
    private func calculateMoodVariability(entries: [MoodHistoryEntry]) -> Double {
        guard entries.count > 1 else { return 0.0 }
        
        // Convert moods to numerical values for variability calculation
        let moodValues = entries.map { moodToNumericalValue($0.mood) }
        let mean = moodValues.reduce(0, +) / Double(moodValues.count)
        let squaredDifferences = moodValues.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(moodValues.count)
        
        return sqrt(variance)
    }
    
    private func moodToNumericalValue(_ mood: Mood) -> Double {
        switch mood {
        case .excited: return 2.0
        case .happy: return 1.5
        case .loving: return 1.7
        case .peaceful: return 1.0
        case .neutral: return 0.0
        case .confused: return -0.3
        case .anxious: return -1.0
        case .frustrated: return -1.2
        case .sad: return -1.5
        case .angry: return -2.0
        }
    }
    
    private func calculateMoodTrend(entries: [MoodHistoryEntry]) -> MoodTrend {
        guard entries.count >= 3 else { return .stable }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        let moodValues = sortedEntries.map { moodToNumericalValue($0.mood) }
        
        // Simple linear trend calculation
        let n = Double(moodValues.count)
        let sumX = (0..<moodValues.count).reduce(0) { $0 + $1 }
        let sumY = moodValues.reduce(0, +)
        let sumXY = zip(0..<moodValues.count, moodValues).reduce(0) { $0 + Double($1.0) * $1.1 }
        let sumX2 = (0..<moodValues.count).reduce(0) { $0 + $1 * $1 }
        
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * Double(sumX2) - Double(sumX * sumX))
        
        if slope > 0.1 {
            return .improving
        } else if slope < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func identifyWeeklyMoodPatterns(entries: [MoodHistoryEntry]) -> [String] {
        var patterns: [String] = []
        
        // Group by day of week
        let calendar = Calendar.current
        let dayGroups = Dictionary(grouping: entries) { entry in
            calendar.component(.weekday, from: entry.timestamp)
        }
        
        // Check for day-of-week patterns
        let moodsByDay = dayGroups.mapValues { dayEntries in
            getDominantMood(from: dayEntries) ?? .neutral
        }
        
        // Identify patterns
        let weekendMoods = [moodsByDay[1], moodsByDay[7]].compactMap { $0 } // Sunday, Saturday
        let weekdayMoods = [moodsByDay[2], moodsByDay[3], moodsByDay[4], moodsByDay[5], moodsByDay[6]].compactMap { $0 }
        
        if !weekendMoods.isEmpty && !weekdayMoods.isEmpty {
            let weekendPositive = weekendMoods.allSatisfy { [.happy, .excited, .loving, .peaceful].contains($0) }
            let weekdayStressful = weekdayMoods.contains { [.anxious, .frustrated, .sad].contains($0) }
            
            if weekendPositive && weekdayStressful {
                patterns.append("Weekend mood boost pattern")
            }
        }
        
        // Check for time-of-day patterns (simplified)
        let morningEntries = entries.filter { calendar.component(.hour, from: $0.timestamp) < 12 }
        let eveningEntries = entries.filter { calendar.component(.hour, from: $0.timestamp) >= 18 }
        
        if !morningEntries.isEmpty && !eveningEntries.isEmpty {
            let morningMood = getDominantMood(from: morningEntries)
            let eveningMood = getDominantMood(from: eveningEntries)
            
            if let morning = morningMood, let evening = eveningMood {
                if moodToNumericalValue(morning) > moodToNumericalValue(evening) {
                    patterns.append("Morning energy, evening calm pattern")
                } else if moodToNumericalValue(evening) > moodToNumericalValue(morning) {
                    patterns.append("Building energy throughout the day")
                }
            }
        }
        
        return patterns
    }
    
    private func getDominantMood(from entries: [MoodHistoryEntry]) -> Mood? {
        guard !entries.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: entries) { $0.mood }
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func generateWeeklyInsightsText(dominantMood: Mood, entries: [MoodHistoryEntry], patterns: [String]) -> String {
        var insights: [String] = []
        
        insights.append("This week, your emotional landscape was predominantly \(dominantMood.displayName.lowercased()).")
        
        if entries.count >= 5 {
            insights.append("You showed great consistency in emotional awareness with \(entries.count) mood entries.")
        } else {
            insights.append("Consider tracking your moods more frequently for deeper insights.")
        }
        
        if !patterns.isEmpty {
            insights.append("Notable patterns: \(patterns.joined(separator: ", ")).")
        }
        
        // Add mood-specific insights
        switch dominantMood {
        case .happy, .excited:
            insights.append("Your positive energy this week is wonderful to see!")
        case .anxious, .frustrated:
            insights.append("You've been navigating some challenging emotions - remember to be gentle with yourself.")
        case .peaceful:
            insights.append("Your emotional balance this week shows great inner stability.")
        default:
            insights.append("Your emotional journey this week shows your human complexity.")
        }
        
        return insights.joined(separator: " ")
    }
    
    private func compareWithPreviousWeek(currentWeekEntries: [MoodHistoryEntry]) -> String {
        let calendar = Calendar.current
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        
        let previousWeekEntries = moodHistoryEntries.filter { entry in
            calendar.isDate(entry.timestamp, equalTo: previousWeekStart, toGranularity: .weekOfYear)
        }
        
        guard !previousWeekEntries.isEmpty else {
            return "This is your first week of mood tracking!"
        }
        
        let currentAverage = currentWeekEntries.map { moodToNumericalValue($0.mood) }.reduce(0, +) / Double(currentWeekEntries.count)
        let previousAverage = previousWeekEntries.map { moodToNumericalValue($0.mood) }.reduce(0, +) / Double(previousWeekEntries.count)
        
        let difference = currentAverage - previousAverage
        
        if difference > 0.3 {
            return "Significant improvement from last week! 📈"
        } else if difference < -0.3 {
            return "This week was more challenging than last week. 💙"
        } else {
            return "Consistent emotional patterns compared to last week."
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveMoodHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(moodHistoryEntries)
            try data.write(to: moodHistoryFile)
        } catch {
            print("Failed to save mood history: \(error)")
        }
    }
    
    private func saveDailySummaries() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(dailyMoodSummaries)
            try data.write(to: dailySummariesFile)
        } catch {
            print("Failed to save daily summaries: \(error)")
        }
    }
    
    private func saveWeeklyInsights() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(weeklyInsights)
            try data.write(to: weeklyInsightsFile)
        } catch {
            print("Failed to save weekly insights: \(error)")
        }
    }
    
    private func saveMoodStreaks() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(moodStreaks)
            try data.write(to: streaksFile)
        } catch {
            print("Failed to save mood streaks: \(error)")
        }
    }
    
    private func loadAllData() {
        loadMoodHistory()
        loadDailySummaries()
        loadWeeklyInsights()
        loadMoodStreaks()
    }
    
    private func loadMoodHistory() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard fileManager.fileExists(atPath: moodHistoryFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: moodHistoryFile)
            moodHistoryEntries = try decoder.decode([MoodHistoryEntry].self, from: data)
        } catch {
            print("Failed to load mood history: \(error)")
        }
    }
    
    private func loadDailySummaries() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard fileManager.fileExists(atPath: dailySummariesFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: dailySummariesFile)
            dailyMoodSummaries = try decoder.decode([DailyMoodSummary].self, from: data)
        } catch {
            print("Failed to load daily summaries: \(error)")
        }
    }
    
    private func loadWeeklyInsights() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard fileManager.fileExists(atPath: weeklyInsightsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: weeklyInsightsFile)
            weeklyInsights = try decoder.decode([WeeklyMoodInsight].self, from: data)
        } catch {
            print("Failed to load weekly insights: \(error)")
        }
    }
    
    private func loadMoodStreaks() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard fileManager.fileExists(atPath: streaksFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: streaksFile)
            moodStreaks = try decoder.decode([MoodStreak].self, from: data)
        } catch {
            print("Failed to load mood streaks: \(error)")
        }
    }
}

// MARK: - Data Models

struct MoodHistoryEntry: Identifiable, Codable {
    let id: UUID
    let mood: Mood
    let confidence: Double
    let timestamp: Date
    let context: String
    let triggers: [String]
    let conversationId: UUID
}

enum MoodTimeRange: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case threeMonths = "3 Months"
    case year = "This Year"
    case all = "All Time"
    
    var displayName: String { rawValue }
}

struct MoodStatistics {
    let totalEntries: Int
    let moodDistribution: [Mood: Double]
    let averageConfidence: Double
    let mostFrequentMood: Mood
    let moodVariability: Double
    let positiveRatio: Double
    let trendDirection: MoodTrend
    let commonTriggers: [String]
}

enum MoodTrend {
    case improving
    case stable
    case declining
    
    var description: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Needs Attention"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

struct DailyMoodSummary: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var entries: [MoodHistoryEntry]
    
    var dominantMood: Mood {
        guard !entries.isEmpty else { return .neutral }
        
        let moodCounts = Dictionary(grouping: entries) { $0.mood }
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
    
    var averageConfidence: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.map { $0.confidence }.reduce(0, +) / Double(entries.count)
    }
    
    var moodCount: Int {
        return entries.count
    }
    
    mutating func addEntry(_ entry: MoodHistoryEntry) {
        entries.append(entry)
    }
}

struct WeeklyMoodInsight: Identifiable, Codable {
    let id = UUID()
    let weekStartDate: Date
    let dominantMood: Mood
    let moodDistribution: [Mood: Double]
    let averageConfidence: Double
    let totalEntries: Int
    let patterns: [String]
    let insights: String
    let previousWeekComparison: String
}

enum MoodStreakType: Codable, Equatable {
    case positive
    case consistent(Mood)
    
    var description: String {
        switch self {
        case .positive:
            return "Positive Mood Streak"
        case .consistent(let mood):
            return "\(mood.displayName) Consistency Streak"
        }
    }
}

struct MoodStreak: Identifiable, Codable {
    let id = UUID()
    let type: MoodStreakType
    let startDate: Date
    var endDate: Date?
    var currentLength: Int
    var isActive: Bool
    
    init(type: MoodStreakType, startDate: Date) {
        self.type = type
        self.startDate = startDate
        self.endDate = nil
        self.currentLength = 1
        self.isActive = true
    }
    
    mutating func extendStreak(to date: Date) {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
        currentLength = daysDifference + 1
    }
    
    mutating func endStreak() {
        isActive = false
        endDate = Date()
    }
}