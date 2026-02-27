import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:world_of_cricket/core/widgets/theme_settings_screen.dart';
// removed unused imports
import 'package:world_of_cricket/feature/sports_news/presentation/providers/news_provider.dart';
import 'package:world_of_cricket/feature/sports_news/presentation/widgets/swipeablecards.dart';
import 'package:world_of_cricket/core/utils/responsive.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/widgets/simple_matches_cards.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/providers/cricket_matches_provider.dart';
import 'package:world_of_cricket/core/services/theme_service.dart';
import 'package:world_of_cricket/core/services/onboarding_service.dart';
// import 'api_test_screen.dart';
// import 'server_status_screen.dart';
import 'core/widgets/collapsing_sliver_app_bar.dart';

// Updated HomeScreen with Swipeable Cards
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToNews; // Add callback parameter
  final ThemeService? themeService; // Add theme service parameter
  final OnboardingService?
  onboardingService; // Add onboarding service parameter

  const HomeScreen({
    super.key,
    this.onNavigateToNews,
    this.themeService,
    this.onboardingService,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    // Invalidate providers to trigger a refresh
    ref.invalidate(newsProvider);
    ref.invalidate(allMatchesProvider);
    ref.invalidate(liveMatchesProvider);
    ref.invalidate(upcomingMatchesProvider);
    ref.invalidate(recentMatchesProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          CollapsingSliverAppBar(
            collapsedTitle: 'Cricket World',
            expandedTitle: const SizedBox.shrink(),
            showLeading: true,
            expandedActions: [
              HeaderAction(
                icon: Icons.refresh,
                label: 'Refresh',
                onTap: _refreshData,
              ),
              HeaderAction(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ThemeSettingsScreen(
                      themeService: widget.themeService!,
                      onboardingService: widget.onboardingService,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Live Matches section - no fixed height
              Container(
                color: colorScheme.surface,
                child: const SimpleMatchCards(),
              ),
              // Top Stories section - no fixed height
              Container(
                color: colorScheme.surface,
                width: double.infinity,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical:
                            8.0, // Added vertical padding for better spacing
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TOP STORIES",
                            style: GoogleFonts.montserrat(
                              fontSize: 36, // Much larger than before
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Switch to the News tab via callback from BottomNavScreen
                              widget.onNavigateToNews?.call();
                            },
                            icon: Icon(
                              Icons.arrow_right_rounded,
                              size: 42,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fixed height container for SwipeableNewsCards
                    SizedBox(
                      height: Responsive.isMobile(context)
                          ? 580
                          : Responsive.isTablet(context)
                          ? 420 // Increased height for tablets
                          : 480, // Significantly increased height for desktop to prevent overflow
                      child: const SwipeableNewsCards(),
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
}
