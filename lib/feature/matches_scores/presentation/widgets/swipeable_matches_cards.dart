import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match_entity.dart';
import '../providers/matches_provider.dart';
import '../screens/enhanced_match_details_screen.dart';
import '../utils/match_converters.dart';
import 'package:world_of_cricket/core/utils/team_abbreviation.dart';

class SwipeableMatchCards extends ConsumerWidget {
  const SwipeableMatchCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try the enhanced matches provider, but fall back to the older provider
    // if the enhanced provider fails.
    final AsyncValue<List<MatchEntity>> enhancedAsync = ref.watch(
      enhancedMatchesProvider,
    );
    final AsyncValue<List<MatchEntity>> fallbackAsync = ref.watch(
      matchesProvider,
    );

    // Prefer enhanced provider when it has data; fall back to older provider
    // while enhanced is loading or errors.
    final AsyncValue<List<MatchEntity>> matchesAsync = enhancedAsync.maybeWhen(
      data: (d) => AsyncValue.data(d),
      orElse: () => fallbackAsync,
    );

    return matchesAsync.when(
      data: (allMatches) {
        // Filter for live matches using the extension method for consistency
        final liveMatches = allMatches.where((match) => match.isLive).toList();

        print('🏏 Total matches loaded: ${allMatches.length}');
        print('🔴 Live matches filtered: ${liveMatches.length}');
        for (var match in liveMatches) {
          print('  - ${match.name}: ${match.status}');
        }

        if (liveMatches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_cricket,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No live matches available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total matches loaded: ${allMatches.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Live Matches",
                    style: TextStyle(
                      fontSize: _getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${liveMatches.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _getMatchCardHeight(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: liveMatches.length,
                itemBuilder: (context, index) {
                  final match = liveMatches[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: MatchCard(match: match),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load matches',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Invalidate both providers to force a refresh
                ref.invalidate(enhancedMatchesProvider);
                ref.invalidate(matchesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  double _getMatchCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Desktop mode (> 1200px)
    if (screenWidth > 1200) {
      return 100;
    }
    // Tablet mode (600px - 1200px)
    else if (screenWidth > 600) {
      return 110;
    }
    // Mobile mode (< 600px)
    else {
      return 120;
    }
  }

  double _getTitleFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Desktop mode (> 1200px)
    if (screenWidth > 1200) {
      return 22;
    }
    // Tablet mode (600px - 1200px)
    else if (screenWidth > 600) {
      return 23;
    }
    // Mobile mode (< 600px)
    else {
      return 24;
    }
  }
}

class MatchCard extends StatelessWidget {
  final MatchEntity match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = _getCardWidth(screenWidth);
    final isCompact = screenWidth > 600;

    return SizedBox(
      width: cardWidth,
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        openElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        openBuilder: (context, _) =>
            EnhancedMatchDetailsScreen(match: match.toCricketMatch()),
        closedBuilder: (context, openContainer) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Teams Row
              if (match.teams.length >= 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _getTeamAbbreviation(match.teams[0]),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isCompact ? 15 : 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Text(
                      'vs',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.8),
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Flexible(
                      child: Text(
                        _getTeamAbbreviation(match.teams[1]),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isCompact ? 15 : 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  match.name.isNotEmpty ? match.name : "Match Details",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],

              // Score Information
              if (match.liveScore != null && match.liveScore!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    match.liveScore!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                // Show placeholder for score when not available
                Text(
                  'Score: TBD',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],

              // Series Information
              if (match.series != null && match.series!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    match.series!,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: isCompact ? 9 : 10,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Match Type
              if (match.matchType.isNotEmpty) ...[
                Text(
                  match.matchType,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: isCompact ? 9 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 12,
                  vertical: isCompact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLive(match.status)) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        _getDisplayStatus(match.status),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1200) {
      return 240;
    } else if (screenWidth > 600) {
      return 260;
    } else {
      return 280;
    }
  }

  bool _isLive(String status) {
    final s = status.toLowerCase();
    return s == 'live' || s == 'in progress';
  }

  String _getDisplayStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'live' || s == 'in progress') return 'LIVE';
    if (s == 'completed' || s == 'finished') return 'COMPLETED';
    if (s == 'upcoming' || s == 'scheduled') return 'UPCOMING';
    return status.toUpperCase();
  }

  String _getTeamAbbreviation(String teamName) {
    return TeamAbbreviation.name(teamName);
  }
}
