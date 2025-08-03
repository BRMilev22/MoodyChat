//
//  MoodJournalView.swift
//  MoodyChat
//
//  Created by Boris Milev on 1.08.25.
//

import SwiftUI

struct MoodJournalView: View {
    @StateObject private var journalManager = MoodJournalManager()
    @StateObject private var aiService = AIEnhancedSentimentService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var selectedTimeFilter: TimeFilter = .week
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with time filter
                journalHeader
                
                // Content
                if journalManager.entries.isEmpty {
                    emptyJournalState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Weekly mood summary
                            weeklyMoodSummary
                            
                            // Journal entries
                            ForEach(filteredEntries, id: \.id) { entry in
                                JournalEntryCard(
                                    entry: entry,
                                    onTap: { selectedEntry = entry }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Mood Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                NewJournalEntryView(journalManager: journalManager)
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry, journalManager: journalManager)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
    
    private var journalHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Emotional Journey")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Mood streak indicator
                if journalManager.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("\(journalManager.currentStreak) day streak")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.orange.opacity(0.1))
                    )
                }
            }
            
            // Time filter picker
            Picker("Time Filter", selection: $selectedTimeFilter) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .horizontal)
        )
    }
    
    private var weeklyMoodSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Emotional Landscape")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Mood distribution this week
            HStack(spacing: 12) {
                ForEach(Mood.allCases.prefix(5), id: \.self) { mood in
                    let count = weeklyMoodCount(for: mood)
                    
                    VStack(spacing: 6) {
                        Text(mood.emoji)
                            .font(.title2)
                        
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(count > 0 ? mood.primaryColor : .secondary)
                        
                        Text(mood.displayName)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        weeklyMoodBackground(count: count, mood: mood)
                    )
                }
            }
            
            // AI insights for the week
            if let weeklyInsights = journalManager.weeklyInsights {
                Text(weeklyInsights)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .italic()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var emptyJournalState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Start Your Emotional Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Capture your daily emotions and unlock AI-powered insights about your emotional patterns and growth.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showNewEntry = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Entry")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.blue)
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var filteredEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return journalManager.entries.filter { entry in
            switch selectedTimeFilter {
            case .week:
                return calendar.isDate(entry.createdAt, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(entry.createdAt, equalTo: now, toGranularity: .month)
            case .threeMonths:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                return entry.createdAt >= threeMonthsAgo
            case .all:
                return true
            }
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func weeklyMoodCount(for mood: Mood) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        return journalManager.entries.filter { entry in
            calendar.isDate(entry.createdAt, equalTo: now, toGranularity: .weekOfYear) && entry.mood == mood
        }.count
    }
    
    private func weeklyMoodBackground(count: Int, mood: Mood) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(count > 0 ? mood.primaryColor.opacity(0.1) : Color(.systemGray5).opacity(0.3))
    }
}

// MARK: - Supporting Views

