import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/providers/matches_provider.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/screens/enhanced_match_details_screen.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/utils/match_converters.dart';

class EnhancedMatchesScreen extends ConsumerStatefulWidget {
  const EnhancedMatchesScreen({super.key});

  @override
  ConsumerState<EnhancedMatchesScreen> createState() =>
      _EnhancedMatchesScreenState();
}

class _EnhancedMatchesScreenState extends ConsumerState<EnhancedMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const TestApiScreen()),
      //     );
      //   },
      //   child: const Icon(Icons.bug_report),
      //   tooltip: 'Test API Connection',
      // ),
      body: Column(
        children: [
          // Connection Status
          _buildConnectionStatus(),

          // Tab Bar
          _buildTabBar(),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveMatchesTab(),
                _buildCompletedMatchesTab(),
                _buildDetailedScoresTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final connectionAsync = ref.watch(apiConnectionTestProvider);

    return connectionAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red[100],
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 16),
                const SizedBox(width: 8),
                Text(
                  'API connection failed. Make sure your cricket API is running on localhost:8000',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
            ),
          );
        }
        return Container();
      },
      loading: () => Container(),
      error: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.red[100],
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700], size: 16),
            const SizedBox(width: 8),
            Text(
              'Cannot connect to cricket API',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(icon: Icon(Icons.live_tv), text: 'Live Matches'),
          Tab(icon: Icon(Icons.history), text: 'Completed'),
          Tab(icon: Icon(Icons.analytics), text: 'Detailed Scores'),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesTab() {
    final matchesAsync = ref.watch(matchesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchesProvider);
      },
      child: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmptyState(
              icon: Icons.sports_cricket,
              title: 'No Live Matches',
              subtitle:
                  'Pull to refresh or check if your API is running on localhost:8000',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildLiveMatchCard(match);
            },
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Loading matches from your API...'),
              SizedBox(height: 8),
              Text('Make sure localhost:8000 is running'),
            ],
          ),
        ),
        error: (error, _) => _buildErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(matchesProvider),
        ),
      ),
    );
  }

  Widget _buildCompletedMatchesTab() {
    final completedMatchesAsync = ref.watch(completedMatchesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(completedMatchesProvider);
      },
      child: completedMatchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history,
              title: 'No Completed Matches',
              subtitle: 'Pull to refresh',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildCompletedMatchCard(match);
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => _buildErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(completedMatchesProvider),
        ),
      ),
    );
  }

  Widget _buildDetailedScoresTab() {
    final detailedScoresAsync = ref.watch(detailedLiveScoresProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(detailedLiveScoresProvider);
      },
      child: detailedScoresAsync.when(
        data: (scores) {
          if (scores.isEmpty) {
            return _buildEmptyState(
              icon: Icons.analytics,
              title: 'No Detailed Scores',
              subtitle: 'Pull to refresh',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final score = scores[index];
              return _buildDetailedScoreCard(score);
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => _buildErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(detailedLiveScoresProvider),
        ),
      ),
    );
  }

  Widget _buildLiveMatchCard(MatchEntity match) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.transparent, width: 0),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showMatchDetails(match),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match title
              Text(
                match.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Teams
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.teams.join(' vs '),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Match type and date
              Row(
                children: [
                  Icon(
                    Icons.sports_cricket,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.matchType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (match.dateTimeGMT.isNotEmpty) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      match.dateTimeGMT,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMatchCard(CompletedMatchEntity match) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.transparent, width: 0),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showMatchResult(match.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match title
              Text(
                match.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Result
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.result,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Teams and scores
              if (match.scores.isNotEmpty) ...[
                ...match.scores.map(
                  (score) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          score,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Date and match type
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.date.isNotEmpty ? match.date : 'Date not available',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.sports_cricket,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.matchType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedScoreCard(DetailedLiveScoreEntity score) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.transparent, width: 0),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match title
            Text(
              score.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Live score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                score.liveScore,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Run rate
            if (score.runRate.isNotEmpty &&
                score.runRate != 'Rate not available') ...[
              Text(
                score.runRate,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
            ],

            // Current batsmen
            if (score.batsman1Name.isNotEmpty &&
                score.batsman1Name != 'Unknown') ...[
              Text(
                'Current Batsmen:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${score.batsman1Name}: ${score.batsman1Runs}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${score.batsman2Name}: ${score.batsman2Runs}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Current bowlers
            if (score.bowler1.isNotEmpty && score.bowler1 != 'Unknown') ...[
              Text(
                'Current Bowlers:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      score.bowler1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      score.bowler2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.contains('localhost') || error.contains('connection')
                  ? 'Make sure your cricket API is running on localhost:8000'
                  : error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('live')) {
      return Colors.red;
    } else if (status.toLowerCase().contains('complete')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('upcoming')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  void _showMatchDetails(MatchEntity match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EnhancedMatchDetailsScreen(match: match.toCricketMatch()),
      ),
    );
  }

  void _showMatchResult(String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchResultScreen(matchId: matchId),
      ),
    );
  }
}

// Placeholder screen for match results while legacy flow is phased out
class MatchResultScreen extends ConsumerWidget {
  final String matchId;

  const MatchResultScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchResultAsync = ref.watch(matchResultProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Match Result')),
      body: matchResultAsync.when(
        data: (result) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match title
                Text(
                  result.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Result
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.result,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Innings scores
                if (result.inningsScores.isNotEmpty) ...[
                  Text(
                    'Innings Scores:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.inningsScores.map(
                    (innings) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              innings.team,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              innings.score,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Match details
                Text(
                  'Match Details:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(context, 'Date:', result.date),
                        _buildDetailRow(context, 'Venue:', result.venue),
                        _buildDetailRow(context, 'Format:', result.format),
                        _buildDetailRow(context, 'Toss:', result.toss),
                        _buildDetailRow(
                          context,
                          'Man of Match:',
                          result.manOfMatch,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load match result',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(matchResultProvider(matchId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty || value == 'not available'
                  ? 'Not available'
                  : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
