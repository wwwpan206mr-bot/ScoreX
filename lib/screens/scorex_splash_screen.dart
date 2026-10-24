import 'dart:async';
import 'package:flutter/material.dart';

/// ScoreX branded intro. Activate after adding the bundled PNG asset.
class ScoreXSplashScreen extends StatefulWidget {
  const ScoreXSplashScreen({super.key, required this.home});
  final Widget home;

  @override
  State<ScoreXSplashScreen> createState() => _ScoreXSplashScreenState();
}

class _ScoreXSplashScreenState extends State<ScoreXSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => widget.home),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061B15),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Image.asset('assets/branding/scorex_logo.png', fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
