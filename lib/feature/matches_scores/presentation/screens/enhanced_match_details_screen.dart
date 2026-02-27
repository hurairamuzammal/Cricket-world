import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:world_of_cricket/core/services/cricket_api_service.dart';

import 'package:world_of_cricket/core/utils/team_abbreviation.dart';

import '../../../../core/models/cricket_models.dart';

class EnhancedMatchDetailsScreen extends StatefulWidget {
  final CricketMatch match;

  const EnhancedMatchDetailsScreen({super.key, required this.match});

  @override
  State<EnhancedMatchDetailsScreen> createState() =>
      _EnhancedMatchDetailsScreenState();
}

class _EnhancedMatchDetailsScreenState
    extends State<EnhancedMatchDetailsScreen> {
  final CricketApiService _apiService = CricketApiService();
  CricketMatch? _detailedMatch;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetailedMatchInfo();
  }

  Future<void> _loadDetailedMatchInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detailedMatch = await _apiService.getDetailedMatchInfo(
        widget.match.id,
      );
      if (!mounted) return;
      setState(() {
        _detailedMatch = detailedMatch.copyWith(teams: widget.match.teams);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _detailedMatch ??= widget.match;
      });
    }
  }

  Future<void> _refreshMatch() async {
    await _loadDetailedMatchInfo();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final match = _detailedMatch ?? widget.match;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button and header - always visible at top
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 56,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: _MatchOverviewCard(
                    match: match,
                    teams: _DetailsBody.resolveTeams(match),
                  ),
                ),
                // Back button overlay - always visible
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.8),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Scrollable content below
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMatch,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (_isLoading && _detailedMatch == null)
                      const _LoadingPlaceholder()
                    else
                      _DetailsBodyContent(
                        match: match,
                        isRefreshing: _isLoading,
                        errorMessage: _error,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final CricketMatch match;
  final bool isRefreshing;
  final String? errorMessage;

  const _DetailsBody({
    required this.match,
    required this.isRefreshing,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final liveInsights = _liveInsights(match);
    final keyFacts = _keyFacts(match);
    final batters = _currentBatters(match);
    final bowler = match.details?.currentBowler;
    final overs = match.details?.recentOvers ?? const <String>[];
    final links = _links(match);

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              if (isRefreshing)
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _SubtleLoader(),
                  ),
                ),
              if (errorMessage != null)
                _AnimatedSection(
                  delay: Duration.zero,
                  child: _ErrorNotice(message: errorMessage!),
                ),
              if (liveInsights.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 140),
                  child: _InsightSection(insights: liveInsights),
                ),
              ],
              if (batters.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 190),
                  child: _CurrentBattersSection(batters: batters),
                ),
              ],
              if (bowler != null) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 240),
                  child: _BowlerSection(bowler: bowler),
                ),
              ],
              if (overs.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 280),
                  child: _RecentOversSection(overs: overs.take(6).toList()),
                ),
              ],
              if (keyFacts.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 320),
                  child: _KeyFactsSection(facts: keyFacts),
                ),
              ],
              if (links.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AnimatedSection(
                  delay: const Duration(milliseconds: 360),
                  child: _LinksSection(links: links),
                ),
              ],
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
              Align(
                child: Text(
                  match.details?.result ??
                      match.enhancedInfo?.formattedResult ??
                      match.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  static List<_ResolvedTeam> resolveTeams(CricketMatch match) {
    final resolved = <_ResolvedTeam>[];

    void addOrUpdate(String name, {String score = '', String overs = ''}) {
      final cleanedName = _cleanValue(name);
      if (cleanedName.isEmpty) return;
      final sanitizedScore = _cleanValue(score);
      final sanitizedOvers = _sanitizeOvers(overs);
      final index = resolved.indexWhere(
        (team) => team.name.toLowerCase() == cleanedName.toLowerCase(),
      );
      if (index != -1) {
        // Only update if the new data is more complete
        final existing = resolved[index];
        resolved[index] = existing.copyWith(
          score: sanitizedScore.isNotEmpty ? sanitizedScore : existing.score,
          overs: sanitizedOvers.isNotEmpty ? sanitizedOvers : existing.overs,
        );
      } else {
        resolved.add(
          _ResolvedTeam(
            name: cleanedName,
            abbreviation: TeamAbbreviation.name(cleanedName),
            score: sanitizedScore,
            overs: sanitizedOvers,
          ),
        );
      }
    }

    for (final team in match.teams) {
      final score = _composeScore(team);
      addOrUpdate(team.name, score: score, overs: team.overs);
    }

    final descriptiveSources = <String?>[
      match.enhancedInfo?.originalDescription,
      match.status,
      match.details?.result,
    ];

    for (final source in descriptiveSources) {
      for (final snippet in _parseScoreSnippets(source)) {
        addOrUpdate(snippet.name, score: snippet.score, overs: snippet.overs);
      }
    }

    if (resolved.length < 2) {
      final titleSources = <String?>[
        match.title,
        match.enhancedInfo?.originalTitle,
        match.series,
        match.status,
      ];
      for (final source in titleSources) {
        for (final name in _extractTeamNames(source)) {
          addOrUpdate(name);
        }
      }
    }

    if (resolved.isEmpty) {
      addOrUpdate('Team 1');
      addOrUpdate('Team 2');
    } else if (resolved.length == 1) {
      addOrUpdate('Opponent');
    }

    return resolved;
  }

  static List<_ScoreLine> _scoreEntries(List<_ResolvedTeam> teams) {
    final entries = <_ScoreLine>[];
    for (final team in teams) {
      if (!team.hasData) continue;
      entries.add(
        _ScoreLine(
          team: team.abbreviation,
          score: team.score,
          overs: team.oversLabel,
        ),
      );
    }
    return entries;
  }

  static Map<String, String> _liveInsights(CricketMatch match) {
    final map = <String, String>{};
    final details = match.details;

    void add(String label, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '-') return;
      map[label] = trimmed;
    }

    add('Match status', match.status);
    add('Series', match.series);
    add('Partnership', details?.currentPartnership);
    add('Target', details?.targetInfo);

    for (final team in match.teams) {
      if (team.runRate.isNotEmpty) {
        map['${TeamAbbreviation.name(team.name)} RR'] = team.runRate;
      }
    }

    return map;
  }

  static Map<String, String> _keyFacts(CricketMatch match) {
    final map = <String, String>{};
    final info = match.enhancedInfo;

    void add(String label, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '-') return;
      map[label] = trimmed;
    }

    add('Format', match.matchType);
    add('Venue', match.venue.isNotEmpty ? match.venue : info?.formattedVenue);
    add('Updated', _relativeTime(match.lastUpdated));
    add('Source', match.source);
    add('Toss', info?.formattedToss ?? match.details?.toss);
    add('Day/Night', info?.dayNight);
    add('Match date', info?.matchDate);
    add('Match time', info?.matchTime);
    add('Quality score', info?.qualityScore?.toStringAsFixed(1));

    return map;
  }

  static List<_BatterLine> _currentBatters(CricketMatch match) {
    final details = match.details;
    if (details == null || details.currentBatsmen.isEmpty) return const [];
    return details.currentBatsmen
        .map(
          (batter) => _BatterLine(
            name: batter.name,
            score: '${batter.runs} (${batter.balls})',
            strikeRate: batter.strikeRate.toStringAsFixed(1),
            fours: batter.fours,
            sixes: batter.sixes,
          ),
        )
        .toList();
  }

  static Map<String, String> _links(CricketMatch match) {
    final links = <String, String>{};
    if (match.url.trim().isNotEmpty) {
      links['Open match centre'] = match.url.trim();
    }
    return links;
  }

  static String _composeScore(TeamData team) {
    final rawScore = team.score.trim();
    final rawWickets = team.wickets.trim();
    final score = _cleanValue(rawScore);
    final wickets = _cleanValue(rawWickets);

    if (score.isEmpty && wickets.isEmpty) return '';
    if (score.contains('/') || score.contains('-')) return score;
    if (wickets.isEmpty) return score;
    if (wickets.toLowerCase() == 'all out') {
      return score.isEmpty ? 'All out' : '$score all out';
    }
    return '$score/$wickets';
  }

  static Iterable<_ScoreSnippet> _parseScoreSnippets(String? source) {
    if (source == null) return const <_ScoreSnippet>[];
    final normalized = source.replaceAll('\n', ' ');
    final regex = RegExp(
      r'([A-Za-z&\s\.\-\(\)]+?)\s+(\d+(?:\/|\-)?\d*)(?:\s*\(([^\)]+)\))?',
    );

    return regex
        .allMatches(normalized)
        .map((match) {
          final name = _cleanValue(match.group(1) ?? '');
          final score = _cleanValue(match.group(2) ?? '');
          final overs = _sanitizeOvers(match.group(3));
          return _ScoreSnippet(name: name, score: score, overs: overs);
        })
        .where(
          (snippet) => snippet.name.isNotEmpty && snippet.score.isNotEmpty,
        );
  }

  static Iterable<String> _extractTeamNames(String? source) {
    if (source == null) return const <String>[];
    final text = source.replaceAll(RegExp(r'[\n\r]+'), ' ');
    final matches = <String>{};

    final versusRegex = RegExp(
      r'([A-Za-z&\s\.\-]+?)\s+(?:vs\.?|v\.?|versus)\s+([A-Za-z&\s\.\-]+)',
      caseSensitive: false,
    );

    for (final match in versusRegex.allMatches(text)) {
      matches
        ..add(_cleanValue(match.group(1) ?? ''))
        ..add(_cleanValue(match.group(2) ?? ''));
    }

    if (matches.isNotEmpty) {
      return matches.where((name) => name.isNotEmpty);
    }

    final possibleNames = text.split(RegExp(r'[,&/]'));
    return possibleNames
        .map(_cleanValue)
        .where((name) => name.isNotEmpty && name.length > 2);
  }

  static String _sanitizeOvers(String? raw) {
    if (raw == null) return '';
    final cleaned = raw
        .replaceAll(
          RegExp(r'(overs?|ovs?|ov\.?|\s+ov\s*)', caseSensitive: false),
          '',
        )
        .trim();
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9\.]'), '');
    return digitsOnly.trim();
  }

  static String _cleanValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase() == 'tbd' || trimmed.toLowerCase() == 'null') {
      return '';
    }
    return trimmed;
  }
}

