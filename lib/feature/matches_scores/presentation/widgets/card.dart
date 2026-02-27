// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:world_of_cricket/core/utils/team_abbreviation.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/screens/enhanced_match_details_screen.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/utils/match_converters.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth > 600; // Compact layout for tablet/desktop

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      openShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      tappable: true,
      openBuilder: (context, _) =>
          EnhancedMatchDetailsScreen(match: match.toCricketMatch()),
      closedBuilder: (context, openContainer) => Container(
        margin: EdgeInsets.symmetric(vertical: isCompact ? 6 : 8),
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
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            children: [
              // Teams Row - IND vs ENG in one row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (match.teams.isNotEmpty) ...[
                    Text(
                      _getTeamAbbreviation(
                        match.teams.isNotEmpty ? match.teams[0] : 'Team 1',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Text(
                      'vs',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.8),
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Text(
                      _getTeamAbbreviation(
                        match.teams.length > 1 ? match.teams[1] : 'Team 2',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: isCompact ? 8 : 12),

              // Match Type
              Text(
                match.matchType,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: isCompact ? 8 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: isCompact ? 8 : 12),

              // Status and Score
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: isCompact ? 6 : 8,
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
                        width: isCompact ? 6 : 8,
                        height: isCompact ? 6 : 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.5),
                              blurRadius: isCompact ? 3 : 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isCompact ? 6 : 8),
                    ],
                    Text(
                      _getDisplayStatus(match.status),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.w600,
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

  bool _isLive(String status) {
    return status.toLowerCase() == 'live' ||
        status.toLowerCase() == 'in progress';
  }

  String _getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'in progress':
        return 'LIVE';
      case 'completed':
      case 'finished':
        return 'COMPLETED';
      case 'upcoming':
      case 'scheduled':
        return 'UPCOMING';
      default:
        return status.toUpperCase();
    }
  }

  String _getTeamAbbreviation(String teamName) {
    return TeamAbbreviation.name(teamName);
  }
}
