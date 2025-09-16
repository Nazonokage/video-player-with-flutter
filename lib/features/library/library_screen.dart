import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../player/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final AppStateModel state;
  final StateStore store;
  const LibraryScreen({super.key, required this.state, required this.store});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Future<void> _openFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'mov', 'avi', 'webm'],
    );
    // inside _openFile():
    if (picked?.files.single.path == null) return;
    final path = picked!.files.single.path!;
    if (!widget.state.playlist.contains(path)) widget.state.playlist.add(path);
    await widget.store.save(widget.state);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: widget.state,
          store: widget.store,
          initialPath: path,
        ),
      ),
    );
  }

  Future<void> _openFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    // TODO: scan directory for videos & add to playlist
    setState(() {});
    await widget.store.save(widget.state);
  }

  Future<void> _clearRecents() async {
    widget.state.recents.clear();
    setState(() {});
    await widget.store.save(widget.state);
  }

  @override
  Widget build(BuildContext context) {
    final recents = widget.state.recents;
    return Scaffold(
      appBar: AppBar(title: const Text('CleanPlayer — Library')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _openFolder,
                  child: const Text('📂 Open Folder'),
                ),
                OutlinedButton(
                  onPressed: _openFile,
                  child: const Text('📄 Open File'),
                ),
                TextButton(
                  onPressed: _clearRecents,
                  child: const Text('🧹 Clear recents'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: recents.isEmpty
                  ? const Center(child: Text('No recents yet'))
                  : ListView.separated(
                      itemCount: recents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = recents[i];
                        return ListTile(
                          title: Text(
                            r.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Resume at ${r.lastPosition.toStringAsFixed(1)}s • ${r.updatedAt}',
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  state: widget.state,
                                  store: widget.store,
                                  initialPath: r.path,
                                ),
                              ),
                            );
                          },

                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () async {
                              widget.state.recents.removeAt(i);
                              setState(() {});
                              await widget.store.save(widget.state);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
