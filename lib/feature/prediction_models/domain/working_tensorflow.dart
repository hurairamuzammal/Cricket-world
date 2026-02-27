import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../data/match.dart';

class WorkingTensorflow {
  late Interpreter _interpreter;
  late List<double> _mean;
  late List<double> _std;
  late List<String> _featureNames;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/cricket_win_predictor.tflite',
      );
      // Load scaler parameters from JSON
      final String jsonString = await rootBundle.loadString(
        'assets/models/keras_scaler_params.json',
      );
      final Map<String, dynamic> scalerParams = json.decode(jsonString);

      _mean = List<double>.from(scalerParams['mean']);
      _std = List<double>.from(scalerParams['std']);
      _featureNames = List<String>.from(scalerParams['features']);

      _isLoaded = true;
      print('Model loaded successfully');
      print('Features: $_featureNames');
    } catch (e) {
      print('! Error loading model: $e');
      rethrow;
    }
  }

  bool get isLoaded => _isLoaded;

  /// Apply StandardScaler transformation: scaled = (x - mean) / std
  List<double> _scaleFeatures(List<double> rawFeatures) {
    // if (_mean == null || _std == null) {
    //   throw Exception('Scaler not loaded. Call loadModel() first.');
    // }

    if (rawFeatures.length != _mean.length) {
      throw Exception(
        'Feature count mismatch. Expected ${_mean.length}, got ${rawFeatures.length}',
      );
    }

    List<double> scaled = [];
    for (int i = 0; i < rawFeatures.length; i++) {
      // StandardScaler formula: (x - mean) / std
      // Add small epsilon to avoid division by zero
      double stdVal = _std[i] != 0 ? _std[i] : 1e-10;
      double scaledValue = (rawFeatures[i] - _mean[i]) / stdVal;
      scaled.add(scaledValue);
    }
    return scaled;
  }

  double predict(MatchState state) {
    if (!_isLoaded  ) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    // Calculate all features
    final features = state.toFeatureVector();

    // Apply StandardScaler
    final scaledFeatures = _scaleFeatures(features);

    // Prepare input/output tensors
    var input = [scaledFeatures];
    var output = List.filled(1, [0.0]);

    // Run inference
    _interpreter.run(input, output);

    // Return the probability (sigmoid output gives value between 0-1)
    double probability = output[0][0];

    // Clamp to valid probability range
    return probability.clamp(0.0, 1.0);
  }

  void dispose() {
    _interpreter.close();
    _isLoaded = false;
  }
}
