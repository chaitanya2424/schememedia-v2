import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A single shimmering placeholder rectangle -- built from Flutter's own
/// `AnimationController` + `ShaderMask`, no new package dependency.
/// Composed into per-screen skeleton shapes (a list-row skeleton for
/// Search, a block skeleton for Scheme Detail, etc.) rather than used bare.
/// Replaces [AsyncValueView]'s previous bare spinner as the default loading
/// state -- a spinner alone reads as unfinished on first load of every
/// screen; a content-shaped skeleton reads as intentional.
///
/// Respects `MediaQuery.disableAnimations` (the OS "reduce motion" setting)
/// by rendering a static placeholder instead of animating.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: base, borderRadius: widget.borderRadius),
    );

    if (MediaQuery.of(context).disableAnimations) return box;

    final highlight = base.withValues(alpha: 0.4);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 - t * 2, 0),
            end: Alignment(1 - t * 2, 0),
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: box,
        );
      },
    );
  }
}

/// A generic list-row-shaped skeleton (leading circle + two lines) -- the
/// default shape for a scrollable list/grid of cards while loading.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 16),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.4, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
