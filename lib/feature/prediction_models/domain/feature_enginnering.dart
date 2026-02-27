// in this file we will find out additional features needed these are
// runs_left , balls_left ,wickets_left ,cur_run_rate ,req_run_rate  are already given
// | Index | Feature Name | Formula / Description |
// | :--- | :--- | :--- |
// | 0 | `runs_left` | `target - runsScored` |
// | 1 | `balls_left` | `120 - ballsBowled` |
// | 2 | `wickets_left` | **Wickets Fallen** (0 to 10) |
// | 3 | `cur_run_rate` | `(runsScored / ballsBowled) * 6` |
// | 4 | `req_run_rate` | `runsLeft / (ballsLeft / 6)` |
// | 5 | `pressure` | `req_run_rate - cur_run_rate` |
// | 6 | `resource_score`| `(wicketsFallen^1.5) * (ballsLeft^0.5)` |
// | 7 | `rr_ratio` | `reqRunRate / (curRunRate + 0.5)` |
// | 8 | `runs_last_12` | Sum of runs in the last 12 balls |
// | 9 | `wickets_last_18`| `-(wickets fallen in last 18 balls)` |
// | 10 | `venue_par_diff`| `targetRuns - venueAverageTarget` |

import 'dart:math';

/// Handles the calculation of features required for the Cricket Prediction Models.
/// These features are based on the training dataset requirements.
class FeatureEngineering {
  final double target;
  final double runsScored;
  final double ballsBowled;
  final double wicketsFallen;
  final double venueAverageTarget;

  // Historical context features
  final double runsLast12Balls;
  final double wicketsLast18Balls;

  FeatureEngineering({
    required this.target,
    required this.runsScored,
    required this.ballsBowled,
    required this.wicketsFallen,
    required this.venueAverageTarget,
    this.runsLast12Balls = 0,
    this.wicketsLast18Balls = 0,
  });

  // 0. runs_left
  double get runsLeft => target - runsScored;

  // 1. balls_left
  double get ballsLeft => 120 - ballsBowled;

  // 2. wickets_left (Formula says Wickets Fallen)
  double get wicketsLeftValue => wicketsFallen;

  // 3. cur_run_rate
  double get curRunRate => ballsBowled > 0 ? (runsScored / ballsBowled) * 6 : 0;

  // 4. req_run_rate
  double get reqRunRate => (ballsLeft > 0) ? (runsLeft / (ballsLeft / 6)) : 0;

  // 5. pressure
  double get pressure => reqRunRate - curRunRate;

  // 6. resource_score
  double get resourceScore =>
      pow(wicketsFallen, 1.5) * pow(max(0, ballsLeft), 0.5) as double;

  // 7. rr_ratio
  double get rrRatio => reqRunRate / (curRunRate + 0.5);

  // 8. runs_last_12 (already provided)

  // 9. wickets_last_18 (Table says: -(wickets fallen in last 18 balls))
  double get wicketsLast18Negated => -wicketsLast18Balls;

  // 10. venue_par_diff
  double get venueParDiff => target - venueAverageTarget;

  /// Returns the features as a List<double> in the exact order expected by the model.
  List<double> toFeatureVector() {
    return [
      runsLeft, // 0
      ballsLeft, // 1
      wicketsLeftValue, // 2
      curRunRate, // 3
      reqRunRate, // 4
      pressure, // 5
      resourceScore, // 6
      rrRatio, // 7
      runsLast12Balls, // 8
      wicketsLast18Negated, // 9
      venueParDiff, // 10
    ];
  }

  @override
  String toString() {
    return '''
    --- Feature Engineering Summary ---
    Runs Left: $runsLeft
    Balls Left: $ballsLeft
    Wickets Fallen: $wicketsFallen
    CRR: ${curRunRate.toStringAsFixed(2)}
    RRR: ${reqRunRate.toStringAsFixed(2)}
    Pressure: ${pressure.toStringAsFixed(2)}
    Resource Score: ${resourceScore.toStringAsFixed(2)}
    RR Ratio: ${rrRatio.toStringAsFixed(2)}
    Venue Par Diff: $venueParDiff
    ---------------------------------
    ''';
  }
}
