# ONNX Model Inference Guide for Flutter
## Windows & Android

A focused guide on running ONNX model inference in Flutter. Assumes you already have your `.onnx` model and `scaler_params.json` files ready.

---

## Quick Setup

### 1. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  flutter_onnxruntime: ^1.6.1
```

### 2. Add Assets

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/your_model.onnx
    - assets/scaler_params.json
```

### 3. Android Config

In `android/app/build.gradle.kts`, ensure Java 11:

```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

kotlinOptions {
    jvmTarget = "11"
}
```

---

## Basic Inference

### Single Feature Input

```dart
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

// Initialize
final ort = OnnxRuntime();
final session = await ort.createSessionFromAsset('assets/your_model.onnx');

// Get input name from model
final inputNames = await session.inputNames;
print('Input name: ${inputNames.first}'); // e.g., "input"

// Create input tensor: shape [1, 1] for single value
final input = await OrtValue.fromList([5.0], [1, 1]);

// Run inference
final outputs = await session.run({inputNames.first: input});

// Get result
final outputValue = outputs.values.first;
final outputList = await outputValue.asList();
final result = (outputList[0] as List)[0] as double;
print('Result: $result');
```

---

## Multiple Features Input

### Example: 11 Features

```dart
// Your feature values
final features = [
  150.0,  // feature 1
  45.0,   // feature 2
  6.0,    // feature 3
  2.0,    // feature 4
  18.5,   // feature 5
  3.2,    // feature 6
  0.75,   // feature 7
  12.0,   // feature 8
  85.0,   // feature 9
  1.0,    // feature 10
  42.0,   // feature 11
];

// Create input tensor: shape [1, 11] for 11 features
final input = await OrtValue.fromList(features, [1, features.length]);

// Run inference
final outputs = await session.run({'input': input});

// Get result
final outputValue = outputs.values.first;
final outputList = await outputValue.asList();
final result = (outputList[0] as List)[0] as double;
```

---

## With Normalization (StandardScaler)

### scaler_params.json Format

```json
{
  "mean": [10.5, 20.3, 5.2, ...],
  "std": [2.1, 4.5, 1.8, ...]
}
```

### Normalize Before Inference

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

// Load scaler params
final jsonString = await rootBundle.loadString('assets/scaler_params.json');
final params = jsonDecode(jsonString);
final mean = (params['mean'] as List).cast<num>();
final std = (params['std'] as List).cast<num>();

// Your raw features
final rawFeatures = [150.0, 45.0, 6.0, 2.0, 18.5, 3.2, 0.75, 12.0, 85.0, 1.0, 42.0];

// Normalize each feature: (value - mean) / std
final normalizedFeatures = <double>[];
for (int i = 0; i < rawFeatures.length; i++) {
  normalizedFeatures.add((rawFeatures[i] - mean[i]) / std[i]);
}

// Create input tensor with normalized features
final input = await OrtValue.fromList(normalizedFeatures, [1, normalizedFeatures.length]);

// Run inference
final outputs = await session.run({'input': input});
```

---

## Complete Predictor Class

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class OnnxPredictor {
  OnnxRuntime? _ort;
  OrtSession? _session;
  String _inputName = 'input';
  List<double> _mean = [];
  List<double> _std = [];
  bool _isInitialized = false;

  Future<void> initialize({
    required String modelPath,
    required String scalerPath,
  }) async {
    if (_isInitialized) return;

    // Create session
    _ort = OnnxRuntime();
    _session = await _ort!.createSessionFromAsset(modelPath);

    // Get input name
    final inputNames = await _session!.inputNames;
    _inputName = inputNames.first;

    // Load scaler params
    final jsonString = await rootBundle.loadString(scalerPath);
    final params = jsonDecode(jsonString);
    _mean = (params['mean'] as List).map((e) => (e as num).toDouble()).toList();
    _std = (params['std'] as List).map((e) => (e as num).toDouble()).toList();

    _isInitialized = true;
  }

  Future<double> predict(List<double> features) async {
    if (!_isInitialized) throw Exception('Call initialize() first');

    // Normalize features
    final normalized = <double>[];
    for (int i = 0; i < features.length; i++) {
      normalized.add((features[i] - _mean[i]) / _std[i]);
    }

    // Create input tensor
    final input = await OrtValue.fromList(normalized, [1, features.length]);

    // Run inference
    final outputs = await _session!.run({_inputName: input});

    // Extract result
    final outputList = await outputs.values.first.asList();
    final innerList = outputList[0] as List;
    return (innerList[0] as num).toDouble();
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _ort = null;
    _isInitialized = false;
  }
}
```

