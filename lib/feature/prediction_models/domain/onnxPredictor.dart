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