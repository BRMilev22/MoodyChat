# MoodyChat 🎭
*Where emotions shape conversations*

## Overview
MoodyChat is a revolutionary iOS chat application that dynamically adapts its user interface based on the emotional sentiment of conversations. Using on-device CoreML sentiment analysis, the app creates an immersive experience where UI elements, colors, animations, and interactions respond fluidly to the emotional tone of messages.

Built with **Liquid Glass aesthetics** and Apple's latest iOS 26 design language, MoodyChat offers a unique conversational experience that feels both intimate and technologically advanced.

## Author
**Boris Milev**  
GitHub: [https://github.com/BRMilev22](https://github.com/BRMilev22)

## Tech Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: Combine + MVVM
- **ML**: CoreML (on-device sentiment analysis)
- **Animation**: SwiftUI animations, Lottie
- **Minimum iOS**: 16.0+

## Project Structure
```
MoodyChat/
├── MoodyChat.xcodeproj/     # Xcode project files
├── MoodyChat/               # Main application source code
│   ├── MoodyChatApp.swift   # App entry point
│   ├── ContentView.swift    # Welcome screen
│   ├── ChatView.swift       # Main chat interface
│   ├── Mood.swift           # Emotion data models
│   ├── Message.swift        # Chat message structures
│   ├── SentimentAnalysisService.swift  # CoreML sentiment engine
│   ├── ConversationManager.swift       # Chat state management
│   ├── LiquidGlassCard.swift          # Glassmorphism components
│   ├── MessageBubble.swift            # Mood-responsive chat bubbles
│   ├── MessageInputView.swift         # Smart input with mood prediction
│   └── Assets.xcassets/     # Images, animations, and resources
├── MoodyChatTests/          # Unit tests
├── MoodyChatUITests/        # UI tests
├── README.md
└── .gitignore
```

## Features

### 🎨 Emotional UI Adaptation
- **Dynamic Color Themes**: Interface colors shift based on conversation sentiment
- **Liquid Glass Effects**: Translucent, frosted glass aesthetics with depth
- **Micro-interactions**: Subtle animations responding to emotional context
- **Adaptive Typography**: Font weights and styles adjust to mood intensity

### 🧠 Sentiment Intelligence
- **On-Device Analysis**: Privacy-first CoreML sentiment processing
- **Real-time Processing**: Instant mood detection as you type
- **Contextual Awareness**: Understanding conversation flow and emotional nuance
- **Multi-language Support**: Sentiment analysis across different languages

### 💬 Chat Experience
- **Mood-Aware Bubbles**: Message bubbles reflect sender's emotional state
- **Intelligent Avatars**: Profile pictures adapt to current mood
- **Typing Indicators**: Even typing animations reflect emotional anticipation
- **Conversation Insights**: Subtle mood summaries and conversation analytics

### 🔒 Privacy & Security
- **100% On-Device**: No sentiment data leaves your device
- **Encrypted Messages**: End-to-end encryption for all communications
- **Anonymous Analytics**: Optional, aggregated usage insights
- **Data Control**: Complete control over your emotional data

## Screenshots
*Coming Soon - Interface previews showcasing mood adaptations*

![Happy Conversation](./Assets/Screenshots/happy-chat.png)
![Melancholic Theme](./Assets/Screenshots/sad-theme.png)
![Excited Interactions](./Assets/Screenshots/excited-ui.png)

## Setup Instructions

### Prerequisites
- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **macOS 13.0+** for development

### Installation
1. Clone or download the MoodyChat project
2. Open `MoodyChat.xcodeproj` in Xcode
3. Ensure your development team is selected in project settings
4. Build and run on simulator or physical device

### Development Setup
```bash
# Navigate to project directory
cd MoodyChat

# Install dependencies (if using CocoaPods)
pod install

# Open workspace
open MoodyChat.xcworkspace
```

## Development Phases

### Phase 1: Core Sentiment Foundation

**Sentiment Engine**
- [x] Create advanced semantic sentiment analysis (beyond simple keyword matching)
- [x] Implement Mood enum with emotional states (happy, sad, excited, angry, neutral, etc.)
- [x] Build contextual conversation understanding with natural language processing
- [x] Add intelligent confidence scoring based on emotional clarity
- [x] Create user learning system that adapts to individual communication patterns
- [x] Implement privacy-first on-device processing architecture

### Phase 2: Liquid Glass UI Foundation

**Visual Design System**
- [x] Implement SwiftUI Liquid Glass visual effects with blur and transparency
- [x] Create dynamic color palette system that responds to mood states
- [x] Build foundational animation framework with micro-interactions
- [x] Add glassmorphism components (cards, buttons, backgrounds)
- [x] Implement smooth gradient transitions between emotional states
- [x] Create responsive typography system that adapts to mood intensity

### Phase 3: Adaptive Chat Experience

**Interactive Messaging**
- [x] Build SwiftUI message list with LazyVStack optimization
- [x] Create mood-responsive chat bubbles with dynamic styling
- [x] Implement real-time typing indicators with emotional context (mood prediction preview)
- [x] Add animated message sending with sentiment-based effects
- [x] Create intelligent message grouping and conversation flow
- [x] Build conversation mood summary visualization (MoodIndicator component)

### Phase 4: Advanced Mood Intelligence

**Smart Features**
- [ ] Implement AI-powered conversation insights and mood patterns
- [ ] Add mood-based response suggestions and emotional coaching
- [ ] Create conversation mood analytics with beautiful charts
- [ ] Build intelligent notification system based on emotional context
- [ ] Add mood journaling with SwiftUI diary interface
- [ ] Implement contextual emotional intelligence recommendations

### Phase 5: Premium Experience

**Enhanced Capabilities**
- [ ] Add voice sentiment analysis with Speech framework integration
- [ ] Implement camera-based emotion detection using Vision framework
- [ ] Create Apple Watch companion app with mood quick-logging
- [ ] Add Siri Shortcuts for mood check-ins and insights
- [ ] Build HealthKit integration for wellness correlation
- [ ] Implement advanced privacy controls and data export features

## Future Enhancements

### 🚀 Stretch Goals
- **Voice Sentiment**: Real-time voice emotion analysis
- **Gesture Recognition**: Hand gesture mood input
- **Biometric Integration**: Heart rate and stress level correlation
- **AR Mood Bubbles**: Augmented reality emotion visualization
- **Apple Watch Companion**: Wrist-based mood monitoring
- **Siri Integration**: Voice-controlled emotional check-ins

### 🎯 Advanced Features
- **Group Chat Dynamics**: Multi-person sentiment analysis
- **Mood History**: Personal emotional journey tracking
- **Wellness Integration**: HealthKit mood correlation
- **Custom Themes**: User-created emotional color palettes
- **AI Mood Coach**: Personalized emotional intelligence insights

## Contributing
This is a personal project, but feedback and suggestions are welcome! Feel free to reach out through GitHub issues or discussions.

## License
© 2024 Boris Milev. All rights reserved.

---

*MoodyChat: Where technology meets emotion, creating conversations that truly understand you.*