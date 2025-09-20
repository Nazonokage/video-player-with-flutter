import 'package:flutter/material.dart';
import '../../core/app_state.dart';

class VolumeEnhancementDialog extends StatefulWidget {
  final VolumeEnhancement currentSettings;
  final ValueChanged<VolumeEnhancement> onSettingsChanged;

  const VolumeEnhancementDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<VolumeEnhancementDialog> createState() => _VolumeEnhancementDialogState();
}

class _VolumeEnhancementDialogState extends State<VolumeEnhancementDialog> {
  late VolumeEnhancement _settings;
  late bool _enabled;
  late double _boost;
  late double _bass;
  late double _treble;
  late bool _normalize;
  late double _dynamicRange;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    _enabled = _settings.enabled;
    _boost = _settings.boost;
    _bass = _settings.bass;
    _treble = _settings.treble;
    _normalize = _settings.normalize;
    _dynamicRange = _settings.dynamicRange;
  }

  @override
  void didUpdateWidget(VolumeEnhancementDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if the widget's settings changed
    if (oldWidget.currentSettings != widget.currentSettings) {
      _settings = widget.currentSettings;
      _enabled = _settings.enabled;
      _boost = _settings.boost;
      _bass = _settings.bass;
      _treble = _settings.treble;
      _normalize = _settings.normalize;
      _dynamicRange = _settings.dynamicRange;
    }
  }

  void _updateSettings() {
    final newSettings = _settings.copyWith(
      enabled: _enabled,
      boost: _boost,
      bass: _bass,
      treble: _treble,
      normalize: _normalize,
      dynamicRange: _dynamicRange,
    );
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a2235),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Volume Enhancement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Enable/Disable Toggle
            _buildSwitch(
              'Enable Volume Enhancement',
              _enabled,
              (value) {
                setState(() => _enabled = value);
                _updateSettings();
              },
            ),
            const SizedBox(height: 24),

            // Settings (only show if enabled)
            if (_enabled) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Volume Boost
                      _buildSlider(
                        'Volume Boost',
                        _boost,
                        0.5,
                        2.0,
                        (value) {
                          setState(() => _boost = value);
                          _updateSettings();
                        },
                        '${(_boost * 100).round()}%',
                      ),
                      const SizedBox(height: 20),

                      // Bass
                      _buildSlider(
                        'Bass',
                        _bass,
                        -1.0,
                        1.0,
                        (value) {
                          setState(() => _bass = value);
                          _updateSettings();
                        },
                        _bass > 0 ? '+${(_bass * 100).round()}%' : '${(_bass * 100).round()}%',
                      ),
                      const SizedBox(height: 20),

                      // Treble
                      _buildSlider(
                        'Treble',
                        _treble,
                        -1.0,
                        1.0,
                        (value) {
                          setState(() => _treble = value);
                          _updateSettings();
                        },
                        _treble > 0 ? '+${(_treble * 100).round()}%' : '${(_treble * 100).round()}%',
                      ),
                      const SizedBox(height: 20),

                      // Volume Normalization
                      _buildSwitch(
                        'Volume Normalization',
                        _normalize,
                        (value) {
                          setState(() => _normalize = value);
                          _updateSettings();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Range Compression
                      _buildSlider(
                        'Dynamic Range',
                        _dynamicRange,
                        0.0,
                        1.0,
                        (value) {
                          setState(() => _dynamicRange = value);
                          _updateSettings();
                        },
                        '${(_dynamicRange * 100).round()}%',
                      ),
                      const SizedBox(height: 20),

                      // Presets
                      const Text(
                        'Presets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPresetButton('Normal', () => _applyPreset(1.0, 0.0, 0.0, false, 1.0)),
                          _buildPresetButton('Bass Boost', () => _applyPreset(1.0, 0.3, 0.0, false, 0.8)),
                          _buildPresetButton('Treble Boost', () => _applyPreset(1.0, 0.0, 0.3, false, 0.8)),
                          _buildPresetButton('Loud', () => _applyPreset(1.5, 0.2, 0.2, true, 0.6)),
                          _buildPresetButton('Clear', () => _applyPreset(1.0, -0.1, 0.2, false, 0.9)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Disabled state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volume_off,
                        size: 64,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Volume Enhancement Disabled',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enable to access audio enhancement features',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset to defaults
                    setState(() {
                      _enabled = false;
                      _boost = 1.0;
                      _bass = 0.0;
                      _treble = 0.0;
                      _normalize = false;
                      _dynamicRange = 1.0;
                    });
                    _updateSettings();
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              displayValue,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: const Color(0xFF4CAF50),
          inactiveColor: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2a3441),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  void _applyPreset(double boost, double bass, double treble, bool normalize, double dynamicRange) {
    setState(() {
      _boost = boost;
      _bass = bass;
      _treble = treble;
      _normalize = normalize;
      _dynamicRange = dynamicRange;
    });
    _updateSettings();
  }
}
