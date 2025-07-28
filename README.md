# 📖 Storyboard – AI-Powered Financial Literacy Game for Teens - FBLA NATIONALIST

<img src="assets/icon.png" alt="Storyboard Icon" width="150"/>

**Storyboard** is an iOS app that teaches teens how to manage money—through immersive, interactive storytelling powered by **Groq's LLaMA 3**, Firebase, and SwiftUI. Built for the 2025 FBLA Introduction to Programming competition, Storyboard blends **gameplay, AI, and real-life financial decision-making** into one unforgettable experience.

---

## 🚀 Features

- 🎮 **Adventure Mode**: Choose your own path through preset financial stories about budgeting, career planning, and investing.
- 🤖 **AI Mode**: Enter *any* idea and let our LLM create a custom financial journey—plus live translation and image generation.
- 🧠 **Minigames**: Learn by doing—play fast-paced games that reinforce key financial skills.
- 🗣️ **Groq-Powered Multilingual Narration**: Real-time story translation for accessibility across users.
- 📊 **Real-Time Leaderboard**: Compete with friends and track your top-performing runs.
- 📷 **API-Based Image Generation**: Every story is visually enhanced using keyword extraction and 3D assets from Sketchfab.
- 📄 **Custom Financial Report**: View a detailed breakdown of your decisions, earnings, and outcomes at the end of every session.
- ✅ **Real-Time Validation**: Smart input handling across login, signup, and prompt generation.
- 🔒 **Firebase Integration**: Secure authentication, instant sync, and persistent cloud data.

---

## 📸 Screenshots

| Home Screen | AI Mode | Adventure Mode | Financial Report |
|-------------|---------|----------------|------------------|
| ![Home](https://your-image-url.com/home.png) | ![AI](https://your-image-url.com/ai.png) | ![Adventure](https://your-image-url.com/adventure.png) | ![Report](https://your-image-url.com/report.png) |

---

## 🛠️ Built With

- **Swift & SwiftUI** – native UI and modular MVVM structure
- **Xcode** – development environment
- **Firebase** – authentication, Firestore storage, and real-time sync
- **Groq LLaMA 3 API** – AI story generation and live translation
- **Sketchfab API** – keyword-to-image functionality
- **CoreMotion**, **AVFoundation**, **PhotosUI**, **Speech** – to enhance user experience and interactivity

---

## 🧠 Architecture

- **MVVM Pattern**: ViewModels handle logic, Services handle Firebase/AI, Views stay UI-only.
- **Modular Codebase**: Everything is cleanly separated by responsibility.
- **Reusable Components**: Buttons, prompts, and UI containers are written once and used across the app.

---

## 🔧 Getting Started

1. **Clone this repository**
   ```bash
   git clone https://github.com/your-username/storyboard.git
