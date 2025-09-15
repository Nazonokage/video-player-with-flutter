import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'screens/main_screen.dart';
import 'providers/media_provider.dart';
import 'package:provider/provider.dart';

class UbraVlcApp extends StatelessWidget {
  const UbraVlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: MaterialApp(
        title: 'Ubra VLC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkGlass,
        home: const MainScreen(),
      ),
    );
  }
}


