import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/cricket_models.dart';
import '../../../../core/services/cricket_api_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/team_abbreviation.dart';
import '../providers/cricket_matches_provider.dart';
import 'enhanced_match_details_screen.dart';
import 'package:world_of_cricket/core/widgets/collapsing_sliver_app_bar.dart';
// import 'package:world_of_cricket/core/widgets/theme_settings_screen.dart';
import 'package:animations/animations.dart';

class RiverpodCricketMatchesScreen extends ConsumerStatefulWidget {
  final ThemeService? themeService; // Add theme service parameter

  const RiverpodCricketMatchesScreen({super.key, this.themeService});

  @override
  ConsumerState<RiverpodCricketMatchesScreen> createState() =>
      _RiverpodCricketMatchesScreenState();
}

class _RiverpodCricketMatchesScreenState
    extends ConsumerState<RiverpodCricketMatchesScreen>
    with AutomaticKeepAliveClientMixin<RiverpodCricketMatchesScreen> {
  String _selectedFilter = 'all';

  // Track which date groups are expanded (by date key)
  final Set<String> _expandedDateGroups = {};

  // Helper: use shared abbreviation util
  String _abbreviateTeamName(String teamName) =>
      TeamAbbreviation.name(teamName);

  // Helper method to handle score display for upcoming matches
  String _getDisplayScore(String score, bool isUpcoming) {
    if (score.isEmpty ||
        score.toLowerCase() == 'tbd' ||
        score.toLowerCase() == 'to be decided') {
      return isUpcoming ? '' : '-';
    }
    return score;
  }

  void _toggleDateGroup(String dateKey) {
    setState(() {
      if (_expandedDateGroups.contains(dateKey)) {
        _expandedDateGroups.remove(dateKey);
      } else {
        _expandedDateGroups.add(dateKey);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Expand "Today" by default
    _expandedDateGroups.add('Today');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start auto-refresh after the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoRefreshDataProvider);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshMatches() async {
    try {
      print('Refresh button clicked - starting refresh');
      await ref.read(matchRefreshProvider.notifier).refreshAllMatches();
      print('Refresh completed successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matches refreshed successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // void _navigateToSettings() {
  //   print('Settings button clicked');
  //   if (widget.themeService != null) {
  //     print('Navigating to settings screen');
  //     Navigator.of(context).push(
  //       MaterialPageRoute(
  //         builder: (context) =>
  //             ThemeSettingsScreen(themeService: widget.themeService!),
  //       ),
  //     );
  //   } else {
  //     print('ThemeService is null - cannot navigate to settings');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Settings not available'),
  //           duration: Duration(seconds: 2),
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   }
  // }

  // Removed Easter egg tap handler and counters as the status chip was removed.

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    // The grouped provider handles all filtering internally

    return Scaffold(
      // No appBar here to avoid double app bars with the root Scaffold.
      backgroundColor: theme.colorScheme.surface, // Match homescreen background
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Slightly taller to reduce header overflow on small screens
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: CollapsingSliverAppBar(
                // expandedHeight: 176,
                collapsedTitle: 'Matches',
                expandedTitle: const SizedBox.shrink(),
                expandedActions: [
                  // HeaderAction(
                  //   icon: Icons.refresh,
                  //   label: 'Refresh',
                  //   onTap: () => _refreshMatches(),
                  // ),
                  // if (widget.themeService != null)
                  //   HeaderAction(
                  //     icon: Icons.settings,
                  //     label: 'Settings',
                  //     onTap: () => _navigateToSettings(),
                  //   ),
                ],
              ),
            ),

            // add space here
            // Pinned simple filter dropdown to keep the UI minimal
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeaderDelegate(
                height: 64,
                child: Container(
                  // Blend with app background
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Flexible(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            dropdownColor: theme.colorScheme.surface,
                            iconEnabledColor: theme.colorScheme.onSurface,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'live',
                                child: Text('Live'),
                              ),
                              DropdownMenuItem(
                                value: 'upcoming',
                                child: Text('Upcoming'),
                              ),
                              DropdownMenuItem(
                                value: 'recent',
                                child: Text('Recent'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _selectedFilter = v;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            // Use the filtered and grouped provider
            final groupedMatchesAsync = ref.watch(
              filteredDateGroupedMatchesProvider(_selectedFilter),
            );

            return RefreshIndicator(
              onRefresh: _refreshMatches,
              child: CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  ..._buildGroupedMatchesSlivers(
                    context,
                    groupedMatchesAsync,
                    _selectedFilter,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildGroupedMatchesSlivers(
    BuildContext context,
    AsyncValue<Map<String, List<CricketMatch>>> groupedAsync,
    String type,
  ) {
    final theme = Theme.of(context);

    return groupedAsync.when(
      data: (groupedMatches) {
        if (groupedMatches.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyView(type),
            ),
          ];
        }

        // Use a single sliver list with expandable date groups
        return [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList.builder(
              itemCount: groupedMatches.length,
              itemBuilder: (context, groupIndex) {
                final dateKey = groupedMatches.keys.elementAt(groupIndex);
                final matches = groupedMatches[dateKey]!;
                final isExpanded = _expandedDateGroups.contains(dateKey);

                return _buildExpandableDateGroup(
                  context,
                  theme,
                  dateKey,
                  matches,
                  isExpanded,
                );
              },
            ),
          ),
        ];
      },
      loading: () => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 16),
                Text('Loading matches...'),
              ],
            ),
          ),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildErrorView(error, type),
        ),
      ],
    );
  }

  /// Builds an expandable date group with header and collapsible match list
  Widget _buildExpandableDateGroup(
    BuildContext context,
    ThemeData theme,
    String dateKey,
    List<CricketMatch> matches,
    bool isExpanded,
  ) {
    // Check if this group has live matches for visual emphasis
    final hasLiveMatches = matches.any((m) => m.isLive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clickable date header
        InkWell(
          onTap: () => _toggleDateGroup(dateKey),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Date icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasLiveMatches
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDateIcon(dateKey),
                    size: 20,
                    color: hasLiveMatches
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Date title and match count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateKey,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${matches.length} ${matches.length == 1 ? 'match' : 'matches'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (hasLiveMatches) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand/collapse arrow
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated collapsible match list with responsive grid
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive: 2 cards on mobile, 3 on tablet, 4 on desktop
                final width = constraints.maxWidth;
                int crossAxisCount = 2; // default mobile
                if (width >= 1200) {
                  crossAxisCount = 4;
                } else if (width >= 800) {
                  crossAxisCount = 3;
                } else if (width >= 500) {
                  crossAxisCount = 2;
                }

                final spacing = 12.0;
                final cardWidth =
                    (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                // final cardHeight = cardWidth * 0.7; // aspect ratio unused

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: matches.map((match) {
                    return SizedBox(
                      width: cardWidth,
                      // Removed fixed height to prevent overflow
                      // height: cardHeight.clamp(140.0, 200.0),
                      child: _buildMatchCard(match, isCompact: true),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  IconData _getDateIcon(String dateKey) {
    if (dateKey == 'Today') return Icons.today;
    if (dateKey == 'Tomorrow') return Icons.event;
    if (dateKey == 'Yesterday') return Icons.history;
    return Icons.calendar_today;
  }

  // _buildMatchesSlivers removed - replaced by _buildGroupedMatchesSlivers

  // _buildMatchesList removed in favor of sliver-based implementation.

  Widget _buildMatchCard(CricketMatch match, {bool isCompact = false}) {
    final theme = Theme.of(context);

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 4,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      openBuilder: (context, _) => EnhancedMatchDetailsScreen(match: match),
      closedBuilder: (context, openContainer) => Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        color: theme.colorScheme.primary, // Match the homescreen card color
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Match header
              Row(
                children: [
                  Icon(
                    _getStatusIcon(match.liveStatus),
                    color: _getStatusColor(match.liveStatus, context),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      match.title.isNotEmpty
                          ? TeamAbbreviation.title(
                              match.title,
                              teams: match.teams,
                            )
                          : TeamAbbreviation.teamsLine(match.teams),
                      style:
                          (isCompact
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme
                                    .colorScheme
                                    .onPrimary, // Match homescreen text color
                              ),
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.liveStatus == 'live') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(match.liveStatus, context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.circle,
                      color: _getStatusColor(match.liveStatus, context),
                      size: 8,
                    ),
                  ],
                ],
              ),

              // Series name
              if (match.series.isNotEmpty && !isCompact) ...[
                const SizedBox(height: 4),
                Text(
                  match.series,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(
                      0.8,
                    ), // Match homescreen style
                  ),
                ),
              ],

              SizedBox(height: isCompact ? 8 : 12),

              // Teams and scores
              if (match.teams.isNotEmpty) ...[
                if (isCompact) ...[
                  // Compact horizontal layout: "AUS 288 vs IND 157"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (match.teams.isNotEmpty) ...[
                        Text(
                          _abbreviateTeamName(match.teams[0].name),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDisplayScore(
                            match.teams[0].score,
                            match.isUpcoming,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'vs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ),
                      if (match.teams.length > 1) ...[
                        Text(
                          _abbreviateTeamName(match.teams[1].name),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDisplayScore(
                            match.teams[1].score,
                            match.isUpcoming,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // Regular vertical layout for mobile
                  ...match.teams
                      .take(2)
                      .map(
                        (team) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              // Team name (abbreviated)
                              SizedBox(
                                width: 60,
                                child: Text(
                                  _abbreviateTeamName(team.name),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme
                                        .colorScheme
                                        .onPrimary, // Match homescreen text color
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Score (empty for upcoming matches instead of TBD)
                              Expanded(
                                child: Text(
                                  _getDisplayScore(
                                    team.score,
                                    match.isUpcoming,
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme
                                        .colorScheme
                                        .onPrimary, // Match homescreen text color
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Overs and run rate
                              if (team.overs.isNotEmpty ||
                                  team.runRate.isNotEmpty) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (team.overs.isNotEmpty)
                                      Text(
                                        '(${team.overs})',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onPrimary
                                                  .withOpacity(
                                                    0.8,
                                                  ), // Match homescreen style
                                            ),
                                      ),
                                    if (team.runRate.isNotEmpty)
                                      Text(
                                        'RR: ${team.runRate}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onPrimary
                                                  .withOpacity(
                                                    0.8,
                                                  ), // Match homescreen style
                                              fontSize: 10,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                ],
              ] else ...[
                Text(
                  TeamAbbreviation.teamsLine(match.teams),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: isCompact ? 4 : 12),

              // Match status and info (no venue on cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCompact) ...[
                    // Compact layout - show only the concise status/info text
                    Flexible(
                      child: Text(
                        _buildInfoText(match),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    // Mobile layout - show only the concise status/info text
                    Expanded(
                      child: Text(
                        _buildInfoText(match),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),

              // Last updated info (hidden in compact mode)
              if (match.lastUpdated.isNotEmpty && !isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  'Updated: ${_formatLastUpdated(match.lastUpdated)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(
                      0.8,
                    ), // Match homescreen style
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(Object error, String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Failed to load matches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'live':
        message = 'No live matches at the moment';
        icon = Icons.play_circle_outline;
        break;
      case 'upcoming':
        message = 'No upcoming matches scheduled';
        icon = Icons.schedule;
        break;
      case 'recent':
        message = 'No recent matches found';
        icon = Icons.history;
        break;
      default:
        message = 'No matches available';
        icon = Icons.sports_cricket;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation handled by OpenContainer's openBuilder

  // Builds a concise info line for the card replacing the venue:
  // - Completed: result text if available
  // - Live: current status message
  // - Upcoming: start date/time when available
  String _buildInfoText(CricketMatch match) {
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
      return match.status.isNotEmpty ? match.status : 'Live';
    }
    return match.status;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'live':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.check_circle;
      case 'upcoming':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  // Use theme colors so that in monochrome mode the UI remains monochrome.
  Color _getStatusColor(String status, [BuildContext? context]) {
    final s = status.toLowerCase();
    if (context != null) {
      final cs = Theme.of(context).colorScheme;
      if (s == 'live') return cs.error; // prominent color in theme
      if (s == 'completed') return cs.primary;
      if (s == 'upcoming') return cs.secondary;
      return cs.outline;
    }
    // Fallback (should rarely be used)
    if (s == 'live') return Colors.red;
    if (s == 'completed') return Colors.blueGrey;
    if (s == 'upcoming') return Colors.grey;
    return Colors.grey;
  }

  String _formatLastUpdated(String lastUpdated) {
    try {
      final date = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // No longer used: kept here for reference but not called.
  // String _getFormattedTeams(CricketMatch match) { /* deprecated */ return TeamAbbreviation.teamsLine(match.teams); }
}

// (HeaderAction moved to core/widgets/collapsing_sliver_app_bar.dart)

// SliverPersistentHeader delegate for the pinned TabBar
class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _TabBarHeaderDelegate({
    required this.child,
    this.height = kToolbarHeight,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
