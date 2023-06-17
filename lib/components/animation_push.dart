import 'package:flutter/material.dart';
import 'package:sekurity/tools/platformtools.dart';

// animation controller for a push in effect on click
class AnimationPush extends StatefulWidget {
  const AnimationPush({super.key, required this.child, required this.onPressed});
  // input widget to be animated
  final Widget child;
  final Function() onPressed;

  @override
  State<AnimationPush> createState() => _AnimationPushState();
}

class _AnimationPushState extends State<AnimationPush>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 75),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
        _controller); // Customize the begin and end values for the desired push-in effect
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
        vibrate(10);
      }
    });
    return InkWell(
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTapDown: (details) {
        _controller.forward(from: 0.0); // Start the animation on tap
        widget.onPressed();
        // vibrate
        vibrate(5);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: ((context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        }),
        child: widget.child, // Replace with your own widget
      ),
    );
  }
}
