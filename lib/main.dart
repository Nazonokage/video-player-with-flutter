import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // <-- add this
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // <-- required before using media_kit
  runApp(const CleanPlayerApp());
}
