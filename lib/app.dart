import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

/// Root widget. One joyful theme, no route table needed — navigation is a
/// simple push/pop stack rooted at the splash → playground.
class KiddlyApp extends StatelessWidget {
  const KiddlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiddly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const SplashScreen(),
    );
  }
}
