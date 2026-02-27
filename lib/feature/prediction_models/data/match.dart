import 'dart:math' as math;

/// Represents the current state of a cricket match delivery by delivery
class MatchState {
  final int targetRuns;
  final int runsScored;
  final int ballsBowled;
  final int wicketsFallen; // Current wickets lost (0-10)
  final double venueAvgTarget;
  final List<BallEvent> ballHistory;

  static const List<String> featureOrder = [
    'runs_left',
    'balls_left',
    'wickets_left',
    'cur_run_rate',
    'req_run_rate',
    'pressure',
    'resource_score',
    'rr_ratio',
    'runs_last_12',
    'wickets_last_18',
    'venue_par_diff',
  ];

  MatchState({
    required this.targetRuns,
    required this.runsScored,
    required this.ballsBowled,
    required this.wicketsFallen,
    required this.venueAvgTarget,
    required this.ballHistory,
  });

  // Derived features for prediction
  int get runsLeft => (targetRuns - runsScored).clamp(0, 999);
  int get ballsLeft => (120 - ballsBowled).clamp(0, 120);
  int get wicketsLeft => 10 - wicketsFallen;

  double get curRunRate =>
      ballsBowled > 0 ? (runsScored / ballsBowled) * 6 : 0.0;
  double get reqRunRate =>
      ballsLeft > 0 ? (runsLeft / (ballsLeft / 6.0)) : 999.0;
  double get pressure => reqRunRate - curRunRate;

  /// Resource score: (wickets_fallen^1.5) * (balls_left^0.5)
  double get resourceScore =>
      math.pow(wicketsFallen.toDouble(), 1.5) *
      math.pow(ballsLeft.toDouble(), 0.5).toDouble();

  double get rrRatio => reqRunRate / (curRunRate + 0.5);

  double get runsLast12 {
    final last12 = ballHistory.length >= 12
        ? ballHistory.sublist(ballHistory.length - 12)
        : ballHistory;
    return last12.fold<double>(0, (sum, b) => sum + b.runs);
  }

  double get wicketsLast18 {
    final last18 = ballHistory.length >= 18
        ? ballHistory.sublist(ballHistory.length - 18)
        : ballHistory;
    // Model expects a negative value for wicket momentum in some notebook versions
    final count = last18.where((b) => b.isWicket).length;
    return -count.toDouble();
  }

  double get venueParDiff => targetRuns - venueAvgTarget;

  /// Returns the features in the exact order required by the TFLite model
  List<double> toFeatureVector() => [
    runsLeft.toDouble(), // 0. runs_left
    ballsLeft.toDouble(), // 1. balls_left
    wicketsFallen.toDouble(), // 2. wickets_left (fallen)
    curRunRate, // 3. cur_run_rate
    reqRunRate, // 4. req_run_rate
    pressure, // 5. pressure
    resourceScore, // 6. resource_score
    rrRatio, // 7. rr_ratio
    runsLast12, // 8. runs_last_12
    wicketsLast18, // 9. wickets_last_18
    venueParDiff, // 10. venue_par_diff
  ];

  @override
  String toString() {
    return '''
MatchState:
  Target: $targetRuns | Scored: $runsScored | Need: $runsLeft from $ballsLeft balls
  Wickets Fallen: $wicketsFallen/10 | CRR: ${curRunRate.toStringAsFixed(2)} | RRR: ${reqRunRate.toStringAsFixed(2)}
  Pressure: ${pressure.toStringAsFixed(2)} | Resource: ${resourceScore.toStringAsFixed(2)}
  Momentum: ${runsLast12.toStringAsFixed(0)} runs/12 balls | ${wicketsLast18.abs().toInt()} wkts/18 balls
''';
  }
}

/// Represents a single ball delivery
class BallEvent {
  final int runs; // Runs scored off this ball (0, 1, 2, 3, 4, 6)
  final bool isWicket; // Whether a wicket fell
  final bool isExtra; // Wide, no-ball, etc.

  BallEvent({required this.runs, this.isWicket = false, this.isExtra = false});
}

/// Extension for easy probability display
extension ProbabilityDisplay on double {
  String toPercentString() => '${(this * 100).toStringAsFixed(1)}%';
}
