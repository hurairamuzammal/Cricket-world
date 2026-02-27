import '../models/cricket_models.dart';

/// Utility to abbreviate cricket team names consistently across the app.
///
/// Includes common international sides, women’s teams, domestic/state teams,
/// and a safe fallback that creates an acronym from the first letters.
class TeamAbbreviation {
  // Common cricket team abbreviations
  static const Map<String, String> _map = {
    // International (Men)
    'Australia': 'AUS',
    'India': 'IND',
    'England': 'ENG',
    'Pakistan': 'PAK',
    'South Africa': 'SA',
    'New Zealand': 'NZ',
    'West Indies': 'WI',
    'Sri Lanka': 'SL',
    'Bangladesh': 'BAN',
    'Afghanistan': 'AFG',

    // International (Women)
    'Australia Women': 'AW',
    'India Women': 'IW',
    'England Women': 'EW',
    'Pakistan Women': 'PW',
    'South Africa Women': 'SAW',
    'New Zealand Women': 'NZW',
    'West Indies Women': 'WIW',
    'Sri Lanka Women': 'SLW',
    'Bangladesh Women': 'BW',
    'Afghanistan Women': 'AW',

    // Associate (examples used in dataset)
    'Myanmar Women': 'MW',
    'Hong Kong Women': 'HKW',
    'China Women': 'CW',
    'Mongolia Women': 'MW',

    // Australian domestic/state
    'New South Wales': 'NSW',
    'South Australia': 'SA',
    'Queensland': 'QLD',
    'Victoria': 'VIC',
    'Western Australia': 'WA',
    'Tasmania': 'TAS',

    // Leagues/Clubs (examples)
    'Trinbago Knight Riders': 'TKR',
    'Saint Lucia Kings': 'SLK',
    'Hampshire': 'HAM',
    'Worcestershire': 'WOR',
  };

  /// Abbreviate a single team name. If the name is not in the known map,
  /// returns an acronym from the first letters of the first two words (or
  /// first three letters if a single word).
  static String name(String teamName) {
    final direct = _map[teamName];
    if (direct != null) return direct;

    final words = teamName
        .trim()
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) {
      return words.take(2).map((w) => w[0].toUpperCase()).join('');
    }
    return teamName.length > 3
        ? teamName.substring(0, 3).toUpperCase()
        : teamName.toUpperCase();
  }

  /// Abbreviate a full title by replacing known team names with their
  /// abbreviations. If [teams] are provided, they get priority for matching.
  static String title(String title, {List<TeamData>? teams}) {
    String result = title;

    // Replace from provided teams first (exact matches)
    if (teams != null) {
      for (final t in teams) {
        if (t.name.isEmpty) continue;
        final abbr = name(t.name);
        result = result.replaceAll(t.name, abbr);
      }
    }

    // Replace known map keys (best-effort, avoids double replacing if already abbr)
    _map.forEach((full, abbr) {
      if (result.contains(full)) {
        result = result.replaceAll(full, abbr);
      }
    });

    return result;
  }

  /// Convenience: format two teams as "AAA vs BBB" using abbreviations.
  static String teamsLine(List<TeamData> teams) {
    if (teams.length >= 2) {
      return '${name(teams[0].name)} vs ${name(teams[1].name)}';
    } else if (teams.isNotEmpty) {
      return name(teams[0].name);
    }
    return 'Unknown Teams';
  }
}
