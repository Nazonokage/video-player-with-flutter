// lib/app.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/state_store.dart';
import 'core/playlist_service.dart';
import 'core/app_state.dart';

import 'features/library/library_screen.dart';
import 'features/player/player_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final Future<StateStore> _storeFuture;
  late final PlaylistService _playlist;

  @override
  void initState() {
    super.initState();
    // Must be called before using media_kit anywhere.
    MediaKit.ensureInitialized();

    _storeFuture = StateStore.load();
    _playlist = PlaylistService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StateStore>(
      future: _storeFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: const ColorScheme.dark(),
              useMaterial3: true,
            ),
            home: const Scaffold(
              backgroundColor: Color(0xFF0a0f1e),
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final store = snap.data!;
        final AppStateModel state = store.state;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(),
            useMaterial3: true,
          ),
          // If you want to jump straight to a last-played file, you can route to PlayerScreen here.
          // For now, land on LibraryScreen.
          home: LibraryScreen(state: state, store: store, playlist: _playlist),
          // Example named route to open a file directly (optional):
          onGenerateRoute: (settings) {
            if (settings.name == '/player' && settings.arguments is String) {
              final path = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  state: state, // <-- REQUIRED: pass state
                  store: store,
                  initialPath: path,
                  playlist: _playlist,
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
