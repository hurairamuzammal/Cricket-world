import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';
import '../screens/enhanced_match_details_screen.dart';
import '../providers/cricket_matches_provider.dart';
import '../../../../core/models/cricket_models.dart';
import '../../../../core/services/cricket_api_service.dart';
import '../../../../core/utils/team_abbreviation.dart';

class SimpleMatchCards extends ConsumerWidget {
  const SimpleMatchCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔧 SimpleMatchCards: Starting build');

    // Use the same provider as the matches screen for consistency
    final allMatchesAsync = ref.watch(allMatchesProvider);

    return allMatchesAsync.when(
      data: (allMatches) {
        print('� Total matches from API service: ${allMatches.length}');

        if (allMatches.isEmpty) {
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
                  'No matches available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter matches into proper categories using match extension methods
        final liveMatches = <CricketMatch>[];
        final upcomingMatches = <CricketMatch>[];
        final recentMatches = <CricketMatch>[];

        for (var match in allMatches) {
          print('🔍 Match: ${match.title}');
          print(
            '   Status: "${match.status}" | LiveStatus: "${match.liveStatus}"',
          );

          if (match.isLive) {
            liveMatches.add(match);
            print('   🔴 Added to live matches');
          } else if (match.isUpcoming) {
            upcomingMatches.add(match);
            print('   ⏰ Added to upcoming matches');
          } else {
            recentMatches.add(match);
            print('   📋 Added to recent matches');
          }
        }

        print('🔴 Live matches found: ${liveMatches.length}');
        print('⏰ Upcoming matches found: ${upcomingMatches.length}');
        print('📋 Recent matches found: ${recentMatches.length}');

        // Determine what to display and with what title
        List<CricketMatch> displayMatches;
        String sectionTitle;

        if (liveMatches.isNotEmpty) {
          // Show live matches if available
          displayMatches = liveMatches;
          sectionTitle = "Live Matches";
        } else {
          // Show recent matches if no live matches
          displayMatches = recentMatches.take(5).toList();
          sectionTitle = "Recent Matches";
        }

        // Handle case when no live matches are available
        if (liveMatches.isEmpty && displayMatches.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Live Matches",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 140,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tv_off,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No live matches currently',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                    sectionTitle.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 30, // Increased from 24 to 30
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // if (liveMatches.isNotEmpty) ...[
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 4,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: Colors.red,
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     // child: Row(
                  //     //   mainAxisSize: MainAxisSize.min,
                  //     //   children: [
                  //     //     Container(
                  //     //       width: 8,
                  //     //       height: 8,
                  //     //       decoration: const BoxDecoration(
                  //     //         color: Colors.white,
                  //     //         shape: BoxShape.circle,
                  //     //       ),
                  //     //     ),
                  //     //     const SizedBox(width: 4),
                  //     //     const Text(
                  //     //       'LIVE',
                  //     //       style: TextStyle(
                  //     //         color: Colors.white,
                  //     //         fontSize: 12,
                  //     //         fontWeight: FontWeight.bold,
                  //     //       ),
                  //     //     ),
                  //     //   ],
                  //     // ),
                  //   ),
                  // ] else ...[
                  //   const SizedBox.shrink(),
                  // ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.width >= 800
                  ? 160
                  : 140, // Increased height for desktop/wide screens
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayMatches.length,
                itemBuilder: (context, index) {
                  final match = displayMatches[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SimpleMatchCard(match: match),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, stackTrace) {
        print('❌ Error in SimpleMatchCards: $error');
        return Center(
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
                'Error loading matches',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SimpleMatchCard extends StatelessWidget {
  final CricketMatch match;

  const SimpleMatchCard({super.key, required this.match});

  // Helper method to handle score display for upcoming matches
  String _getDisplayScore(String score) {
    if (score.isEmpty ||
        score.toLowerCase() == 'tbd' ||
        score.toLowerCase() == 'to be decided') {
      return match.isUpcoming ? '' : '-';
    }
    return score;
  }

  String _buildInfoText() {
    final ls = match.liveStatus.toLowerCase();
    if (ls == 'completed') {
      final result =
          match.details?.result ??
          match.enhancedInfo?.formattedResult ??
          match.status;
      return result.isNotEmpty ? result : 'Completed';
    }
    if (ls == 'upcoming') {
      final when = match.enhancedInfo?.formattedDateTime;
      if (when != null && when.trim().isNotEmpty) {
        return 'Starts $when';
      }
      return 'Upcoming';
    }
    if (ls == 'live') {
      // Prefer rich status if present
      return match.status.isNotEmpty ? match.status : 'Live';
    }
    return match.status;
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    return SizedBox(
      width: isWideScreen ? 320 : 280, // Wider cards for desktop screens
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        openElevation: 0,
        tappable: true,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        openBuilder: (context, _) => EnhancedMatchDetailsScreen(match: match),
        closedBuilder: (context, openContainer) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(
            isWideScreen ? 18 : 14,
          ), // Increased padding for desktop
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Title
              Text(
                TeamAbbreviation.title(match.title, teams: match.teams),
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: isWideScreen ? 18 : 16, // Larger font for desktop
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Teams and scores
              if (match.teams.isNotEmpty) ...[
                Column(
                  children: match.teams.take(2).map((team) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              TeamAbbreviation.name(team.name),
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getDisplayScore(team.score),
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Series
              if (match.series.isNotEmpty) ...[
                Text(
                  match.series,
                  style: GoogleFonts.poppins(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],

              // Info line (result/upcoming/live). No venues on cards.
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceTint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    _buildInfoText(),
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleMatchCardShimmer extends StatelessWidget {
  const SimpleMatchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
      highlightColor: colorScheme.surfaceVariant.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          width: isWideScreen ? 320 : 280,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.5),
            highlightColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.2),
            child: Container(
              height: 30,
              width: 200,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.of(context).size.width >= 800 ? 160 : 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return const SimpleMatchCardShimmer();
            },
          ),
        ),
      ],
    );
  }
}