struct JournalEntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Mood indicator
                VStack(spacing: 6) {
                    Text(entry.mood.emoji)
                        .font(.title2)
                    
                    Text(entry.mood.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(entry.mood.primaryColor)
                }
                .frame(width: 60)
                
                // Entry content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatDate(entry.createdAt))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let intensity = entry.emotionalIntensity {
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { index in
                                    Circle()
                                        .fill(index < Int(intensity * 5) ? entry.mood.primaryColor : Color(.systemGray4))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let tags = entry.tags, !tags.isEmpty {
                        HStack {
                            ForEach(tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(entry.mood.primaryColor.opacity(0.1))
                                    )
                                    .foregroundColor(entry.mood.primaryColor)
                            }
                            
                            if tags.count > 3 {
                                Text("+\(tags.count - 3)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(16)
            .background(journalEntryCardBackground)
        }
        .buttonStyle(.plain)
    }
    
    private var journalEntryCardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(entry.mood.primaryColor.opacity(0.2), lineWidth: 1)
            )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct NewJournalEntryView: View {
    @ObservedObject var journalManager: MoodJournalManager
    @StateObject private var aiService = AIEnhancedSentimentService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMood: Mood = .neutral
    @State private var content = ""
    @State private var emotionalIntensity: Double = 0.5
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showTagInput = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button(action: { selectedMood = mood }) {
                                    VStack(spacing: 8) {
                                        Text(mood.emoji)
                                            .font(.title2)
                                        
                                        Text(mood.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        moodSelectionBackground(mood: mood, isSelected: mood == selectedMood)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Emotional intensity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Emotional Intensity")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            Slider(value: $emotionalIntensity, in: 0...1)
                                .accentColor(selectedMood.primaryColor)
                            
                            HStack {
                                Text("Subtle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Intense")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's on your mind?")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemGray5).opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedMood.primaryColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Tags")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: { showTagInput.toggle() }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagChip(
                                        text: tag,
                                        color: selectedMood.primaryColor,
                                        onRemove: { tags.removeAll { $0 == tag } }
                                    )
                                }
                            }
                        }
                        
                        if showTagInput {
                            HStack {
                                TextField("Add a tag...", text: $newTag)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button("Add", action: addTag)
                                    .disabled(newTag.isEmpty)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.medium)
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
    
    private func saveEntry() {
        let entry = JournalEntry(
            mood: selectedMood,
            content: content,
            emotionalIntensity: emotionalIntensity,
            tags: tags.isEmpty ? nil : tags
        )
        
        journalManager.addEntry(entry)
        
        // Generate AI insights for the entry
        Task {
            await journalManager.generateWeeklyInsights()
        }
        
        dismiss()
    }
    
    private func moodSelectionBackground(mood: Mood, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? mood.primaryColor.opacity(0.2) : Color(.systemGray5).opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? mood.primaryColor : .clear, lineWidth: 2)
            )
    }
}

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var journalManager: MoodJournalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Mood and intensity header
                    HStack {
                        VStack(spacing: 8) {
                            Text(entry.mood.emoji)
                                .font(.system(size: 48))
                            
                            Text(entry.mood.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(entry.mood.primaryColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Intensity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let intensity = entry.emotionalIntensity {
                                HStack(spacing: 4) {
                                    ForEach(0..<5, id: \.self) { index in
                                        Circle()
                                            .fill(index < Int(intensity * 5) ? entry.mood.primaryColor : Color(.systemGray4))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Date
                    Text(formatFullDate(entry.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    // Content
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    // Tags
                    if let tags = entry.tags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(tagBackground)
                                        .foregroundColor(entry.mood.primaryColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // AI Insights (if available)
                    if let insights = entry.aiInsights {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Insights")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(insights)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(20)
                        .background(aiInsightsBackground)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditMode = true
                    }
                }
            }
        }
    }
    
    private var tagBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(entry.mood.primaryColor.opacity(0.1))
    }
    
    private var aiInsightsBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(entry.mood.primaryColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views and Types

struct TagChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
        )
        .foregroundColor(color)
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, spacing: spacing, containerWidth: proposal.width ?? .infinity).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, spacing: spacing, containerWidth: bounds.width).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], spacing: CGFloat, containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for size in sizes {
            if currentRowX + size.width > containerWidth && currentRowX > 0 {
                // Move to next row
                currentRowY += currentRowHeight + spacing
                currentRowX = 0
                currentRowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentRowX, y: currentRowY))
            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
            totalWidth = max(totalWidth, currentRowX - spacing)
        }
        
        let totalHeight = currentRowY + currentRowHeight
        return (offsets, CGSize(width: totalWidth, height: totalHeight))
    }
}

enum TimeFilter: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case all = "All"
    
    var displayName: String { rawValue }
}

// MARK: - Data Models

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let mood: Mood
    let content: String
    let createdAt: Date
    let emotionalIntensity: Double?
    let tags: [String]?
    var aiInsights: String?
    
    init(mood: Mood, content: String, emotionalIntensity: Double? = nil, tags: [String]? = nil) {
        self.id = UUID()
        self.mood = mood
        self.content = content
        self.createdAt = Date()
        self.emotionalIntensity = emotionalIntensity
        self.tags = tags
    }
}

class MoodJournalManager: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var weeklyInsights: String?
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        for i in 0..<30 { // Check up to 30 days
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let hasEntry = entries.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
            
            if hasEntry {
                streak += 1
            } else if i > 0 { // Don't break streak on today if no entry yet
                break
            }
        }
        
        return streak
    }
    
    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        saveEntries()
    }
    
    func generateWeeklyInsights() async {
        let recentEntries = entries.filter { entry in
            Calendar.current.isDate(entry.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
        
        guard !recentEntries.isEmpty else { return }
        
        // Generate AI insights based on weekly patterns
        let moodCounts = Dictionary(grouping: recentEntries) { $0.mood }
            .mapValues { $0.count }
        
        let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .neutral
        let averageIntensity = recentEntries.compactMap { $0.emotionalIntensity }.reduce(0, +) / Double(recentEntries.count)
        
        let insights = "This week you've been predominantly \(dominantMood.displayName.lowercased()) with an average intensity of \(String(format: "%.1f", averageIntensity * 10))/10. You've made \(recentEntries.count) entries, showing great consistency in emotional awareness."
        
        await MainActor.run {
            self.weeklyInsights = insights
        }
    }
    
    private func saveEntries() {
        // TODO: Implement persistence
    }
}

#Preview {
    MoodJournalView()
}