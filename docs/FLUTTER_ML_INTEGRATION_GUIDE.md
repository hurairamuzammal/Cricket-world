# Complete Flutter ML Model Integration Guide
## TensorFlow Lite & ONNX Runtime for Windows and Android

This comprehensive guide covers how to integrate machine learning models into your Flutter application using both **TensorFlow Lite** and **ONNX Runtime** for **Windows** and **Android** platforms.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Setup](#project-setup)
4. [Platform Configuration](#platform-configuration)
   - [Android Setup](#android-setup)
   - [Windows Setup](#windows-setup)
5. [Model Preparation](#model-preparation)
   - [Converting to TFLite](#converting-to-tflite)
   - [Converting to ONNX](#converting-to-onnx)
   - [Saving Scaler Parameters](#saving-scaler-parameters)
6. [Dart Implementation](#dart-implementation)
   - [TFLite Predictor](#tflite-predictor)
   - [ONNX Predictor](#onnx-predictor)
   - [Combined Screen](#combined-screen)
7. [Troubleshooting](#troubleshooting)
8. [Comparison: TFLite vs ONNX](#comparison-tflite-vs-onnx)
9. [Resources](#resources)

---

## Overview

| Framework | Package | API Style | Best For |
|-----------|---------|-----------|----------|
| **TFLite** | `tflite_flutter` | Synchronous | TensorFlow/Keras models |
| **ONNX** | `flutter_onnxruntime` | Asynchronous | Cross-framework (PyTorch, sklearn, etc.) |

Both frameworks support Android and Windows platforms with similar setup requirements.

---

## Prerequisites

- Flutter SDK 3.10+
- A trained ML model (Keras, PyTorch, scikit-learn, etc.)
- Python 3.8+ with the following packages:
  ```bash
  pip install tensorflow tf2onnx onnx onnxruntime
  ```

---

## Project Setup

### Step 1: Add Dependencies

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # TensorFlow Lite
  tflite_flutter: ^0.12.1
  
  # ONNX Runtime
  flutter_onnxruntime: ^1.6.1
```

Run:
```bash
flutter pub get
```

### Step 2: Create Assets Directory

Create the following structure in your project root:

```
your_project/
├── assets/
│   ├── your_model.tflite      # TFLite model
│   ├── your_model.onnx        # ONNX model
│   └── scaler_params.json     # Normalization parameters
├── lib/
│   ├── main.dart
│   ├── tflite_predictor.dart
│   ├── onnx_predictor.dart
│   └── combined_screen.dart
└── pubspec.yaml
```

### Step 3: Register Assets

Add assets to `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/your_model.tflite
    - assets/your_model.onnx
    - assets/scaler_params.json
```

---

## Platform Configuration

### Android Setup

#### 1. Update `android/app/build.gradle.kts`

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
        
        // Required for ONNX Runtime native libraries
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        }
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

#### 2. Create ProGuard Rules

Create `android/app/proguard-rules.pro`:

```proguard
# TensorFlow Lite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# ONNX Runtime
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
```

#### 3. Common Android Issues

| Issue | Solution |
|-------|----------|
| `minSdk` unresolved | Move `minSdk` inside `defaultConfig` block |
| Java version error | Use Java 11, not Java 17 |
| Namespace error | Ensure `namespace` is defined in `android` block |
| `tflite_flutter_helper_plus` error | Remove this package from dependencies |

---

### Windows Setup

Both packages handle Windows configuration automatically. No manual setup required.

#### System Requirements

- Windows 10/11 (64-bit)
- Visual C++ Redistributable 2019 or later

#### First Run

- TFLite: DLL is auto-downloaded on first run (may take a moment)
- ONNX: Runtime included in the package

#### Troubleshooting Windows

| Issue | Solution |
|-------|----------|
| DLL not found | Install Visual C++ Redistributable 2019+ |
| First run slow | DLL downloading, wait for completion |
| Build fails | Run `flutter clean` then rebuild |

---

## Model Preparation

### Converting to TFLite

#### From Keras/TensorFlow

```python
import tensorflow as tf

# Load your trained model
model = tf.keras.models.load_model('your_model.keras')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('assets/your_model.tflite', 'wb') as f:
    f.write(tflite_model)

print(f"TFLite model saved! Size: {len(tflite_model) / 1024:.1f} KB")
```

---

### Converting to ONNX

#### From Keras/TensorFlow

```python
import tensorflow as tf
import tf2onnx

# Load your trained model
model = tf.keras.models.load_model('your_model.keras')

# Get input shape
input_shape = model.inputs[0].shape
input_dtype = model.inputs[0].dtype

# Define input signature
input_signature = [tf.TensorSpec(input_shape, input_dtype, name='input')]

# Convert to ONNX
onnx_model, _ = tf2onnx.convert.from_keras(model, input_signature)

# Save the model
with open('assets/your_model.onnx', 'wb') as f:
    f.write(onnx_model.SerializeToString())

print("ONNX model saved!")
```

#### From PyTorch

```python
import torch

# Load model
model = YourModel()
model.load_state_dict(torch.load('model.pth'))
model.eval()

# Create dummy input matching your input shape
dummy_input = torch.randn(1, num_features)

# Export to ONNX
torch.onnx.export(
    model,
    dummy_input,
    'assets/your_model.onnx',
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={
        'input': {0: 'batch_size'},
        'output': {0: 'batch_size'}
    }
)
```

#### From scikit-learn

```python
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
import joblib

# Load your trained model
model = joblib.load('sklearn_model.pkl')

# Define input type [batch_size, num_features]
initial_type = [('input', FloatTensorType([None, num_features]))]

# Convert to ONNX
onnx_model = convert_sklearn(model, initial_types=initial_type)

# Save
with open('assets/your_model.onnx', 'wb') as f:
    f.write(onnx_model.SerializeToString())
```

---

### Saving Scaler Parameters

If you used StandardScaler during training, save the parameters:

```python
import json

# Assuming you have a fitted StandardScaler
scaler_params = {
    'mean': float(scaler.mean_[0]),   # For single feature
    'std': float(scaler.scale_[0])
}

# For multiple features
# scaler_params = {
#     'mean': scaler.mean_.tolist(),
#     'std': scaler.scale_.tolist()
# }

with open('assets/scaler_params.json', 'w') as f:
    json.dump(scaler_params, f, indent=2)
```

---

### Verify Models Work

```python
import numpy as np

# Test TFLite
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path='assets/your_model.tflite')
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print(f"TFLite - Input: {input_details[0]['shape']}, Output: {output_details[0]['shape']}")

# Test ONNX
import onnxruntime as ort
session = ort.InferenceSession('assets/your_model.onnx')
print(f"ONNX - Input: {session.get_inputs()[0].name} {session.get_inputs()[0].shape}")
print(f"ONNX - Output: {session.get_outputs()[0].name} {session.get_outputs()[0].shape}")

# Test inference with same input
test_input = np.array([[5.0]], dtype=np.float32)

# TFLite inference
interpreter.set_tensor(input_details[0]['index'], test_input)
interpreter.invoke()
tflite_result = interpreter.get_tensor(output_details[0]['index'])
print(f"TFLite result: {tflite_result}")

# ONNX inference
onnx_result = session.run(None, {'input': test_input})
print(f"ONNX result: {onnx_result}")
```

---

## Dart Implementation

### TFLite Predictor

Create `lib/tflite_predictor.dart`:

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
      // Load the TFLite model from assets
      _interpreter = await Interpreter.fromAsset('assets/your_model.tflite');

      // Load scaler parameters
      final jsonString = await rootBundle.loadString('assets/scaler_params.json');
      final params = jsonDecode(jsonString) as Map<String, dynamic>;
      _mean = (params['mean'] as num).toDouble();
      _std = (params['std'] as num).toDouble();

      _isInitialized = true;
      print('TFLite model initialized successfully');
      print('Scaler params - mean: $_mean, std: $_std');
    } catch (e) {
      print('Error initializing TFLite predictor: $e');
      rethrow;
    }
  }

  /// Run prediction on a single input value.
  double predict(double x) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Predictor not initialized. Call initialize() first.');
    }

    // Normalize input
    final normalizedInput = (x - _mean) / _std;

    // Prepare input tensor [batch_size=1, features=1]
    var input = [[normalizedInput]];

    // Prepare output tensor
    var output = List.filled(1, List.filled(1, 0.0));

    // Run inference (synchronous)
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

---

### ONNX Predictor

Create `lib/onnx_predictor.dart`:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class OnnxPredictor {
  OnnxRuntime? _ort;
  OrtSession? _session;
  double _mean = 0;
  double _std = 1;
  bool _isInitialized = false;
  String _inputName = 'input'; // Will be updated from model

  bool get isInitialized => _isInitialized;

  /// Initialize the ONNX model and load scaler parameters.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Create ONNX Runtime instance
      _ort = OnnxRuntime();

      // Load model from assets
      _session = await _ort!.createSessionFromAsset('assets/your_model.onnx');

      // Get input/output names
      final inputNames = await _session!.inputNames;
      final outputNames = await _session!.outputNames;
      _inputName = inputNames.first;
      
      print('ONNX Input names: $inputNames');
      print('ONNX Output names: $outputNames');

      // Load scaler parameters
      final jsonString = await rootBundle.loadString('assets/scaler_params.json');
      final params = jsonDecode(jsonString) as Map<String, dynamic>;
      _mean = (params['mean'] as num).toDouble();
      _std = (params['std'] as num).toDouble();

      _isInitialized = true;
      print('ONNX model initialized successfully');
      print('Scaler params - mean: $_mean, std: $_std');
    } catch (e) {
      print('Error initializing ONNX predictor: $e');
      rethrow;
    }
  }

  /// Run prediction on a single input value.
  Future<double> predict(double x) async {
    if (!_isInitialized || _session == null) {
      throw Exception('Predictor not initialized. Call initialize() first.');
    }

    // Normalize input
    final normalizedInput = (x - _mean) / _std;

    // Create input tensor with shape [1, 1]
    final inputs = {
      _inputName: await OrtValue.fromList([normalizedInput], [1, 1]),
    };

    // Run inference (asynchronous)
    final outputs = await _session!.run(inputs);

    // Get output value - handle nested output shape [1, 1]
    final outputValue = outputs.values.first;
    final outputList = await outputValue.asList();
    
    // Access nested list: outputList[0] is Float32List, get first element
    final innerList = outputList[0] as List;
    final normalizedOutput = (innerList[0] as num).toDouble();

    // Denormalize output
    final result = normalizedOutput * _std + _mean;

    return result;
  }

  /// Run prediction on a batch of inputs.
  Future<List<double>> predictBatch(List<double> inputs) async {
    final results = <double>[];
    for (final x in inputs) {
      results.add(await predict(x));
    }
    return results;
  }

  /// Release resources.
  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _ort = null;
    _isInitialized = false;
  }
}
```

---

### Combined Screen

Create `lib/combined_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'tflite_predictor.dart';
import 'onnx_predictor.dart';

class CombinedPredictorScreen extends StatefulWidget {
  const CombinedPredictorScreen({super.key});

  @override
  State<CombinedPredictorScreen> createState() => _CombinedPredictorScreenState();
}

class _CombinedPredictorScreenState extends State<CombinedPredictorScreen> {
  final _tflitePredictor = TflitePredictor();
  final _onnxPredictor = OnnxPredictor();
  final _inputController = TextEditingController(text: '5');

  bool _loading = true;
  String? _tfliteError;
  String? _onnxError;

  String _tfliteResult = '';
  String _onnxResult = '';
  Duration? _tfliteTime;
  Duration? _onnxTime;

  @override
  void initState() {
    super.initState();
    _initPredictors();
  }

  Future<void> _initPredictors() async {
    // Initialize both predictors in parallel
    await Future.wait([
      _initTflite(),
      _initOnnx(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _initTflite() async {
    try {
      await _tflitePredictor.initialize();
    } catch (e) {
      _tfliteError = e.toString();
    }
  }

  Future<void> _initOnnx() async {
    try {
      await _onnxPredictor.initialize();
    } catch (e) {
      _onnxError = e.toString();
    }
  }

  Future<void> _runTflitePrediction(double input) async {
    if (_tfliteError != null) return;

    final stopwatch = Stopwatch()..start();
    try {
      final result = _tflitePredictor.predict(input);
      stopwatch.stop();
      setState(() {
        _tfliteResult = result.toStringAsFixed(4);
        _tfliteTime = stopwatch.elapsed;
      });
    } catch (e) {
      setState(() {
        _tfliteResult = 'Error: $e';
        _tfliteTime = null;
      });
    }
  }

  Future<void> _runOnnxPrediction(double input) async {
    if (_onnxError != null) return;

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _onnxPredictor.predict(input);
      stopwatch.stop();
      setState(() {
        _onnxResult = result.toStringAsFixed(4);
        _onnxTime = stopwatch.elapsed;
      });
    } catch (e) {
      setState(() {
        _onnxResult = 'Error: $e';
        _onnxTime = null;
      });
    }
  }

  Future<void> _runBothPredictions() async {
    final input = double.tryParse(_inputController.text) ?? 5.0;
    await Future.wait([
      _runTflitePrediction(input),
      _runOnnxPrediction(input),
    ]);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _tflitePredictor.dispose();
    _onnxPredictor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Model Predictor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading models...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input Section
                  _buildInputCard(),
                  const SizedBox(height: 16),

                  // Run Both Button
                  ElevatedButton.icon(
                    onPressed: _runBothPredictions,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Both Predictions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Results Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          title: 'TFLite',
                          icon: Icons.flash_on,
                          color: Colors.orange,
                          error: _tfliteError,
                          result: _tfliteResult,
                          time: _tfliteTime,
                          onPredict: () => _runTflitePrediction(
                            double.tryParse(_inputController.text) ?? 5.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildResultCard(
                          title: 'ONNX',
                          icon: Icons.memory,
                          color: Colors.blue,
                          error: _onnxError,
                          result: _onnxResult,
                          time: _onnxTime,
                          onPredict: () => _runOnnxPrediction(
                            double.tryParse(_inputController.text) ?? 5.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Tests
                  _buildQuickTests(),
                ],
              ),
            ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Value',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a number',
                prefixIcon: Icon(Icons.numbers),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Expected: ${(double.tryParse(_inputController.text) ?? 5) + 1}',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Color color,
    required String? error,
    required String result,
    required Duration? time,
    required VoidCallback onPredict,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
              )
            else ...[
              Text('Result:', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                result.isEmpty ? '-' : result,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (time != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Time: ${time.inMicroseconds} μs',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPredict,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                  child: const Text('Run'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Tests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in [0, 5, 10, 50, 100, 500, 999])
              OutlinedButton(
                onPressed: () {
                  _inputController.text = value.toString();
                  _runBothPredictions();
                },
                child: Text('Test $value'),
              ),
          ],
        ),
      ],
    );
  }
}
```

---

### Main Entry Point

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'combined_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Model Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CombinedPredictorScreen(),
    );
  }
}
```

---

## Troubleshooting

### Common Issues - Both Platforms

| Issue | Cause | Solution |
|-------|-------|----------|
| Model not found | Asset not registered | Check `pubspec.yaml` assets section |
| Wrong output values | Normalization mismatch | Verify mean/std match training |
| Slow first run | Model loading | Normal - subsequent runs are faster |

### TFLite-Specific Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| DLL load failed (Windows) | Missing VC++ | Install Visual C++ Redistributable 2019+ |
| `Interpreter.fromAsset` fails | Wrong path | Use `assets/` prefix in path |
| Output shape mismatch | Model changed | Print tensor info and adjust code |

### ONNX-Specific Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `NoSuchMethodError: toDouble()` | Nested output | Use `outputList[0][0]` |
| `Float32List not subtype of num` | Wrong cast | Cast inner list first |
| Input name mismatch | Model uses different name | Print `inputNames` and use exact name |

### Android-Specific Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `Unresolved reference: minSdk` | Wrong placement | Move into `defaultConfig` block |
| `jvmTarget deprecated` | Old syntax | Use `kotlinOptions { jvmTarget = "11" }` |
| Java 17 not found | Missing JDK | Use Java 11 instead |
| Namespace error | Old package | Remove `tflite_flutter_helper_plus` |

---

## Comparison: TFLite vs ONNX

| Feature | TFLite | ONNX |
|---------|--------|------|
| **Package** | `tflite_flutter` | `flutter_onnxruntime` |
| **API Style** | Synchronous | Asynchronous (Future) |
| **Inference Call** | `interpreter.run()` | `await session.run()` |
| **Model Size** | Usually smaller | Slightly larger |
| **Speed** | Very fast | Comparable |
| **Source Frameworks** | TensorFlow/Keras only | Any (PyTorch, sklearn, TF) |
| **Output Handling** | Direct list access | Nested list, needs casting |
| **First Run** | DLL download (Windows) | Immediate |

### When to Use TFLite

- ✅ Model trained with TensorFlow/Keras
- ✅ Need synchronous API for simpler code
- ✅ Want smallest model size
- ✅ TensorFlow ecosystem integration

### When to Use ONNX

- ✅ Model from PyTorch, scikit-learn, or other frameworks
- ✅ Need cross-framework portability
- ✅ Using ONNX-specific optimizations
- ✅ Already have ONNX models

### Using Both Together

Both can coexist in the same app! Use:
- TFLite for TensorFlow/Keras models
- ONNX for PyTorch/sklearn models
- Compare performance and choose the best for production

---

## Resources

### Documentation

- [tflite_flutter Package](https://pub.dev/packages/tflite_flutter)
- [flutter_onnxruntime Package](https://pub.dev/packages/flutter_onnxruntime)
- [TensorFlow Lite Guide](https://www.tensorflow.org/lite/guide)
- [ONNX Runtime Docs](https://onnxruntime.ai/docs/)

### Model Conversion

- [tf2onnx (TensorFlow to ONNX)](https://github.com/onnx/tensorflow-onnx)
- [skl2onnx (scikit-learn to ONNX)](https://github.com/onnx/sklearn-onnx)
- [PyTorch ONNX Export](https://pytorch.org/docs/stable/onnx.html)

### Platform Support

| Platform | TFLite | ONNX |
|----------|--------|------|
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ |
| Windows | ✅ | ✅ |
| macOS | ✅ | ✅ |
| Linux | ✅ | ✅ |
| Web | ❌ | ❌ |

---

## Complete Checklist

Before running your app, verify:

- [ ] Both packages added to `pubspec.yaml`
- [ ] Assets registered in `pubspec.yaml`
- [ ] Model files in `assets/` directory
- [ ] Scaler params JSON created
- [ ] Android `build.gradle.kts` configured correctly
- [ ] Java version set to 11
- [ ] ProGuard rules added (for release builds)
- [ ] Input/output names match model
- [ ] Normalization matches training
- [ ] `flutter pub get` run
- [ ] `flutter clean` run (if issues persist)
