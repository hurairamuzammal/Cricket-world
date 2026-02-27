import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CollapsingSliverAppBar extends StatelessWidget {
  final double expandedHeight;
  final String collapsedTitle; // Text when collapsed
  final Widget expandedTitle; // Prominent title when expanded
  final List<Widget> expandedActions; // Buttons visible in expanded header
  final bool showLeading;

  const CollapsingSliverAppBar({
    super.key,
    required this.collapsedTitle,
    required this.expandedTitle,
    this.expandedActions = const [],
    this.expandedHeight = 200,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaPadding = MediaQuery.of(context).padding;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double computedExpandedHeight = math.max(
      expandedHeight,
      _calculateRequiredHeight(
        mediaPadding: mediaPadding,
        isMobile: isMobile,
        actionCount: expandedActions.length,
      ),
    );

    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: computedExpandedHeight,
      centerTitle: true,
      automaticallyImplyLeading: showLeading,
      title: null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double current = constraints.biggest.height - kToolbarHeight;
          final double max = computedExpandedHeight - kToolbarHeight;
          final double t = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),

              // Collapsed title (visible when collapsed)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16.0 : 24.0,
                          ),
                          child: Text(
                            collapsedTitle,
                            style: GoogleFonts.montserrat(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 22 : 24, // Increased sizes
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded content (visible when expanded)
              Positioned.fill(
                child: SafeArea(
                  child: Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 20),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16.0 : 24.0,
                          kToolbarHeight + (isMobile ? 10 : 12),
                          isMobile ? 16.0 : 24.0,
                          isMobile ? 10 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Large title when expanded
                            Text(
                              collapsedTitle,
                              style: GoogleFonts.montserrat(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: isMobile
                                    ? 36
                                    : 42, // Much larger sizes
                                letterSpacing: -0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),

                            if (expandedActions.isNotEmpty) ...[
                              SizedBox(height: isMobile ? 16 : 20),
                              SizedBox(height: isMobile ? 12 : 16),
                              // Actions layout optimized for mobile and desktop
                              if (isMobile) ...[
                                // Mobile: Stack actions vertically or in a grid
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: expandedActions.map((action) {
                                    return SizedBox(
                                      width: (screenWidth - 64) / 2,
                                      child: action,
                                    );
                                  }).toList(),
                                ),
                              ] else ...[
                                // Desktop: Horizontal layout
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: expandedActions.asMap().entries.map(
                                    (entry) {
                                      final isLast =
                                          entry.key ==
                                          expandedActions.length - 1;
                                      return Row(
                                        children: [
                                          entry.value,
                                          if (!isLast)
                                            const SizedBox(width: 12),
                                        ],
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

double _calculateRequiredHeight({
  required EdgeInsets mediaPadding,
  required bool isMobile,
  required int actionCount,
}) {
  const double baseBottomPadding = 3;
  final double topPadding =
      mediaPadding.top + kToolbarHeight + (isMobile ? 10 : 12);
  final double bottomPadding = mediaPadding.bottom + baseBottomPadding;
  final double titleHeight = isMobile ? 38 : 46;

  if (actionCount == 0) {
    return topPadding + titleHeight + bottomPadding;
  }

  final double spacingAfterTitle = isMobile ? 10 : 14;
  final double buttonHeight = isMobile ? 42 : 46;

  final int rows = isMobile ? ((actionCount + 1) ~/ 2) : 1;
  final double runSpacing = isMobile && rows > 1 ? 8.0 * (rows - 1) : 0.0;

  final double actionsHeight = (rows * buttonHeight) + runSpacing;

  return topPadding +
      titleHeight +
      spacingAfterTitle +
      actionsHeight +
      bottomPadding;
}

class HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurface;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: fg.withValues(alpha: 0.25)),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 12 : 14,
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: isMobile ? 18 : 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
