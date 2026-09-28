// FixMate — splash screen, restores the Supabase session
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'navigation.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    controller.forward();
    _start();
  }

  Future<void> _start() async {
    final state = context.read<AppState>();
    final restore = state.restoreSession();
    await Future.delayed(const Duration(seconds: 2));
    await restore;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => state.loggedIn ? const MainNavigation() : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: const FixMateLogo(size: 150),
          ),
        ),
      ),
    );
  }
}
