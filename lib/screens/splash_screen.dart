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
  late Animation<double> _sponsorFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Sponsor logos fade in slightly later
    _sponsorFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.cardBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Center: Main logo + loading indicator
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.asset(
                        'assets/logos/soilava_logo_light_theme.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.colors.primaryBtn,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: Sponsor logos
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _sponsorFadeAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'สนับสนุนโดย',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logos/logo_rmutsb_transparent.gif',
                          height: 48,
                          color: isDark ? Colors.white : null,
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 1,
                          height: 32,
                          color: context.colors.borderColor,
                        ),
                        const SizedBox(width: 20),
                        Image.asset(
                          'assets/logos/สกสว.png',
                          height: 48,
                          color: isDark ? Colors.white : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
