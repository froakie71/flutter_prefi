import 'package:flutter/material.dart';

/// Simple fade + slide from below animation for small UI polish.
class FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double dy;
  final Curve curve;

  const FadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.dy = 12,
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Animated number/text appearance using AnimatedSwitcher.
class CountupText extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const CountupText(this.value, {super.key, this.style, this.duration = const Duration(milliseconds: 250)});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(anim), child: child)),
      child: Text(
        value,
        key: ValueKey(value),
        style: style,
      ),
    );
  }
}
