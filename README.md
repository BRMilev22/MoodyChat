# MoodyChat 🎭
*Where emotions shape conversations*

<p align="center">
  <img src="./MoodyChat/Assets.xcassets/AppIcon.appiconset/logo.png" width="120" alt="MoodyChat Light Logo">
  <img src="./MoodyChat/Assets.xcassets/AppIcon.appiconset/logo-adrk.png" width="120" alt="MoodyChat Dark Logo">
</p>

<p align="center">
  <strong>A revolutionary iOS chat application that dynamically adapts its UI based on emotional sentiment</strong>
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Author](#-author)
- [App Showcase](#-app-showcase)
  - [Welcome Experience](#welcome-experience)
  - [Mood Detection in Action](#mood-detection-in-action)
  - [Emotional Chat Experience](#emotional-chat-experience)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Features](#-features)
- [Setup Instructions](#-setup-instructions)
- [Development Phases](#-development-phases)
- [Future Enhancements](#-future-enhancements)
- [Production Considerations](#️-production-considerations)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview
**This is a portfolio project and proof of concept.**

MoodyChat is a revolutionary iOS chat application that dynamically adapts its user interface based on the emotional sentiment of conversations. This proof of concept demonstrates advanced SwiftUI techniques, liquid glass aesthetics, and AI-powered emotional intelligence.

Built with **Liquid Glass aesthetics** and Apple's latest iOS 26 design language, MoodyChat offers a unique conversational experience that feels both intimate and technologically advanced.

> **Note**: This implementation currently uses OLLAMA AI models for mood detection as a proof of concept. In a production environment, **CoreML (on-device sentiment analysis) MUST be implemented** to ensure privacy, performance, and offline functionality.

## 👨‍💻 Author
**Boris Milev**  
GitHub: [https://github.com/BRMilev22](https://github.com/BRMilev22)

---

## 📱 App Showcase

### Welcome Experience
*Beautiful onboarding with mood-adaptive backgrounds*

<p align="center">
  <img src="./assets/welcome-image-peaceful.png" width="250" alt="Peaceful Welcome">
  <img src="./assets/welcome-image-love.png" width="250" alt="Loving Welcome">
  <img src="./assets/welcome-image-excited.png" width="250" alt="Excited Welcome">
</p>

### Mood Detection in Action
*Real-time mood detection with confidence-based UI adaptation*

<p align="center">
  <img src="./assets/mood-detected-happy-chat.png" width="300" alt="Happy Mood Detection">
  <img src="./assets/mood-detected-angry-chat.png" width="300" alt="Angry Mood Detection">
</p>

### Emotional Chat Experience
*Chat interface that transforms based on emotional sentiment*

<p align="center">
  <img src="./assets/neutral-chat.png" width="250" alt="Neutral Chat">
  <img src="./assets/sad-chat.png" width="250" alt="Sad Mood Chat">
</p>

---

## 🛠 Tech Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: Combine + MVVM
- **ML**: OLLAMA (proof of concept) → CoreML (production recommendation)
- **Animation**: SwiftUI animations with liquid glass effects
- **Minimum iOS**: 16.0+

## 📁 Project Structure
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

## ✨ Features

### 🎨 Emotional UI Adaptation
- **Dynamic Color Themes**: Interface colors shift based on conversation sentiment
- **Liquid Glass Effects**: Translucent, frosted glass aesthetics with depth
- **Micro-interactions**: Subtle animations responding to emotional context
- **Adaptive Typography**: Font weights and styles adjust to mood intensity

### 🧠 Sentiment Intelligence
- **AI-Powered Analysis**: OLLAMA-based mood detection (proof of concept)
- **Real-time Processing**: Instant mood detection as you type
- **Contextual Awareness**: Understanding conversation flow and emotional nuance
- **Production Ready**: Designed for CoreML integration for on-device processing

### 💬 Chat Experience
- **Mood-Aware Bubbles**: Message bubbles reflect sender's emotional state
- **Typing Indicators**: Even typing animations reflect emotional anticipation
- **Conversation Insights**: Subtle mood summaries and conversation analytics

## 🚀 Setup Instructions

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

# Open workspace
open MoodyChat.xcworkspace
```

## 🔄 Development Phases

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
- [x] Implement OLLAMA AI-powered conversation insights and mood patterns
- [x] Add progressive mood detection with confidence-based UI adaptation
- [x] Create conversation mood analytics with beautiful charts
- [x] Build liquid glass iOS 26-inspired UI transformation system
- [x] Add mood transition animations with dramatic visual feedback
- [x] Implement contextual emotional intelligence with conversation memory

> **Production Note**: Replace OLLAMA with CoreML for production deployment

## 🎯 Future Enhancements

### 🚀 Stretch Goals
- **Biometric Integration**: Heart rate and stress level correlation
- **Apple Watch Companion**: Wrist-based mood monitoring
- **Siri Integration**: Voice-controlled emotional check-ins

### 🎯 Advanced Features
- **Mood History**: Personal emotional journey tracking
- **Custom Themes**: User-created emotional color palettes
- **AI Mood Coach**: Personalized emotional intelligence insights

## ⚙️ Production Considerations

### CoreML Integration Requirements
For production deployment, the following MUST be implemented:

1. **Replace OLLAMA with CoreML**:
   - Train sentiment analysis model using CreateML
   - Implement on-device inference pipeline
   - Ensure privacy compliance with local processing

2. **Performance Optimization**:
   - Model quantization for mobile deployment
   - Batch processing for efficiency
   - Background sentiment analysis without UI blocking

3. **Privacy & Security**:
   - Remove all network-based AI calls
   - Implement local-only data processing
   - Add user consent and data control features

## 🤝 Contributing
This is a portfolio project demonstrating advanced iOS development concepts. Feedback and suggestions are welcome through GitHub issues.

## 📄 License
© 2025 Boris Milev. All rights reserved.

---

*MoodyChat: A portfolio project showcasing where technology meets emotion, creating conversations that truly understand you.*