# 🏏 Flutter Cricket Win Predictor - Master Integration Guide

This guide covers the integration of the Cricket Win Probability Model into your Flutter application.

## 📁 Required Assets

Ensure you have the following files in your `assets/models/` directory:

1.  **TensorFlow Lite Model**: `keras_model.tflite` (23 KB)
2.  **Scaler Parameters**: `keras_scaler_params.json` (Contains 11 mean/std values)
3.  **Pure Dart Model**: `mlp_sklearn_model.json` (For Approach 2)

---

## 📋 Feature Engineering (11 Features)

The model expects exactly 11 features in the following order. These must be calculated in real-time within your Flutter app:

| Index | Feature Name | Formula / Description |
| :--- | :--- | :--- |
| 0 | `runs_left` | `target - runsScored` |
| 1 | `balls_left` | `120 - ballsBowled` |
| 2 | `wickets_left` | **Wickets Fallen** (0 to 10) |
| 3 | `cur_run_rate` | `(runsScored / ballsBowled) * 6` |
| 4 | `req_run_rate` | `runsLeft / (ballsLeft / 6)` |
| 5 | `pressure` | `req_run_rate - cur_run_rate` |
| 6 | `resource_score`| `(wicketsFallen^1.5) * (ballsLeft^0.5)` |
| 7 | `rr_ratio` | `reqRunRate / (curRunRate + 0.5)` |
| 8 | `runs_last_12` | Sum of runs in the last 12 balls |
| 9 | `wickets_last_18`| `-(wickets fallen in last 18 balls)` |
| 10 | `venue_par_diff`| `targetRuns - venueAverageTarget` |

> **Note on Index 2 & 9**: The model was trained with `wickets_left` representing **wickets fallen** and `wickets_last_18` as a **negative change** in wickets remaining.

---

## � Integration Approaches

### Approach 1: TensorFlow Lite (Recommended)
Use this if you want maximum performance and minimum file size.

**Dependencies:**
```yaml
dependencies:
  tflite_flutter: ^0.10.4
```

**Implementation:**
Use the `CricketWinPredictor` class provided in `lib/cricket_win_predictor.dart`.

```dart
final predictor = CricketWinPredictor();
await predictor.loadModel(); // Loads keras_model.tflite and keras_scaler_params.json

double winProb = predictor.predict(matchState);
print("Win Probability: ${winProb.toPercentString()}");
```

### Approach 2: Pure Dart (No Dependencies)
Use this if you want to avoid native binaries or `tflite_flutter` overhead.

**Implementation:**
Use the `SklearnMLPPredictor` class provided in `lib/sklearn_mlp_predictor.dart`.

```dart
final predictor = SklearnMLPPredictor();
await predictor.loadModel(); // Loads mlp_sklearn_model.json

double winProb = predictor.predict(matchState);
```

---

## � Project Structure

```
your_flutter_app/
├── assets/
│   └── models/
│       ├── keras_model.tflite
│       ├── keras_scaler_params.json
│       └── mlp_sklearn_model.json
├── lib/
│   ├── main.dart
│   └── predictor/
│       ├── cricket_win_predictor.dart  (Approach 1)
│       └── sklearn_mlp_predictor.dart  (Approach 2)
└── pubspec.yaml
```

## 📝 Pubspec Configuration
```yaml
flutter:
  assets:
    - assets/models/keras_model.tflite
    - assets/models/keras_scaler_params.json
    - assets/models/mlp_sklearn_model.json
```