class _DetailsBodyContent extends StatelessWidget {
  final CricketMatch match;
  final bool isRefreshing;
  final String? errorMessage;

  const _DetailsBodyContent({
    required this.match,
    required this.isRefreshing,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final liveInsights = _DetailsBody._liveInsights(match);
    final keyFacts = _DetailsBody._keyFacts(match);
    final batters = _DetailsBody._currentBatters(match);
    final bowler = match.details?.currentBowler;
    final overs = match.details?.recentOvers ?? const <String>[];
    final links = _DetailsBody._links(match);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          if (isRefreshing)
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _SubtleLoader(),
              ),
            ),
          if (errorMessage != null)
            _AnimatedSection(
              delay: Duration.zero,
              child: _ErrorNotice(message: errorMessage!),
            ),
          if (liveInsights.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 140),
              child: _InsightSection(insights: liveInsights),
            ),
          ],
          if (batters.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 190),
              child: _CurrentBattersSection(batters: batters),
            ),
          ],
          if (bowler != null) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 240),
              child: _BowlerSection(bowler: bowler),
            ),
          ],
          if (overs.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 280),
              child: _RecentOversSection(overs: overs.take(6).toList()),
            ),
          ],
          if (keyFacts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 320),
              child: _KeyFactsSection(facts: keyFacts),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnimatedSection(
              delay: const Duration(milliseconds: 360),
              child: _LinksSection(links: links),
            ),
          ],
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          Align(
            child: Text(
              match.details?.result ??
                  match.enhancedInfo?.formattedResult ??
                  match.status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedTeam {
  final String name;
  final String abbreviation;
  final String score;
  final String overs;

  const _ResolvedTeam({
    required this.name,
    required this.abbreviation,
    required this.score,
    required this.overs,
  });

  _ResolvedTeam copyWith({String? score, String? overs}) {
    final nextScore = score != null && score.trim().isNotEmpty
        ? score.trim()
        : this.score;
    String nextOvers = this.overs;
    if (overs != null && overs.trim().isNotEmpty) {
      final candidate = _DetailsBody._sanitizeOvers(overs);
      if (candidate.isNotEmpty) {
        nextOvers = candidate;
      }
    }
    return _ResolvedTeam(
      name: name,
      abbreviation: abbreviation,
      score: nextScore,
      overs: nextOvers,
    );
  }

  bool get hasData => score.isNotEmpty || overs.isNotEmpty;

  String get oversLabel => overs;
}

class _ScoreSnippet {
  final String name;
  final String score;
  final String overs;

  const _ScoreSnippet({
    required this.name,
    required this.score,
    required this.overs,
  });
}

class _MatchOverviewCard extends StatelessWidget {
  final CricketMatch match;
  final List<_ResolvedTeam> teams;

  const _MatchOverviewCard({required this.match, required this.teams});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final teamsToDisplay = teams.take(2).toList();
    final statusLabel = match.status.trim().isEmpty
        ? (match.enhancedInfo?.formattedResult ?? match.liveStatus)
        : match.status;
    final tone = _statusTone(match.liveStatus);

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            TeamAbbreviation.title(match.title, teams: match.teams),
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleLarge,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          if (teamsToDisplay.isNotEmpty)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _TeamScoreDisplay(team: teamsToDisplay[0])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: VerticalDivider(width: 1),
                  ),
                  Expanded(
                    child: _TeamScoreDisplay(
                      team: teamsToDisplay.length > 1
                          ? teamsToDisplay[1]
                          : const _ResolvedTeam(
                              name: 'TBD',
                              abbreviation: 'TBD',
                              score: '',
                              overs: '',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (match.matchType.isNotEmpty)
                _Tag(label: match.matchType.toUpperCase()),
              _StatusBadge(label: statusLabel, tone: tone),
            ],
          ),
          if (match.series.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              match.series,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return _StatusTone.live;
      case 'upcoming':
        return _StatusTone.upcoming;
      default:
        return _StatusTone.completed;
    }
  }
}

class _TeamScoreDisplay extends StatelessWidget {
  final _ResolvedTeam team;

  const _TeamScoreDisplay({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team.abbreviation,
          style: GoogleFonts.poppins(
            textStyle: theme.textTheme.titleMedium,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          team.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Text(
          team.score,
          style: GoogleFonts.robotoMono(
            textStyle: theme.textTheme.headlineSmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (team.overs.isNotEmpty)
          Text(
            '(${team.overs} ov)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final List<_ScoreLine> entries;

  const _ScoreSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score summary',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (int i = 0; i < entries.length; i++)
                _ScoreRow(entry: entries[i], isLast: i == entries.length - 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final Map<String, String> insights;

  const _InsightSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live insights',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: insights.entries
                .map((entry) => _FactChip(label: entry.key, value: entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CurrentBattersSection extends StatelessWidget {
  final List<_BatterLine> batters;

  const _CurrentBattersSection({required this.batters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At the crease',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: batters
                .map((batter) => _BatterRow(batter: batter))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BowlerSection extends StatelessWidget {
  final BowlerData bowler;

  const _BowlerSection({required this.bowler});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bowling now',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  bowler.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _TinyPill(
                label:
                    '${bowler.overs}-${bowler.maidens}-${bowler.runs}-${bowler.wickets}',
                foreground: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _TinyPill(
                label: 'ECON ${bowler.economy.toStringAsFixed(2)}',
                foreground: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOversSection extends StatelessWidget {
  final List<String> overs;

  const _RecentOversSection({required this.overs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent overs',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: overs
                .map(
                  (over) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      over,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _KeyFactsSection extends StatelessWidget {
  final Map<String, String> facts;

  const _KeyFactsSection({required this.facts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key facts',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: facts.entries
                .map((entry) => _FactTile(label: entry.key, value: entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LinksSection extends StatelessWidget {
  final Map<String, String> links;

  const _LinksSection({required this.links});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More detail',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: links.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _LinkButton(label: entry.key, url: entry.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final _ScoreLine entry;
  final bool isLast;

  const _ScoreRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.team,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.score,
                style: GoogleFonts.robotoMono(
                  textStyle: theme.textTheme.titleMedium,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (entry.overs.isNotEmpty)
                Text(
                  '${entry.overs} ov',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatterRow extends StatelessWidget {
  final _BatterLine batter;

  const _BatterRow({required this.batter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            batter.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TinyPill(label: batter.score, foreground: colorScheme.primary),
              const SizedBox(width: 8),
              _TinyPill(
                label: 'SR ${batter.strikeRate}',
                foreground: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _TinyPill(
                label: '4s ${batter.fours}',
                foreground: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _TinyPill(
                label: '6s ${batter.sixes}',
                foreground: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final String label;
  final String value;

  const _FactChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final String label;
  final String value;

  const _FactTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final _StatusTone tone;

  const _StatusBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _palette(colorScheme, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ) ??
            TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
      ),
    );
  }

  _TonePalette _palette(ColorScheme scheme, _StatusTone tone) {
    switch (tone) {
      case _StatusTone.live:
        return _TonePalette(
          background: scheme.errorContainer.withOpacity(0.4),
          border: scheme.error.withOpacity(0.5),
          foreground: scheme.error,
        );
      case _StatusTone.upcoming:
        return _TonePalette(
          background: scheme.tertiaryContainer.withOpacity(0.4),
          border: scheme.tertiary.withOpacity(0.45),
          foreground: scheme.tertiary,
        );
      case _StatusTone.completed:
        return _TonePalette(
          background: scheme.secondaryContainer.withOpacity(0.4),
          border: scheme.secondary.withOpacity(0.45),
          foreground: scheme.secondary,
        );
    }
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;

  const _LinkButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(color: colorScheme.primary, width: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedSection({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }
}

class _SurfaceContainer extends StatelessWidget {
  final Widget child;

  const _SurfaceContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SurfaceContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live data is unavailable right now.',
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.titleMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _SubtleLoader extends StatelessWidget {
  const _SubtleLoader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 4,
      width: 96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          color: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final Color foreground;

  const _TinyPill({required this.label, required this.foreground});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          textStyle: Theme.of(context).textTheme.bodySmall,
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreLine {
  final String team;
  final String score;
  final String overs;

  const _ScoreLine({
    required this.team,
    required this.score,
    required this.overs,
  });
}

class _BatterLine {
  final String name;
  final String score;
  final String strikeRate;
  final String fours;
  final String sixes;

  const _BatterLine({
    required this.name,
    required this.score,
    required this.strikeRate,
    required this.fours,
    required this.sixes,
  });
}

enum _StatusTone { live, upcoming, completed }

class _TonePalette {
  final Color background;
  final Color border;
  final Color foreground;

  const _TonePalette({
    required this.background,
    required this.border,
    required this.foreground,
  });
}

String _relativeTime(String raw) {
  if (raw.isEmpty) return '';
  try {
    final parsed = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final diff = now.difference(parsed);
    if (diff.inMinutes.abs() < 1) return 'Just now';
    if (diff.inMinutes.abs() < 60) {
      final minutes = diff.inMinutes.abs();
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }
    if (diff.inHours.abs() < 24) {
      final hours = diff.inHours.abs();
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    final days = diff.inDays.abs();
    return days == 1 ? '1 day ago' : '$days days ago';
  } catch (_) {
    return raw;
  }
}
