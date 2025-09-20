// lib/app.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/state_store.dart';
import 'core/playlist_service.dart';
import 'core/app_state.dart';

import 'features/library/library_screen.dart';
import 'features/player/player_screen.dart';
import 'features/player/player_controller.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final Future<StateStore> _storeFuture;
  late final PlaylistService _playlist;
  String? _currentPlayerPath;
  PlayerController? _currentPlayerController;

  @override
  void initState() {
    super.initState();
    // Must be called before using media_kit anywhere.
    MediaKit.ensureInitialized();

    _storeFuture = StateStore.load();
    _playlist = PlaylistService();
  }

  void _openPlayer(String path) {
    setState(() {
      _currentPlayerPath = path;
      // Create a new player controller for this session
      _currentPlayerController = PlayerController();
    });
  }

  void _goBackToLibrary() {
    // Dispose the current player controller
    _currentPlayerController?.dispose();
    _currentPlayerController = null;
    
    setState(() {
      _currentPlayerPath = null;
    });
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
          home: _currentPlayerPath != null && _currentPlayerController != null
              ? PlayerScreen(
                  state: state,
                  store: store,
                  initialPath: _currentPlayerPath!,
                  playlist: _playlist,
                  controller: _currentPlayerController!,
                  onBackToLibrary: _goBackToLibrary,
                )
              : LibraryScreen(
                  state: state,
                  store: store,
                  playlist: _playlist,
                  onOpenFile: _openPlayer,
                ),
        );
      },
    );
  }
}
