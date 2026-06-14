import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/character_provider.dart';
import 'providers/commute_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CommuteQuestApp());
}

class CommuteQuestApp extends StatelessWidget {
  const CommuteQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => CommuteProvider()),
      ],
      child: MaterialApp(
        title: 'CommuteQuest',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
