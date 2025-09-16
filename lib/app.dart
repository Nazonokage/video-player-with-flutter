// lib/app.dart
import 'package:flutter/material.dart';
import 'core/state_store.dart';
import 'core/playlist_service.dart';
import 'features/library/library_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StateStore>(
      future: StateStore.load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFF0a0f1e),
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final store = snap.data!;
        final playlist = PlaylistService();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CleanPlayer',
          // ✅ Let ColorScheme define brightness (dark) & remove ThemeData.brightness.
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00D4FF),
              brightness:
                  Brightness.dark, // <-- this is the only brightness we set
            ),
          ),
          home: LibraryScreen(store: store, playlist: playlist),
        );
      },
    );
  }
}
