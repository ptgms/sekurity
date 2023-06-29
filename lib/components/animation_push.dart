import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// animation controller for a push in effect on click
class AnimationPush extends StatefulWidget {
  const AnimationPush(
      {super.key, required this.child, required this.onPressed});
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

    _animation = Tween<double>(begin: 1.0, end: 0.96).animate(
        _controller); // Customize the begin and end values for the desired push-in effect
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !isPressed) {
        _controller.reverse();
        HapticFeedback.mediumImpact();
      }
    });
    return GestureDetector(
      onTapDown: (details) {
        isPressed = true;
        _controller.forward(from: 0.0); // Start the animation on tap
        // widget.onPressed();
        // vibrate
        HapticFeedback.lightImpact();
      },
      // when the tap is released, reverse the animation
      onTapUp: ((details) {
        isPressed = false;
        widget.onPressed();
        if (!_controller.isAnimating) {
          _controller.reverse();
          HapticFeedback.mediumImpact();
          }
          isPressed = false;
      }),
      // when u tap and drag away, reverse the animation
      onTapCancel: () {
        isPressed = false;
        if (!_controller.isAnimating) {
          _controller.reverse();
          HapticFeedback.mediumImpact();
          }
          isPressed = false;
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
