import 'package:flutter/material.dart';
import '../../utils/app_utils.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  static const List<_NamedColor> _colorOptions = [
    _NamedColor('Red', Colors.red),
    _NamedColor('Pink', Colors.pink),
    _NamedColor('Purple', Colors.purple),
    _NamedColor('Deep Purple', Colors.deepPurple),
    _NamedColor('Indigo', Colors.indigo),
    _NamedColor('Blue', Colors.blue),
    _NamedColor('Light Blue', Colors.lightBlue),
    _NamedColor('Cyan', Colors.cyan),
    _NamedColor('Teal', Colors.teal),
    _NamedColor('Green', Colors.green),
    _NamedColor('Light Green', Colors.lightGreen),
    _NamedColor('Lime', Colors.lime),
    _NamedColor('Yellow', Colors.yellow),
    _NamedColor('Amber', Colors.amber),
    _NamedColor('Orange', Colors.orange),
    _NamedColor('Deep Orange', Colors.deepOrange),
    _NamedColor('Brown', Colors.brown),
    _NamedColor('Grey', Colors.grey),
    _NamedColor('Blue Grey', Colors.blueGrey),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorOptions
          .map(
            (option) => _ColorOptionChip(
              option: option,
              isSelected: selectedColor.value == option.color.value,
              onSelected: onColorSelected,
            ),
          )
          .toList(),
    );
  }
}

class _ColorOptionChip extends StatelessWidget {
  const _ColorOptionChip({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final _NamedColor option;
  final bool isSelected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.onSurface
        : option.color.withOpacity(0.3);
    final foregroundColor = option.color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Semantics(
      label: option.name,
      button: true,
      selected: isSelected,
      child: Tooltip(
        message: option.name,
        child: InkWell(
          onTap: () => onSelected(option.color),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: AppConstants.shortAnimationDuration,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: option.color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: foregroundColor,
                    size: 22,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _NamedColor {
  const _NamedColor(this.name, this.color);

  final String name;
  final Color color;
}
