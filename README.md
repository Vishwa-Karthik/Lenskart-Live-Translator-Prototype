# 🔍 Lenskart Lens Companion

A live translator prototype designed for smart eyewear HUD (Heads-Up Display) systems. Listen to speech, get instant translations, and hear them spoken back — all in real-time.

## ✨ Features

- **Live Speech Recognition** — Captures audio input and transcribes it instantly
- **Real-time Translation** — Translates between English, Hindi, and Kannada
- **Text-to-Speech** — Speaks translations back to the user with natural voice
- **Smart Model Loading** — On mobile, uses local Google ML Kit models; on web, uses cloud APIs for simplicity
- **Beautiful HUD UI** — Glassmorphic dark theme with gradient overlays, perfect for wearable concepts
- **Language Switching** — Easy toggle between language pairs
- **Translation Overlay** — Full-screen modal showing the translated text

## 🛠️ How It Works

### Translation Architecture

**On Mobile (Android/iOS):**
- Downloads translation models locally using Google ML Kit (first launch)
- Processes all translations offline for privacy and speed
- Models are cached for future use

**On Web:**
- Uses cloud-based translation APIs via HTTP
- No local model storage needed
- Simpler setup for browser-based prototyping

## 📝 Notes

This is a **prototype/proof-of-concept** for demonstrating live translation on smart eyewear. The UI concept explores HUD-style interfaces with glassmorphic design patterns commonly used in AR applications.

## 👨‍💻 Developer

**Built by:** Vishwa Karthik  
**Purpose:** Concept prototype exploring Smart-powered translation for wearable devices