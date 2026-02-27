// Swipeable News Cards Widget
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_of_cricket/core/utils/responsive.dart';
import '../providers/news_provider.dart';
import '../../domain/entities/news_entity.dart';
import '../pages/news_detail.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';

class SwipeableNewsCards extends ConsumerStatefulWidget {
  const SwipeableNewsCards({super.key});

  @override
  ConsumerState<SwipeableNewsCards> createState() => _SwipeableNewsCardsState();
}

class _SwipeableNewsCardsState extends ConsumerState<SwipeableNewsCards> {
  List<NewsEntity> currentNews = [];

  void changeCardOrder() {
    setState(() {
      if (currentNews.isNotEmpty) {
        // Move the top card to the back
        final topCard = currentNews.removeAt(0);
        currentNews.add(topCard);
      }
    });
  }

  void initializeCards(List<NewsEntity> newsList) {
    if (currentNews.isEmpty) {
      currentNews = newsList.take(5).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(topNewsProvider);

    return newsAsync.when(
      data: (newsList) {
        if (newsList.isEmpty) {
          return const Center(child: Text('No news available'));
        }

        // Initialize cards if needed
        initializeCards(newsList);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Render cards in reverse order so the first card appears on top
                  for (int i = currentNews.length - 1; i >= 0; i--)
                    SwipeableNewsCard(
                      newsData: currentNews[i],
                      index: i,
                      key: ValueKey('${i}_${currentNews[i].title}'),
                      isTopCard: i == 0,
                      onSwiped: changeCardOrder,
                      totalCards: currentNews.length,
                      availableWidth: availableWidth,
                    ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const NewsShimmerLoading(),
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
              'Failed to load news',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Swipeable News Card
class SwipeableNewsCard extends StatefulWidget {
  final int index;
  final bool isTopCard;
  final VoidCallback onSwiped;
  final NewsEntity newsData;
  final int totalCards;
  final double availableWidth;

  const SwipeableNewsCard({
    super.key,
    required this.index,
    required this.isTopCard,
    required this.onSwiped,
    required this.newsData,
    required this.totalCards,
    required this.availableWidth,
  });
  @override
  State<SwipeableNewsCard> createState() => _SwipeableNewsCardState();
}

class _SwipeableNewsCardState extends State<SwipeableNewsCard>
    with TickerProviderStateMixin {
  Offset _position = const Offset(0, 0);
  double _rotation = 0.0;

  Curve _curve = Curves.linear;
  Duration _duration = const Duration(milliseconds: 0);

  static const double _swipeRegionHeightFactor = 0.75;

  void _handleHorizontalDragStart(DragStartDetails details) {
    _curve = Curves.linear;
    _duration = const Duration(milliseconds: 0);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;

    setState(() {
      final deltaX = details.primaryDelta ?? 0;
      _position = Offset(_position.dx + deltaX, _position.dy);
      _rotation = _position.dx / 800;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details, double cardWidth) {
    _curve = Curves.easeInOut;
    _duration = const Duration(milliseconds: 300);

    setState(() {
      final velocity = details.velocity.pixelsPerSecond;
      const velocityThreshold = 500.0;

      if (_position.dx.abs() > cardWidth / 4 ||
          velocity.dx.abs() > velocityThreshold) {
        final direction = _position.dx >= 0 ? 1 : -1;
        _position = Offset(direction * (cardWidth + 100), _position.dy);
        _rotation = direction * 0.3;

        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onSwiped();
          if (mounted) {
            setState(() {
              _position = Offset.zero;
              _rotation = 0.0;
            });
          }
        });
      } else {
        _position = Offset.zero;
        _rotation = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate card dimensions based on screen size and responsive breakpoints
    double cardWidth = _getCardWidth(context);
    double cardHeight = _getCardHeight(context);

    // Calculate stacking offset relative to the TOP card (index 0)
    // This ensures the top card remains centered and only the
    // underlying cards are offset slightly to the right and UP so the
    // stack is visible from the top-right (not the bottom).
    int stackIndex = widget.index; // 0 for top, increasing for cards behind

    // Reveal from top: move underlying cards UP by a few pixels per layer
    double topRevealOffset = Responsive.isMobile(context)
        ? stackIndex * 6.0
        : stackIndex * 4.0;

    final double baseTop = 0.0;

    return AnimatedPositioned(
      left:
          // Center the top card and apply stacking offset for underlying cards
          ((widget.availableWidth - cardWidth) / 2) +
          (widget.isTopCard ? _position.dx : 0) +
          (stackIndex *
              (Responsive.isMobile(context)
                  ? 3.0
                  : 2.0)), // Reduced stacking offset
      top: baseTop - topRevealOffset + (widget.isTopCard ? _position.dy : 0),
      duration: _duration,
      curve: _curve,
      child: Transform.rotate(
        angle: widget.isTopCard ? _rotation : 0,
        child: OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          closedElevation: 0,
          openElevation: 0,
          tappable: false, // We'll open manually on tap to keep custom gestures
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          openBuilder: (context, _) => NewsDetailScreen(news: widget.newsData),
          closedBuilder: (context, openContainer) => SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    debugPrint(
                      'Card ${widget.index} tapped - isTopCard: ${widget.isTopCard}',
                    );
                    openContainer();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildResponsiveCard(context),
                  ),
                ),
                if (widget.isTopCard)
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: _swipeRegionHeightFactor,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: openContainer,
                        onHorizontalDragStart: _handleHorizontalDragStart,
                        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                        onHorizontalDragEnd: (details) =>
                            _handleHorizontalDragEnd(details, cardWidth),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (Responsive.isMobile(context)) {
      return screenWidth * 0.85;
    } else if (Responsive.isTablet(context)) {
      return screenWidth * 0.65; // Slightly wider for better proportions
    } else {
      return screenWidth *
          0.75; // Increased width for desktop to match height increase
    }
  }

  double _getCardHeight(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return 320;
    } else if (Responsive.isTablet(context)) {
      return 350; // Increased height for tablets
    } else {
      return 400; // Significantly increased height for desktop to prevent overflow
    }
  }

  Widget _buildResponsiveCard(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return _buildMobileCard(context);
    } else {
      return _buildDesktopTabletCard(context);
    }
  }

  Widget _buildMobileCard(BuildContext context) {
    return Material(
      elevation: widget.isTopCard ? 8 : 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isTopCard
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(
                  0.9,
                ), // Slightly dimmed background instead of opacity
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isTopCard ? 0.25 : 0.15),
              blurRadius: widget.isTopCard ? 16 : 12,
              offset: Offset(0, widget.isTopCard ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: widget.newsData.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.newsData.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Center(
                              child: Icon(
                                Icons.article,
                                size: 48,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Center(
                          child: Icon(
                            Icons.article,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.newsData.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isTopCard
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onPrimary.withOpacity(0.8),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.newsData.description.isNotEmpty
                            ? widget.newsData.description.length > 100
                                  ? '${widget.newsData.description.substring(0, 100)}...'
                                  : widget.newsData.description
                            : 'Click to read more...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isTopCard
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.8)
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.swipe,
                        size: 16,
                        color: widget.isTopCard
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8)
                            : Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe to see more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isTopCard
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.8)
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTabletCard(BuildContext context) {
    return Material(
      elevation: widget.isTopCard ? 8 : 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isTopCard
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(
                  0.9,
                ), // Slightly dimmed background instead of opacity
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isTopCard ? 0.25 : 0.15),
              blurRadius: widget.isTopCard ? 16 : 12,
              offset: Offset(0, widget.isTopCard ? 6 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Section
            SizedBox(
              width: Responsive.isDesktop(context)
                  ? 140
                  : 120, // Wider image for desktop
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: widget.newsData.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.newsData.imageUrl,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.primary,
                            child: Center(
                              child: Icon(
                                Icons.article,
                                size: 40,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Center(
                          child: Icon(
                            Icons.article,
                            size: 40,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: Responsive.isDesktop(context)
                      ? 12.0
                      : 8.0, // More vertical padding for desktop
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.newsData.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.isDesktop(context)
                            ? 18
                            : null, // Larger font for desktop
                        color: widget.isTopCard
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8),
                      ),
                      maxLines: Responsive.isDesktop(context)
                          ? 3
                          : 2, // Allow more lines on desktop
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: Responsive.isDesktop(context) ? 8 : 4,
                    ), // More spacing for desktop
                    Text(
                      widget.newsData.description.isNotEmpty
                          ? Responsive.isDesktop(context)
                                ? (widget.newsData.description.length > 120
                                      ? '${widget.newsData.description.substring(0, 120)}...'
                                      : widget.newsData.description)
                                : (widget.newsData.description.length > 80
                                      ? '${widget.newsData.description.substring(0, 80)}...'
                                      : widget.newsData.description)
                          : 'Click to read more...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.isDesktop(context)
                            ? 15
                            : null, // Slightly larger for desktop
                        color: widget.isTopCard
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8)
                            : Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.6),
                      ),
                      maxLines: Responsive.isDesktop(context)
                          ? 4
                          : 2, // Allow more lines on desktop
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: Responsive.isDesktop(context) ? 12 : 8,
                    ), // More spacing for desktop
                    Row(
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 16,
                          color: widget.isTopCard
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.8)
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe to see more',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: widget.isTopCard
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withOpacity(0.8)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ), // Arrow Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.chevron_right,
                color: widget.isTopCard
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsCardShimmer extends StatelessWidget {
  const NewsCardShimmer({
    super.key,
    required this.index,
    required this.totalCards,
    required this.availableWidth,
  });

  final int index;
  final int totalCards;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardWidth = _getCardWidth(context);
    final cardHeight = _getCardHeight(context);

    int stackIndex = index;
    double topRevealOffset = Responsive.isMobile(context)
        ? stackIndex * 6.0
        : stackIndex * 4.0;
    final double baseTop = 0.0;

    return Positioned(
      left:
          ((availableWidth - cardWidth) / 2) +
          (stackIndex * (Responsive.isMobile(context) ? 3.0 : 2.0)),
      top: baseTop - topRevealOffset,
      child: Shimmer.fromColors(
        baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
        highlightColor: colorScheme.surfaceVariant.withOpacity(0.2),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (Responsive.isMobile(context)) {
      return screenWidth * 0.85;
    } else if (Responsive.isTablet(context)) {
      return screenWidth * 0.65;
    } else {
      return screenWidth * 0.75;
    }
  }

  double _getCardHeight(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return 320;
    } else if (Responsive.isTablet(context)) {
      return 350;
    } else {
      return 400;
    }
  }
}

class NewsShimmerLoading extends StatelessWidget {
  const NewsShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          const totalCards = 5;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (int i = totalCards - 1; i >= 0; i--)
                NewsCardShimmer(
                  index: i,
                  totalCards: totalCards,
                  availableWidth: availableWidth,
                  key: ValueKey('shimmer_$i'),
                ),
            ],
          );
        },
      ),
    );
  }
}
