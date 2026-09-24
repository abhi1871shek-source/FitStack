import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmojiProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String emoji;
  final String? assetPath;
  final Color barColor;
  final Color backgroundColor;
  final double height;
  final double emojiSize;

  const EmojiProgressBar({
    super.key,
    required this.progress,
    required this.emoji,
    this.assetPath,
    this.barColor = AppColors.primary,
    this.backgroundColor = AppColors.borderSubdued,
    this.height = 8.0,
    this.emojiSize = 24.0,
  });

  @override
  State<EmojiProgressBar> createState() => _EmojiProgressBarState();
}

class _EmojiProgressBarState extends State<EmojiProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;

  static final Uint8List _saladBytes = base64Decode(
    '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',
  );

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(EmojiProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.progress - oldWidget.progress).abs() > 0.001) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  String _resolveAssetPath() {
    if (widget.assetPath != null && widget.assetPath!.isNotEmpty) {
      return widget.assetPath!;
    }
    if (widget.emoji == '💪') return 'assets/images/emoji/emoji_biceps.png';
    if (widget.emoji == '🎯') return 'assets/images/emoji/emoji_target.png';
    if (widget.emoji == '🔥') return 'assets/images/emoji/emoji_fire.png';
    if (widget.emoji == '🥗') return 'assets/images/emoji/emoji_salad.png';
    return '';
  }

  Widget _buildEmojiGraphic() {
    final assetPath = _resolveAssetPath();
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: widget.emojiSize,
        height: widget.emojiSize,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) {
          if (widget.emoji == '🥗' || assetPath.contains('salad')) {
            return Image.memory(
              _saladBytes,
              width: widget.emojiSize,
              height: widget.emojiSize,
              fit: BoxFit.contain,
            );
          }
          return Text(
            widget.emoji,
            style: TextStyle(
              fontSize: widget.emojiSize,
              height: 1.0,
            ),
          );
        },
      );
    }

    return Text(
      widget.emoji,
      style: TextStyle(
        fontSize: widget.emojiSize,
        height: 1.0,
        fontFamilyFallback: const [
          'Apple Color Emoji',
          'Segoe UI Emoji',
          'Noto Color Emoji',
          'Android Emoji',
          'EmojiOne Color',
          'Twemoji Mozilla',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    final totalWidgetHeight = math.max(widget.height, widget.emojiSize + 6.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * clampedProgress;
        final double emojiLeft = (filledWidth - (widget.emojiSize / 2)).clamp(0.0, math.max(0.0, totalWidth - widget.emojiSize)).toDouble();
        final double barTop = (totalWidgetHeight - widget.height) / 2;
        final double emojiTop = (totalWidgetHeight - widget.emojiSize) / 2;

        return SizedBox(
          height: totalWidgetHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track Background & Filled Portion
              Positioned(
                top: barTop,
                left: 0,
                right: 0,
                child: Container(
                  height: widget.height,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: filledWidth,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.barColor,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated Leading Edge Emoji Graphic Asset with Pop Scale
              if (clampedProgress > 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  left: emojiLeft,
                  top: emojiTop,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildEmojiGraphic(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
