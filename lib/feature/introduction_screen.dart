import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:world_of_cricket/core/services/onboarding_service.dart';

class IntroductionScreen extends StatefulWidget {
  final OnboardingService onboardingService;

  const IntroductionScreen({super.key, required this.onboardingService});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 1200);
  static const Duration _revealDuration = Duration(milliseconds: 1800);

  final List<_IntroSlide> _slides = const [
    _IntroSlide(
      id: 'welcome',
      title: 'Welcome to Cricket World',
      subtitle:
          'Your new hub for fixtures, insights, and highlights tailored for every fan.\nCrafted by Muhammad Abu Huraira.',
      showVisual: false,
    ),
    _IntroSlide(
      id: 'live-coverage',
      title: 'Live match coverage',
      subtitle: 'Live ball by ball updates right from  the app.',
      lottieAsset: 'assets/animations/live_match.json',
    ),
    _IntroSlide(
      id: 'news-coverage',
      title: 'Cricket news & stories',
      subtitle: 'Catch top  headlines, stories around the globe.',
      lottieAsset: 'assets/animations/news_headlines.json',
    ),
  ];

  int _currentIndex = 0;
  Offset _arrowOffset = const Offset(-0.18, 0);
  double _arrowOpacity = 0;
  bool _isNavigatingAway = false;
  bool _showReveal = false;
  Offset? _revealCenter;
  double _maxRevealRadius = 0;
  bool _navigationTriggered = false;
  int _revealCycle = 0;

  late final AnimationController _revealController;

  final GlobalKey _arrowButtonKey = GlobalKey();
  final GlobalKey _revealStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _arrowOffset = Offset.zero;
        _arrowOpacity = 1;
      });
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _handleArrowTap() {
    if (_isNavigatingAway) return;

    if (_currentIndex < _slides.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
      return;
    }

    _startRevealAndNavigate();
  }

  void _handleSkip() {
    if (_isNavigatingAway) return;

    if (_currentIndex < _slides.length - 1) {
      setState(() {
        _currentIndex = _slides.length - 1;
      });
      return;
    }

    _startRevealAndNavigate();
  }

  Future<void> _startRevealAndNavigate() async {
    if (_isNavigatingAway) return;

    final RenderBox? buttonBox =
        _arrowButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? stackBox =
        _revealStackKey.currentContext?.findRenderObject() as RenderBox?;

    if (buttonBox == null || stackBox == null) {
      await _completeOnboarding();
      return;
    }

    final Offset buttonCenterGlobal = buttonBox.localToGlobal(
      buttonBox.size.center(Offset.zero),
    );
    final Offset buttonCenter = stackBox.globalToLocal(buttonCenterGlobal);
    final Size stackSize = stackBox.size;

    final double maxHorizontal = math.max(
      buttonCenter.dx,
      stackSize.width - buttonCenter.dx,
    );
    final double maxVertical = math.max(
      buttonCenter.dy,
      stackSize.height - buttonCenter.dy,
    );
    final double maxRadius = math.sqrt(
      (maxHorizontal * maxHorizontal) + (maxVertical * maxVertical),
    );

    setState(() {
      _isNavigatingAway = true;
      _showReveal = true;
      _revealCenter = buttonCenter;
      _maxRevealRadius = maxRadius;
      _navigationTriggered = false;
      _revealCycle += 1;
    });

    final int cycle = _revealCycle;

    Future<void>.delayed(
      Duration(milliseconds: (_revealDuration.inMilliseconds * 0.58).round()),
      () async {
        if (!mounted || _navigationTriggered || _revealCycle != cycle) {
          return;
        }
        await _navigateToHome();
      },
    );

    await _revealController.forward(from: 0);
    if (!mounted) return;
    await _navigateToHome();
  }

  Future<void> _completeOnboarding() async {
    if (_navigationTriggered) return;
    setState(() => _isNavigatingAway = true);
    await widget.onboardingService.completeOnboarding();
    await _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    if (_navigationTriggered || !mounted) return;
    _navigationTriggered = true;
    await Navigator.of(context).pushReplacementNamed('/app');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        key: _revealStackKey,
        children: [
          AnimatedScale(
            scale: _isNavigatingAway ? 0.96 : 1,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              opacity: _isNavigatingAway ? 0 : 1,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleSkip,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 15,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                          child: Text(
                            _currentIndex < _slides.length - 1
                                ? 'Skip'
                                : 'Get started',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: _transitionDuration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _IntroSlideView(
                            key: ValueKey(_slides[_currentIndex].id),
                            slide: _slides[_currentIndex],
                            totalSlides: _slides.length,
                            activeIndex: _currentIndex,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AnimatedSlide(
                        duration: _transitionDuration,
                        curve: Curves.easeOutCubic,
                        offset: _arrowOffset,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 260),
                          opacity: _arrowOpacity,
                          child: _ArrowButton(
                            buttonKey: _arrowButtonKey,
                            onTap: _handleArrowTap,
                            label: _currentIndex < _slides.length - 1
                                ? 'Next'
                                : 'Lets Go!',
                            enabled: !_isNavigatingAway,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showReveal && _revealCenter != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _revealController,
                builder: (context, child) {
                  const double expandCutoff = 0.62;
                  double radiusFactor;
                  double overlayOpacity;
                  if (_revealController.value <= expandCutoff) {
                    final double normalized =
                        (_revealController.value / expandCutoff).clamp(
                          0.0,
                          1.0,
                        );
                    radiusFactor = Curves.easeOutCubic.transform(normalized);
                    overlayOpacity = 1;
                  } else {
                    final double normalized =
                        ((_revealController.value - expandCutoff) /
                                (1 - expandCutoff))
                            .clamp(0.0, 1.0);
                    final double shrinkEase = Curves.easeInOutCubic.transform(
                      normalized,
                    );
                    radiusFactor = 1 - shrinkEase;
                    overlayOpacity = (1 - Curves.easeIn.transform(normalized))
                        .clamp(0.0, 1.0);
                  }
                  overlayOpacity = overlayOpacity.clamp(0.0, 1.0).toDouble();
                  final double clampedRadiusFactor = radiusFactor
                      .clamp(0.0, 1.0)
                      .toDouble();
                  final double radius = _maxRevealRadius * clampedRadiusFactor;

                  return IgnorePointer(
                    child: Opacity(
                      opacity: overlayOpacity,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CircularRevealPainter(
                          center: _revealCenter!,
                          radius: radius,
                          primary: theme.colorScheme.primary,
                          secondary: theme.colorScheme.primaryContainer,
                          opacity: overlayOpacity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _IntroSlide {
  final String id;
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final bool showVisual;

  const _IntroSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.showVisual = true,
  });
}

class _IntroSlideView extends StatelessWidget {
  final _IntroSlide slide;
  final int totalSlides;
  final int activeIndex;

  const _IntroSlideView({
    super.key,
    required this.slide,
    required this.totalSlides,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _DotsIndicator(count: totalSlides, activeIndex: activeIndex),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (slide.showVisual)
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: slide.lottieAsset != null
                              ? Lottie.asset(
                                  slide.lottieAsset!,
                                  fit: BoxFit.contain,
                                  repeat: true,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              SizedBox(height: slide.showVisual ? 32 : 16),
              Text(
                slide.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotsIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 10,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary
                : colors.outlineVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool enabled;
  final GlobalKey? buttonKey;

  const _ArrowButton({
    required this.onTap,
    required this.label,
    this.enabled = true,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Image.asset(
                    'assets/icons/arrow.png',
                    height: 54,
                    fit: BoxFit.contain,
                    semanticLabel: label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularRevealPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color primary;
  final Color secondary;
  final double opacity;

  _CircularRevealPainter({
    required this.center,
    required this.radius,
    required this.primary,
    required this.secondary,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || opacity <= 0) return;

    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary,
          Color.lerp(primary, secondary, 0.4) ?? secondary,
          secondary,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..color = Colors.white.withOpacity(opacity);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularRevealPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.center != center ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.opacity != opacity;
  }
}
