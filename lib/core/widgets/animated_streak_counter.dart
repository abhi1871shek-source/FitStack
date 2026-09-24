import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A subtle, professional animated streak counter.
///
/// Uses [TweenAnimationBuilder] to smoothly interpolate integer numeric values
/// over a 400-600ms duration, paired with an understated scale pulse.
class AnimatedStreakCounter extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;
  final bool enablePulse;

  const AnimatedStreakCounter({
    super.key,
    required this.count,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.enablePulse = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: count.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final currentInt = value.round();

        // Calculate subtle scale pulse during interpolation:
        // Reaches peak scale (1.06x) near the midpoint of fractional progress
        final fractional = (value - value.floor()).abs();
        final pulseMagnitude = math.sin(fractional * math.pi);
        final scale = enablePulse ? 1.0 + (0.06 * pulseMagnitude) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Text(
            '$prefix$currentInt$suffix',
            style: style,
          ),
        );
      },
    );
  }
}
