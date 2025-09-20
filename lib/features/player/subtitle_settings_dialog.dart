import 'package:flutter/material.dart';
import '../../core/app_state.dart';

class SubtitleSettingsDialog extends StatefulWidget {
  final SubtitleSettings currentSettings;
  final ValueChanged<SubtitleSettings> onSettingsChanged;

  const SubtitleSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SubtitleSettingsDialog> createState() => _SubtitleSettingsDialogState();
}

class _SubtitleSettingsDialogState extends State<SubtitleSettingsDialog> {
  late SubtitleSettings _settings;
  late double _fontSize;
  late Color _textColor;
  late Color _backgroundColor;
  late FontWeight _fontWeight;
  late TextAlign _textAlign;
  late double _height;
  late double _letterSpacing;
  late double _wordSpacing;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    _fontSize = _settings.fontSize;
    _textColor = _settings.textColor;
    _backgroundColor = _settings.backgroundColor;
    _fontWeight = _settings.fontWeight;
    _textAlign = _settings.textAlign;
    _height = _settings.height;
    _letterSpacing = _settings.letterSpacing;
    _wordSpacing = _settings.wordSpacing;
  }

  @override
  void didUpdateWidget(SubtitleSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSettings != widget.currentSettings) {
      _settings = widget.currentSettings;
      _fontSize = _settings.fontSize;
      _textColor = _settings.textColor;
      _backgroundColor = _settings.backgroundColor;
      _fontWeight = _settings.fontWeight;
      _textAlign = _settings.textAlign;
      _height = _settings.height;
      _letterSpacing = _settings.letterSpacing;
      _wordSpacing = _settings.wordSpacing;
    }
  }

  void _updateSettings() {
    final newSettings = _settings.copyWith(
      fontSize: _fontSize,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      fontWeight: _fontWeight,
      textAlign: _textAlign,
      height: _height,
      letterSpacing: _letterSpacing,
      wordSpacing: _wordSpacing,
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
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.subtitles, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Subtitle Settings',
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

            // Preview
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: _buildPreviewText(),
              ),
            ),
            const SizedBox(height: 24),

            // Settings
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Font Size
                    _buildSlider(
                      'Font Size',
                      _fontSize,
                      12.0,
                      48.0,
                      (value) {
                        setState(() => _fontSize = value);
                        _updateSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Text Color
                    _buildColorPicker(
                      'Text Color',
                      _textColor,
                      (color) {
                        setState(() => _textColor = color);
                        _updateSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Background Color
                    _buildColorPicker(
                      'Background Color',
                      _backgroundColor,
                      (color) {
                        setState(() => _backgroundColor = color);
                        _updateSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Font Weight
                    _buildDropdown<FontWeight>(
                      'Font Weight',
                      _fontWeight,
                      FontWeight.values,
                      (value) {
                        setState(() => _fontWeight = value);
                        _updateSettings();
                      },
                      (value) => _getFontWeightName(value),
                    ),
                    const SizedBox(height: 16),

                    // Text Alignment
                    _buildDropdown<TextAlign>(
                      'Text Alignment',
                      _textAlign,
                      TextAlign.values,
                      (value) {
                        setState(() => _textAlign = value);
                        _updateSettings();
                      },
                      (value) => _getTextAlignName(value),
                    ),
                    const SizedBox(height: 16),

                    // Line Height
                    _buildSlider(
                      'Line Height',
                      _height,
                      0.8,
                      2.5,
                      (value) {
                        setState(() => _height = value);
                        _updateSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Letter Spacing
                    _buildSlider(
                      'Letter Spacing',
                      _letterSpacing,
                      -2.0,
                      5.0,
                      (value) {
                        setState(() => _letterSpacing = value);
                        _updateSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Word Spacing
                    _buildSlider(
                      'Word Spacing',
                      _wordSpacing,
                      -2.0,
                      10.0,
                      (value) {
                        setState(() => _wordSpacing = value);
                        _updateSettings();
                      },
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
                        _buildPresetButton('Default', () => _applyPreset(24.0, Colors.white, const Color(0xaa000000), FontWeight.normal, TextAlign.center, 1.4, 0.0, 0.0)),
                        _buildPresetButton('Large', () => _applyPreset(32.0, Colors.white, const Color(0xaa000000), FontWeight.bold, TextAlign.center, 1.6, 0.5, 1.0)),
                        _buildPresetButton('Small', () => _applyPreset(18.0, Colors.white, const Color(0xaa000000), FontWeight.normal, TextAlign.center, 1.2, 0.0, 0.0)),
                        _buildPresetButton('Yellow', () => _applyPreset(24.0, Colors.yellow, const Color(0xaa000000), FontWeight.normal, TextAlign.center, 1.4, 0.0, 0.0)),
                        _buildPresetButton('Cyan', () => _applyPreset(24.0, Colors.cyan, const Color(0xaa000000), FontWeight.normal, TextAlign.center, 1.4, 0.0, 0.0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset to defaults
                    setState(() {
                      _fontSize = 24.0;
                      _textColor = const Color(0xffffffff);
                      _backgroundColor = const Color(0xaa000000);
                      _fontWeight = FontWeight.normal;
                      _textAlign = TextAlign.center;
                      _height = 1.4;
                      _letterSpacing = 0.0;
                      _wordSpacing = 0.0;
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

  Widget _buildPreviewText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Sample Subtitle Text',
        style: TextStyle(
          color: _textColor,
          fontSize: _fontSize,
          fontWeight: _fontWeight,
          height: _height,
          letterSpacing: _letterSpacing,
          wordSpacing: _wordSpacing,
        ),
        textAlign: _textAlign,
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color currentColor,
    ValueChanged<Color> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Colors.white,
            Colors.yellow,
            Colors.cyan,
            Colors.green,
            Colors.orange,
            Colors.red,
            Colors.pink,
            Colors.purple,
            Colors.blue,
            Colors.black,
          ].map((color) {
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () => onChanged(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
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
              value.toStringAsFixed(1),
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

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T> onChanged,
    String Function(T) itemBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2a3441),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF2a3441),
              style: const TextStyle(color: Colors.white),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                );
              }).toList(),
              onChanged: (T? newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
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

  void _applyPreset(double fontSize, Color textColor, Color backgroundColor, FontWeight fontWeight, TextAlign textAlign, double height, double letterSpacing, double wordSpacing) {
    setState(() {
      _fontSize = fontSize;
      _textColor = textColor;
      _backgroundColor = backgroundColor;
      _fontWeight = fontWeight;
      _textAlign = textAlign;
      _height = height;
      _letterSpacing = letterSpacing;
      _wordSpacing = wordSpacing;
    });
    _updateSettings();
  }

  String _getFontWeightName(FontWeight weight) {
    switch (weight) {
      case FontWeight.w100: return 'Thin';
      case FontWeight.w200: return 'Extra Light';
      case FontWeight.w300: return 'Light';
      case FontWeight.w400: return 'Normal';
      case FontWeight.w500: return 'Medium';
      case FontWeight.w600: return 'Semi Bold';
      case FontWeight.w700: return 'Bold';
      case FontWeight.w800: return 'Extra Bold';
      case FontWeight.w900: return 'Black';
      default: return 'Normal';
    }
  }

  String _getTextAlignName(TextAlign align) {
    switch (align) {
      case TextAlign.left: return 'Left';
      case TextAlign.right: return 'Right';
      case TextAlign.center: return 'Center';
      case TextAlign.justify: return 'Justify';
      case TextAlign.start: return 'Start';
      case TextAlign.end: return 'End';
    }
  }
}
