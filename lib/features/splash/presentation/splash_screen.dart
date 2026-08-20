import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_assistant/core/services/profile_service.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/account/presentation/account_setup_screen.dart';
import 'package:mobile_assistant/features/lock/presentation/screens/lock_screen.dart';
import 'package:mobile_assistant/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';
import 'package:mobile_assistant/main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered entrance: logo first, then title, then tagline.
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _glowFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;

  static const Duration _splashDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );
    _glowFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );

    _controller.forward();
    _routeToNextScreen();
  }

  Future<void> _routeToNextScreen() async {
    final started = DateTime.now();

    final isAccountCreated = await ProfileService.instance.isAccountCreated();
    final isOnboardingComplete =
        await ProfileService.instance.isOnboardingComplete();

    // settingsProvider contains app lock setting
    final settings = await ref.read(settingsProvider.future);

    // Let the splash animation play out before navigating.
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _splashDuration) {
      await Future.delayed(_splashDuration - elapsed);
    }

    if (!mounted) return;

    if (!isAccountCreated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountSetupScreen()),
      );
    } else if (isOnboardingComplete) {
      if (settings.isAppLockEnabled) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const _SplashBackground(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Soft radial glow behind the logo
                    Opacity(
                      opacity: _glowFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value * 1.35,
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.accent.withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Logo mark — Gemini-generated icon when available,
                    // falls back to the teal sparkle widget icon.
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2DD4BF),
                                Color(0xFF0E9B96),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 40,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/icons/splash_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.auto_awesome_rounded,
                              size: 46,
                              color: Color(0xFF0E0F12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App title
                    Opacity(
                      opacity: _titleFade.value,
                      child: Text(
                        'Mobile Assistant',
                        style: GoogleFonts.manrope(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'Your smart companion',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Deep, teal-tinted backdrop that fades toward the app's base background.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.4,
          colors: [
            Color(0xFF15312F), // teal-tinted deep
            AppTheme.background,
          ],
          stops: [0.0, 0.75],
        ),
      ),
    );
  }
}
