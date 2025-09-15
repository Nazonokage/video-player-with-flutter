import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
	WidgetsFlutterBinding.ensureInitialized();
	MediaKit.ensureInitialized();
	runApp(
		MultiProvider(
			providers: [
				ChangeNotifierProvider(create: (_) => ThemeProvider()),
			],
			child: const UbraVlcApp(),
		),
	);
}
