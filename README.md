<div align="center">

# 🏏 World of Cricket

**Real-Time Cricket Intelligence, Live Match Scorecards & Machine Learning Win Predictor.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-0553B1?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![TensorFlow Lite](https://img.shields.io/badge/ML-TensorFlow_Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)](https://www.tensorflow.org/lite)
[![ONNX](https://img.shields.io/badge/ML-ONNX_Runtime-005CED?style=for-the-badge&logo=onnx&logoColor=white)](https://onnxruntime.ai)
[![Material 3](https://img.shields.io/badge/Design-Material_3-7B1FA2?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

<img src="assets/showcase/banner.png" alt="World of Cricket Banner" width="100%" style="border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.12);" />

</div>

---

## 🌟 Overview

**World of Cricket** is a feature-rich, intelligent sports analytics mobile application built with **Flutter**, **Riverpod**, and embedded **Machine Learning** models. 

Designed for cricket enthusiasts, the app provides a seamless live match experience with instant scorecards, ball-by-ball updates, tournament schedules, and real-time win probability predictions powered by pre-trained **TensorFlow Lite** and **ONNX** inference models.

---

## 🚀 Key Features

### ⚡ Live Match Center & Match Analytics
- Interactive dashboards for **Live Matches**, **Upcoming Fixtures**, and **Recent Results**.
- Ball-by-ball commentary, overs breakdown, required run rates, wickets, and venue information.
- Resilient local caching: match summaries and scores remain accessible offline.

### 🧠 Machine Learning Win Predictor & Score Forecasting
- **Win Wiz Probability Engine**: Computes dynamic match outcome probabilities ball-by-ball based on current match context.
- **Embedded ML Inference**: High-efficiency, on-device prediction models using TFLite and ONNX.
- **In-App Testing Screen**: Built-in developer testing screen to experiment with custom match scenarios.

### 🎨 Tri-Theme Visual Engine
- **Dynamic Material 3**: Adapts seamlessly to system colors and Material 3 palettes.
- **Light & Dark Modes**: Engineered for optimal contrast and battery efficiency.
- **High-Contrast Monochrome Mode**: A bespoke black-and-white theme designed for distraction-free, minimalist viewing.
- **Typography**: Paired Google Fonts (`Montserrat` for expressive headlines, `Poppins` for crisp UI elements).

### 📰 Sports News & Insights
- Integrated cricket news feed with smooth Lottie animations.
- Real-time tournament updates, series recaps, and match reports.

---

## 🖼️ Visual Showcase

<div align="center">

| Live Matches Feed | Real-time Scorecard |
| :---: | :---: |
| <img src="assets/showcase/matches_screen.jpg" width="90%" alt="Matches Feed" style="border-radius: 8px;" /> | <img src="assets/showcase/live_score.jpg" width="90%" alt="Score Details" style="border-radius: 8px;" /> |

| Theme Settings & Customizer | Cricket News Feed |
| :---: | :---: |
| <img src="assets/showcase/theme_settings.jpg" width="90%" alt="Theme Customizer" style="border-radius: 8px;" /> | <img src="assets/showcase/news_screen.jpg" width="90%" alt="Cricket News" style="border-radius: 8px;" /> |

| High-Contrast Monochrome Mode |
| :---: |
| <img src="assets/showcase/monochrome_preview.png" width="95%" alt="Monochrome Mode" style="border-radius: 8px;" /> |

</div>

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/         # App constants and configuration
│   ├── services/          # ThemeService & OnboardingService
│   ├── theme/             # AppThemes (Dynamic, Light, Dark, Monochrome)
│   └── widgets/           # ThemeSettingsScreen, TestModelScreen
└── feature/
    ├── matches_scores/    # Live scores presentation, domain & repository
    └── sports_news/       # News aggregation and reader screens
```

- **State Management**: Reactive state management handled via Riverpod providers.
- **Offline First**: Match data models with local fallback persistence.
- **Design System**: Material 3 theming with custom `ThemeExtension` tokens.

---

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.8.0)
- [Dart SDK](https://dart.dev/get-dart) (^3.8.0)
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hurairamuzammal/Cricket-world.git
   cd Cricket-world
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Flutter application:**
   ```bash
   flutter run
   ```

---

## 👨‍💻 Developer & Contact

Developed with ❤️ by **Muhammad Abu Huraira**

- GitHub: [@hurairamuzammal](https://github.com/hurairamuzammal)
- Email: [huraira.eqeel@gmail.com](mailto:huraira.eqeel@gmail.com)

---

<div align="center">
  <sub>⭐ Found World of Cricket helpful? Consider giving this repository a star!</sub>
</div>
