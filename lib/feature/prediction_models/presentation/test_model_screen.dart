import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/match.dart';
import '../domain/working_tensorflow.dart';
import '../domain/onnxPredictor.dart';

/// A screen for testing TFLite prediction using MatchState logic
class TestModelScreen extends StatefulWidget {
  const TestModelScreen({super.key});

  @override
  State<TestModelScreen> createState() => _TestModelScreenState();
}

class _TestModelScreenState extends State<TestModelScreen> {
  // Controllers for input fields
  final _totalTargetController = TextEditingController(text: '150');
  final _runsScoredController = TextEditingController(text: '24');
  final _ballsBowledController = TextEditingController(text: '12');
  final _wicketsFallenController = TextEditingController(text: '1');
  final _venueAvgController = TextEditingController(text: '165');

  // New controllers for momentum features
  final _runsLast12Controller = TextEditingController(text: '12');
  final _wicketsLast18Controller = TextEditingController(text: '0');

  late WorkingTensorflow _tfliteService;
  late OnnxPredictor _onnxPredictor;
  String? _tfliteResult;
  String? _onnxResult;
  bool _isLoadingTflite = false;
  bool _isLoadingOnnx = false;
  bool _onnxModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _tfliteService = WorkingTensorflow();
    _onnxPredictor = OnnxPredictor();
    _initModels();
  }

  Future<void> _initModels() async {
    // Load TFLite model
    try {
      await _tfliteService.loadModel();
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
    }

    // Load ONNX model
    try {
      await _onnxPredictor.initialize(
        modelPath: 'assets/models/cricket_model.onnx',
        scalerPath: 'assets/models/onnx_scaler_params.json',
      );
      _onnxModelLoaded = true;
    } catch (e) {
      debugPrint('Error loading ONNX model: $e');
    }
  }

  @override
  void dispose() {
    _totalTargetController.dispose();
    _runsScoredController.dispose();
    _ballsBowledController.dispose();
    _wicketsFallenController.dispose();
    _venueAvgController.dispose();
    _runsLast12Controller.dispose();
    _wicketsLast18Controller.dispose();
    _tfliteService.dispose();
    _onnxPredictor.dispose();
    super.dispose();
  }

  /// Helper to create a dummy ball history based on user intensity inputs
  List<BallEvent> _generateMockHistory() {
    final runs = int.tryParse(_runsLast12Controller.text) ?? 12;
    final wks = int.tryParse(_wicketsLast18Controller.text) ?? 0;

    // Create exactly 18 events to satisfy the MatchState logic
    return List.generate(18, (i) {
      return BallEvent(
        runs: (i >= 6)
            ? (runs / 12).round()
            : 0, // Spread runs in last 12 balls
        isWicket: (i == 0 && wks > 0), // Put wickets at start of history
      );
    });
  }

  /// Get input values as a MatchState object
  MatchState _getMatchState() {
    return MatchState(
      targetRuns: int.tryParse(_totalTargetController.text) ?? 150,
      runsScored: int.tryParse(_runsScoredController.text) ?? 24,
      ballsBowled: int.tryParse(_ballsBowledController.text) ?? 12,
      wicketsFallen: int.tryParse(_wicketsFallenController.text) ?? 1,
      venueAvgTarget: double.tryParse(_venueAvgController.text) ?? 165,
      ballHistory: _generateMockHistory(),
    );
  }

  /// Run TFLite model prediction using real service
  Future<void> _predictWithTflite() async {
    if (!_tfliteService.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model still loading... please wait.')),
      );
      return;
    }

    setState(() {
      _isLoadingTflite = true;
      _tfliteResult = null;
    });

    try {
      final state = _getMatchState();

      // Actual TFLite Inference
      final winProbability = _tfliteService.predict(state);

      setState(() {
        _isLoadingTflite = false;
        _tfliteResult =
            '''
📊 AI Prediction Result
━━━━━━━━━━━━━━━━━━━━━━━━
Win Probability: ${winProbability.toPercentString()}

Engineering Summary:
• Runs Needed: ${state.runsLeft}
• Balls Left: ${state.ballsLeft}
• Required RR: ${state.reqRunRate.toStringAsFixed(2)}
• Pressure Index: ${state.pressure.toStringAsFixed(2)}
• Resource Score: ${state.resourceScore.toStringAsFixed(1)}
• Venue Par Diff: ${state.venueParDiff.toInt()}
''';
      });
    } catch (e) {
      setState(() {
        _isLoadingTflite = false;
        _tfliteResult = '❌ Inference Error: $e';
      });
    }
  }

  /// Run ONNX model prediction
  Future<void> _predictWithOnnx() async {
    if (!_onnxModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ONNX model still loading... please wait.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingOnnx = true;
      _onnxResult = null;
    });

    try {
      final state = _getMatchState();

      // Get features from MatchState (same as TFLite)
      final features = state.toFeatureVector();

      // Run actual ONNX inference
      final winProbability = await _onnxPredictor.predict(features);

      setState(() {
        _isLoadingOnnx = false;
        _onnxResult =
            '''
📊 ONNX AI Prediction Result
━━━━━━━━━━━━━━━━━━━━━━━━
Win Probability: ${winProbability.clamp(0.0, 1.0).toPercentString()}

Engineering Summary:
• Runs Needed: ${state.runsLeft}
• Balls Left: ${state.ballsLeft}
• Required RR: ${state.reqRunRate.toStringAsFixed(2)}
• Pressure Index: ${state.pressure.toStringAsFixed(2)}
• Resource Score: ${state.resourceScore.toStringAsFixed(1)}
• Venue Par Diff: ${state.venueParDiff.toInt()}
''';
      });
    } catch (e) {
      setState(() {
        _isLoadingOnnx = false;
        _onnxResult = '❌ ONNX Inference Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Model',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter match parameters to predict win probability using ML models.',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Fields Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match Parameters',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Two-column layout using rows
                    _buildInputRow(
                      context,
                      leftLabel: 'Total Target',
                      leftController: _totalTargetController,
                      leftHint: 'e.g., 150',
                      rightLabel: 'Runs Scored',
                      rightController: _runsScoredController,
                      rightHint: 'e.g., 24',
                    ),
                    const SizedBox(height: 12),
                    _buildInputRow(
                      context,
                      leftLabel: 'Balls Bowled',
                      leftController: _ballsBowledController,
                      leftHint: 'e.g., 12',
                      rightLabel: 'Wickets Fallen',
                      rightController: _wicketsFallenController,
                      rightHint: 'e.g., 1',
                    ),
                    const SizedBox(height: 12),
                    _buildInputRow(
                      context,
                      leftLabel: 'Runs (Last 12 Balls)',
                      leftController: _runsLast12Controller,
                      leftHint: 'e.g., 12',
                      rightLabel: 'Wkts (Last 18 Balls)',
                      rightController: _wicketsLast18Controller,
                      rightHint: 'e.g., 0',
                    ),
                    const SizedBox(height: 12),
                    // Venue Avg - single field
                    _buildInputField(
                      context,
                      label: 'Venue Average Target',
                      controller: _venueAvgController,
                      hint: 'Historical average target score',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prediction Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run Prediction',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingTflite
                                ? null
                                : _predictWithTflite,
                            icon: _isLoadingTflite
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.memory),
                            label: const Text('TFLite'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingOnnx ? null : _predictWithOnnx,
                            icon: _isLoadingOnnx
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onSecondary,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('ONNX'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results Section
            if (_tfliteResult != null) ...[
              _buildResultCard(
                context,
                title: 'TFLite Result',
                result: _tfliteResult!,
                icon: Icons.memory,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
            ],
            if (_onnxResult != null) ...[
              _buildResultCard(
                context,
                title: 'ONNX Result',
                result: _onnxResult!,
                icon: Icons.auto_awesome,
                color: colorScheme.secondary,
              ),
            ],

            // Bottom padding for scrolling
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(
    BuildContext context, {
    required String leftLabel,
    required TextEditingController leftController,
    required String leftHint,
    required String rightLabel,
    required TextEditingController rightController,
    required String rightHint,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            context,
            label: leftLabel,
            controller: leftController,
            hint: leftHint,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInputField(
            context,
            label: rightLabel,
            controller: rightController,
            hint: rightHint,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String result,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
