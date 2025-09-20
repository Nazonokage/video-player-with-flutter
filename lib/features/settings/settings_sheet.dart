import 'package:flutter/material.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          
          // About
          const Text(
            'About',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white70),
            title: const Text(
              'Clean Player',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'A dark-themed media player with subtitle and audio enhancement',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

}
