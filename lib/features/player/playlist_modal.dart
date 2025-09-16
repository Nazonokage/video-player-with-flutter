import 'package:flutter/material.dart';
import '../../core/path_utils.dart';

class PlaylistModal extends StatefulWidget {
  final List<String> items;
  final int currentIndex;
  final void Function(int index) onSelect;

  const PlaylistModal({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  State<PlaylistModal> createState() => _PlaylistModalState();
}

class _PlaylistModalState extends State<PlaylistModal> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = <(int, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      final path = widget.items[i];
      if (filenameOf(path).toLowerCase().contains(_q.toLowerCase())) {
        filtered.add((i, path));
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: const Color(0xFF0a0f1e).withValues(alpha: .95),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Playlist',
                    style: TextStyle(
                      color: Color(0xFF00D4FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search media…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .08),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final (idx, path) = filtered[i];
                      final name = filenameOf(path);
                      final active = idx == widget.currentIndex;
                      return Material(
                        color: active
                            ? const Color(0xFF00D4FF).withValues(alpha: .10)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onSelect(idx);
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: active ? .95 : .85,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // You can add “Open Folder / Open Files” here later if you want to change the playlist mid-session
            ],
          ),
        ),
      ),
    );
  }
}
