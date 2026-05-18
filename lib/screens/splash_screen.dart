import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Navigate to dashboard after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Unique background usually matches dark mode or looks good on black/dark-gray
    // so we force a dark background for the splash to make the "unique" logo pop.
    // Or we use the scaffold background.
    return Scaffold(
      backgroundColor: context.colors.cardBg, // Use cardBg for a clean look
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primaryBtn.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/logos/soilava_logo_light_theme.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // We don't need text if the logo already has text, but adding a nice loading indicator is good.
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: context.colors.primaryBtn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
