import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/slider_model.dart';
import '../../providers/library_provider.dart';

class HomeBannerSlider extends ConsumerStatefulWidget {
  const HomeBannerSlider({super.key});

  @override
  ConsumerState<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends ConsumerState<HomeBannerSlider> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int length) {
    if (_lastLength == length && _autoPlayTimer != null && _autoPlayTimer!.isActive) {
      return;
    }
    _lastLength = length;
    _autoPlayTimer?.cancel();
    if (length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _handleSliderTap(SliderModel slider) async {
    final rawLink = slider.link?.trim();
    final linkToLaunch = (rawLink != null && rawLink.isNotEmpty)
        ? rawLink
        : 'https://alam-alislam.com';

    Uri? uri = Uri.tryParse(linkToLaunch);
    if (uri != null) {
      if (!uri.hasScheme) {
        uri = Uri.tryParse('https://$linkToLaunch');
      }
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        } catch (_) {}

        try {
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slidersAsync = ref.watch(slidersFutureProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return slidersAsync.when(
      loading: () => _buildShimmer(currentPalette, isDark),
      error: (_, _) => const SizedBox.shrink(),
      data: (sliders) {
        if (sliders.isEmpty) return const SizedBox.shrink();

        _startAutoPlay(sliders.length);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          height: 145,
          child: Stack(
            children: [
              // Page View (فقط عکس)
              PageView.builder(
                controller: _pageController,
                itemCount: sliders.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slider = sliders[index];
                  return _buildSliderItem(
                    slider: slider,
                    currentPalette: currentPalette,
                    isDark: isDark,
                    onTap: () => _handleSliderTap(slider),
                  );
                },
              ),

              // Bottom Indicator Dots
              if (sliders.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(sliders.length, (dotIndex) {
                          final isSelected = dotIndex == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            height: 5,
                            width: isSelected ? 16 : 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? currentPalette.accent
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderItem({
    required SliderModel slider,
    required AppPalette currentPalette,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ZoomTapAnimation(
      onTap: onTap,
      begin: 1.0,
      end: 0.98,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E2825) : Theme.of(context).cardColor,
          border: Border.all(
            color: isDark
                ? currentPalette.accent.withValues(alpha: 0.25)
                : currentPalette.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: currentPalette.color.withValues(alpha: isDark ? 0.3 : 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: slider.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: slider.imageUrl,
                memCacheWidth: 800,
                memCacheHeight: 400,
                maxWidthDiskCache: 1200,
                maxHeightDiskCache: 600,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                  highlightColor: isDark ? Colors.grey[750]! : Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: currentPalette.color.withValues(alpha: 0.15),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: currentPalette.accent,
                      size: 32,
                    ),
                  ),
                ),
              )
            : Container(
                color: currentPalette.color.withValues(alpha: 0.15),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: currentPalette.accent,
                    size: 32,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildShimmer(AppPalette currentPalette, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      height: 145,
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[750]! : Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
