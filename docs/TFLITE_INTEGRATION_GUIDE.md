# TensorFlow Lite Integration Guide for Flutter

This guide explains how to integrate TensorFlow Lite models into your Flutter application for **Windows** and **Android** platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Android Configuration](#android-configuration)
4. [Windows Configuration](#windows-configuration)
5. [Model Preparation](#model-preparation)
6. [Dart Implementation](#dart-implementation)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Flutter SDK 3.10+
- A trained TensorFlow/Keras model
- Python environment (for model conversion)

---

## Project Setup

### 1. Add Dependencies

Add `tflite_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.12.1
```

### 2. Create Assets Directory

Create an `assets` folder in your project root and add your model files:

```
your_project/
├── assets/
│   ├── your_model.tflite
│   └── scaler_params.json  # Optional: for normalization
├── lib/
└── pubspec.yaml
```

### 3. Register Assets in pubspec.yaml

```yaml
flutter:
  assets:
    - assets/your_model.tflite
    - assets/scaler_params.json
```

---

## Android Configuration

### build.gradle.kts (app level)

Ensure your `android/app/build.gradle.kts` has the correct configuration:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.yourapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.yourapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
```

### ProGuard Rules (for Release Builds)

Create or update `android/app/proguard-rules.pro`:

```proguard
# TensorFlow Lite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
```

---

## Windows Configuration

### Automatic DLL Download

The `tflite_flutter` package automatically downloads the required DLL on first run. However, you can manually place the DLL if needed.

### Manual DLL Setup (Optional)

1. Download `libtensorflowlite_c-win.dll` from the [TensorFlow Lite releases](https://github.com/pycnic/tflite-flutter-plugin/releases)

2. Place it in your build output:
   ```
   build/windows/x64/runner/Debug/blobs/libtensorflowlite_c-win.dll
   ```

### Known Issues on Windows

- First run may take longer due to DLL download
- If DLL loading fails, ensure Visual C++ Redistributable 2019+ is installed

---

## Model Preparation

### 1. Convert Keras Model to TFLite

```python
import tensorflow as tf

# Load your trained Keras model
model = tf.keras.models.load_model('your_model.keras')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('your_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model converted successfully!")
```

### 2. Save Scaler Parameters (if using normalization)

```python
import json

# If you used StandardScaler during training
scaler_params = {
    'mean': float(scaler.mean_[0]),
    'std': float(scaler.scale_[0])
}

with open('scaler_params.json', 'w') as f:
    json.dump(scaler_params, f)
```

---

## Dart Implementation

### Basic Predictor Class

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TflitePredictor {
  Interpreter? _interpreter;
  double _mean = 0.0;
  double _std = 1.0;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the TFLite model and load scaler parameters.
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/your_model.tflite');
      
      // Load scaler parameters (optional)
      final jsonString = await rootBundle.loadString('assets/scaler_params.json');
      final params = jsonDecode(jsonString) as Map<String, dynamic>;
      _mean = (params['mean'] as num).toDouble();
      _std = (params['std'] as num).toDouble();
      
      _isInitialized = true;
      print('TFLite model initialized successfully');
    } catch (e) {
      print('Error initializing TFLite predictor: $e');
      rethrow;
    }
  }

  /// Run prediction on a single input.
  double predict(double x) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Predictor not initialized. Call initialize() first.');
    }
    
    // Normalize input
    final normalizedInput = (x - _mean) / _std;
    
    // Prepare input tensor [batch_size, features]
    var input = [[normalizedInput]];
    
    // Prepare output tensor
    var output = List.filled(1, List.filled(1, 0.0));
    
    // Run inference
    _interpreter!.run(input, output);
    
    // Denormalize output
    final result = output[0][0] * _std + _mean;
    
    return result;
  }

  /// Run prediction on a batch of inputs.
  List<double> predictBatch(List<double> inputs) {
    return inputs.map((x) => predict(x)).toList();
  }

  /// Release resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
```

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'tflite_predictor.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _predictor = TflitePredictor();
  String _result = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPredictor();
  }

  Future<void> _initPredictor() async {
    await _predictor.initialize();
    setState(() => _loading = false);
  }

  void _runPrediction(double input) {
    final result = _predictor.predict(input);
    setState(() {
      _result = 'Input: $input → Output: ${result.toStringAsFixed(2)}';
    });
  }

  @override
  void dispose() {
    _predictor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('TFLite Prediction')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _runPrediction(5.0),
              child: const Text('Predict'),
            ),
            const SizedBox(height: 16),
            Text(_result, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `Failed to load dynamic library` on Windows | Install Visual C++ Redistributable 2019+ |
| `Interpreter.fromAsset` fails | Check asset path in pubspec.yaml |
| Model gives wrong outputs | Verify input/output normalization matches training |
| Build fails on Android | Check Java version (use Java 11) |
| `tflite_flutter_helper_plus` namespace error | Remove this package, use `tflite_flutter` only |

### Checking Model Input/Output Shapes

```dart
// After initialization
print('Input tensors: ${_interpreter!.getInputTensors()}');
print('Output tensors: ${_interpreter!.getOutputTensors()}');
```

### Debugging Tips

1. **Print model info** during initialization to verify shapes
2. **Compare outputs** with Python inference for same inputs
3. **Check normalization** - ensure mean/std match training exactly
4. **Test on desktop first** - Windows debugging is easier than Android

---

## Platform Support Matrix

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Supported | Requires minSdk 21+ |
| Windows | ✅ Supported | DLL auto-downloaded |
| iOS | ✅ Supported | Requires iOS 11+ |
| macOS | ✅ Supported | - |
| Linux | ✅ Supported | - |
| Web | ❌ Not Supported | Use TensorFlow.js instead |

---

## Resources

- [tflite_flutter Package](https://pub.dev/packages/tflite_flutter)
- [TensorFlow Lite Guide](https://www.tensorflow.org/lite/guide)
- [Flutter Documentation](https://flutter.dev/docs)