### Usage

```dart
final predictor = OnnxPredictor();

await predictor.initialize(
  modelPath: 'assets/your_model.onnx',
  scalerPath: 'assets/scaler_params.json',
);

// Provide your features
final features = [150.0, 45.0, 6.0, 2.0, 18.5, 3.2, 0.75, 12.0, 85.0, 1.0, 42.0];
final result = await predictor.predict(features);
print('Prediction: $result');
```

---

## Input Shapes Reference

| Scenario | Features | Shape | Code |
|----------|----------|-------|------|
| Single value | 1 | `[1, 1]` | `OrtValue.fromList([x], [1, 1])` |
| Single row, N features | N | `[1, N]` | `OrtValue.fromList(features, [1, N])` |
| Batch of M rows | M × N | `[M, N]` | `OrtValue.fromList(flatList, [M, N])` |

### Batch Inference Example

```dart
// 3 samples, each with 4 features
final batch = [
  1.0, 2.0, 3.0, 4.0,  // sample 1
  5.0, 6.0, 7.0, 8.0,  // sample 2
  9.0, 10.0, 11.0, 12.0, // sample 3
];

final input = await OrtValue.fromList(batch, [3, 4]); // [batch_size, features]
```

---

## Getting Output

### Single Output Value (Shape [1, 1])

```dart
final outputList = await outputValue.asList();
final innerList = outputList[0] as List;
final result = (innerList[0] as num).toDouble();
```

### Multiple Output Values (Shape [1, N])

```dart
final outputList = await outputValue.asList();
final innerList = outputList[0] as List;
final results = innerList.map((e) => (e as num).toDouble()).toList();
```

### Classification Probabilities

```dart
final outputList = await outputValue.asList();
final probabilities = (outputList[0] as List).cast<double>();
final predictedClass = probabilities.indexOf(probabilities.reduce(max));
```

---

## Debug: Print Model Info

```dart
final session = await ort.createSessionFromAsset('assets/model.onnx');

// Input info
final inputNames = await session.inputNames;
print('Inputs: $inputNames');

// Output info  
final outputNames = await session.outputNames;
print('Outputs: $outputNames');
```

---

## Common Errors

| Error | Fix |
|-------|-----|
| `NoSuchMethodError: toDouble()` | Output is nested, use `outputList[0][0]` |
| `Float32List is not subtype of num` | Cast: `(outputList[0] as List)[0]` |
| `Input name not found` | Print `inputNames` and use exact name |
| Model not loading | Check asset path starts with `assets/` |

---

## Minimal Working Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PredictScreen());
  }
}

class PredictScreen extends StatefulWidget {
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  String result = 'Loading...';

  @override
  void initState() {
    super.initState();
    runPrediction();
  }

  Future<void> runPrediction() async {
    final ort = OnnxRuntime();
    final session = await ort.createSessionFromAsset('assets/model.onnx');
    
    // Your features here
    final features = [1.0, 2.0, 3.0, 4.0, 5.0];
    
    final input = await OrtValue.fromList(features, [1, features.length]);
    final outputs = await session.run({'input': input});
    
    final outputList = await outputs.values.first.asList();
    final prediction = (outputList[0] as List)[0];
    
    setState(() => result = 'Prediction: $prediction');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONNX Test')),
      body: Center(child: Text(result, style: const TextStyle(fontSize: 24))),
    );
  }
}
```
