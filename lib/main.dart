import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:world_of_cricket/feature/introduction_screen.dart';
import 'package:world_of_cricket/homescreen.dart';
import 'package:world_of_cricket/feature/matches_scores/presentation/screens/riverpod_cricket_matches_screen.dart';
import 'package:world_of_cricket/feature/sports_news/presentation/pages/news_screen.dart';
import 'package:world_of_cricket/core/services/theme_service.dart';
import 'package:world_of_cricket/core/services/onboarding_service.dart';
import 'package:world_of_cricket/core/theme/app_themes.dart';

const bool kShowIntroEveryTime =
    false; // Set to true for debugging intro screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeService = ThemeService();
  await themeService.init();

  final onboardingService = OnboardingService();
  await onboardingService.init();

  runApp(
    ProviderScope(
      child: MyApp(
        themeService: themeService,
        onboardingService: onboardingService,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final ThemeService themeService;
  final OnboardingService onboardingService;

  const MyApp({
    super.key,
    required this.themeService,
    required this.onboardingService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme and onboarding changes
    widget.themeService.addListener(_onStateChanged);
    widget.onboardingService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onStateChanged);
    widget.onboardingService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Get the appropriate color scheme
        final lightColorScheme = AppThemes.getColorScheme(
          isMonochrome: widget.themeService.isMonochrome,
          isDark: false,
          dynamicLight: lightDynamic,
          dynamicDark: darkDynamic,
        );

        final darkColorScheme = AppThemes.getColorScheme(
          isMonochrome: widget.themeService.isMonochrome,
          isDark: true,
          dynamicLight: lightDynamic,
          dynamicDark: darkDynamic,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Cricket World',
          themeMode: widget.themeService.themeMode,
          theme: AppThemes.createThemeData(
            colorScheme: lightColorScheme,
            isDark: false,
            isMonochrome: widget.themeService.isMonochrome,
          ),
          darkTheme: AppThemes.createThemeData(
            colorScheme: darkColorScheme,
            isDark: true,
            isMonochrome: widget.themeService.isMonochrome,
          ),
          home:
              (!kShowIntroEveryTime &&
                  widget.onboardingService.isOnboardingCompleted)
              ? BottomNavScreen(
                  themeService: widget.themeService,
                  onboardingService: widget.onboardingService,
                )
              : IntroductionScreen(onboardingService: widget.onboardingService),
          routes: {
            '/app': (_) => BottomNavScreen(
              themeService: widget.themeService,
              onboardingService: widget.onboardingService,
            ),
          },
        );
      },
    );
  }
}

class BottomNavScreen extends StatefulWidget {
  final ThemeService? themeService;
  final OnboardingService? onboardingService;

  const BottomNavScreen({super.key, this.themeService, this.onboardingService});

  @override
  // ignore: library_private_types_in_public_api
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 1;

  // Screens for each tab
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _screens = [
      // LeagueScreen(),
      NewsScreen(),
      HomeScreen(
        onNavigateToNews: () {
          navigateToNews();
        },
        themeService: widget.themeService,
        onboardingService: widget.onboardingService,
      ),
      RiverpodCricketMatchesScreen(
        themeService: widget.themeService,
      ), // Using the enhanced cricket API screen
      // const ApiTestWidget(), // Test the new API
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Update selected tab and animate to the page with a smooth horizontal slide
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void navigateToNews() {
    _onItemTapped(0); // Navigate to the News tab with animation
  }

  @override
  Widget build(BuildContext context) {
    // Bridge state for the floating nav bar builder
    _bottomNavSelectedIndex = _selectedIndex;
    _bottomNavOnTap = _onItemTapped;
    //
    // No extra content padding; bar truly floats over content

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // PageView provides the horizontal slide animation between tabs
          PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            dragStartBehavior: DragStartBehavior.down,
            allowImplicitScrolling: true,
            // Enable swipe gestures between tabs by using default page physics
            onPageChanged: (index) {
              if (index != _selectedIndex) {
                setState(() => _selectedIndex = index);
              }
            },
            children: _screens,
          ),
          // Floating nav overlaid at the very bottom
          _buildFloatingNavBar(context),
        ],
      ),
    );
  }
}

