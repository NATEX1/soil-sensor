import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScanAnimation extends StatefulWidget {
  final bool isScanning;
  final IconData icon;
  const ScanAnimation({super.key, required this.isScanning, this.icon = Icons.bluetooth});
  @override
  State<ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<ScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.4)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => Container(
                width: 80 * _animation.value,
                height: 80 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryBtn
                      .withValues(alpha: 0.12 * (2 - _animation.value)),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isScanning
                  ? context.colors.primaryBtn
                  : context.colors.cardBg,
            ),
            child: Icon(widget.icon,
                color:
                    widget.isScanning ? Colors.white : context.colors.textMuted,
                size: 30),
          ),
        ],
      ),
    );
  }
}
