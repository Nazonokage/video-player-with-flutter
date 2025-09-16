import 'package:flutter/material.dart';
import 'core/state_store.dart';
import 'core/app_state.dart';
import 'features/library/library_screen.dart';

class CleanPlayerApp extends StatefulWidget {
  const CleanPlayerApp({super.key});
  @override
  State<CleanPlayerApp> createState() => _CleanPlayerAppState();
}

class _CleanPlayerAppState extends State<CleanPlayerApp> {
  final _store = StateStore();
  AppStateModel? _state;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await _store.load();
    setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: LibraryScreen(state: state, store: _store),
    );
  }
}