/// Creates a floating pill-shaped bottom navigation bar that adapts to
/// mobile, tablet and desktop widths.
Widget _buildFloatingNavBar(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final size = MediaQuery.of(context).size;
  final isWide = size.width >= 800; // treat as desktop/tablet breakpoint
  final isCompactPhone = size.width < 380;

  // Width/spacing rules
  final double maxBarWidth = isWide ? 560 : (isCompactPhone ? 320 : 400);
  final double horizontalMargin = isWide ? 0 : (isCompactPhone ? 12 : 14);
  final double barRadius = isCompactPhone ? 50 : (isWide ? 28 : 24);
  final double labelFontSize = isWide ? 12 : (isCompactPhone ? 10.5 : 11.5);
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final double bgOpacity = isDark
      ? 0.35
      : 0.75; // stronger separation to avoid mix

  return SafeArea(
    top: false,
    bottom: true,
    minimum: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? maxBarWidth : size.width,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Nearly transparent background so it still feels floating
                color: colorScheme.surface.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(barRadius),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 6),
                  ),
                ],
                // No outer border to avoid a bright ring
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(barRadius),
                child: Stack(
                  children: [
                    // Subtle blur to separate content beneath the floating bar
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 99, sigmaY: 99),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    isWide
                        ? Theme(
                            data: Theme.of(context).copyWith(
                              navigationBarTheme: NavigationBarThemeData(
                                labelTextStyle: MaterialStatePropertyAll(
                                  TextStyle(
                                    fontSize: labelFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            child: NavigationBar(
                              height: 92,
                              shadowColor: Colors.black.withOpacity(0.20),
                              elevation: 34,
                              backgroundColor: colorScheme.surface,
                              indicatorColor: colorScheme.primary.withOpacity(
                                0.12,
                              ),
                              labelBehavior:
                                  NavigationDestinationLabelBehavior.alwaysShow,
                              destinations: const [
                                NavigationDestination(
                                  icon: Icon(
                                    Icons.newspaper_outlined,
                                    size: 26,
                                  ),
                                  selectedIcon: Icon(Icons.newspaper, size: 28),
                                  label: 'News',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.home_outlined, size: 26),
                                  selectedIcon: Icon(Icons.home, size: 28),
                                  label: 'Home',
                                ),
                                NavigationDestination(
                                  icon: Icon(
                                    Icons.sports_cricket_outlined,
                                    size: 26,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.sports_cricket,
                                    size: 28,
                                  ),
                                  label: 'Matches',
                                ),
                              ],
                              selectedIndex: (_bottomNavSelectedIndex ?? 1),
                              onDestinationSelected: _bottomNavOnTap,
                            ),
                          )
                        : _CompactNavBar(
                            selectedIndex: (_bottomNavSelectedIndex ?? 1),
                            onTap: _bottomNavOnTap,
                            labelFontSize: labelFontSize,
                            isCompactPhone: isCompactPhone,
                            colorScheme: colorScheme,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Helpers to bridge state from the BottomNavScreen's State class to the
// top-level builder above without refactoring the file too much.
// These are set by the State object before build.
int? _bottomNavSelectedIndex;
void Function(int)? _bottomNavOnTap;

/// Compact custom nav bar for phones: shorter height and tighter spacing
class _CompactNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int)? onTap;
  final double labelFontSize;
  final bool isCompactPhone;
  final ColorScheme colorScheme;

  const _CompactNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.labelFontSize,
    required this.isCompactPhone,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final double height = 66; // increased height for better separation
    final double iconSize = isCompactPhone ? 20 : 22;
    final double selectedIconSize = iconSize + 2;
    final double itemVerticalPad = 5;
    final double iconHPad = isCompactPhone ? 6 : 10; // more horizontal for pill
    // vertical padding is kept tight for compact layout; no separate var needed
    const double labelLineHeight = 1.05;

    Widget item(IconData icon, IconData selectedIcon, String label, int index) {
      final bool selected = selectedIndex == index;
      final Color iconColor = selected
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant;
      final FontWeight labelWeight = selected
          ? FontWeight.w700
          : FontWeight.w600;
      final IconData effectiveIcon = selected ? selectedIcon : icon;

      return Expanded(
        child: InkWell(
          // splashColor: Theme.of(  context).colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          onTap: () => onTap?.call(index),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: itemVerticalPad),
            child: SizedBox(
              height: height - (itemVerticalPad * 2) - 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selected)
                    FractionallySizedBox(
                      widthFactor: isCompactPhone ? 0.94 : 0.9,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.20),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: iconHPad,
                          // vertical: iconVPad,
                        ),
                        child: Icon(
                          effectiveIcon,
                          size: selected ? selectedIconSize : iconSize,
                          color: iconColor,
                        ),
                      ),
                      // const SizedBox(height: 0),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: labelWeight,
                          height: labelLineHeight,
                          color: iconColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          item(Icons.newspaper_outlined, Icons.newspaper, 'News', 0),
          item(Icons.home_outlined, Icons.home, 'Home', 1),
          item(
            Icons.sports_cricket_outlined,
            Icons.sports_cricket,
            'Matches',
            2,
          ),
        ],
      ),
    );
  }
}
