import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration animationDuration;
  final Duration backDuration;
  final Duration pauseDuration;

  const MarqueeWidget({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration =
        const Duration(seconds: 6), // Slower for readability
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!mounted) return;

    // Check if scrolling is needed
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      while (mounted) {
        if (!_scrollController.hasClients) break;

        await Future.delayed(widget.pauseDuration);
        if (mounted && _scrollController.hasClients) {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: widget.animationDuration,
            curve: Curves.linear,
          );
        }

        await Future.delayed(widget.pauseDuration);
        if (mounted && _scrollController.hasClients) {
          // Native behavior often jumps back or scrolls back fast.
          // Let's scroll back slightly faster or jump to start for loop.
          // For "Marquee" loop usually means repeat.
          // But infinite list requires more complex setup.
          // Simple back-and-forth or jump-to-start is safer for custom widget.

          // Let's jump to start to simulate marquee loop (with a slight jarring)
          // Or animate back. Animate back is smoother.
          await _scrollController.animateTo(
            0.0,
            duration: widget.backDuration,
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: widget.direction,
      physics: const NeverScrollableScrollPhysics(), // Disable user scrolling
      child: widget.child,
    );
  }
}
