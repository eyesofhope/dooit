import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart' as models;
import '../../providers/task_provider.dart';
import '../../utils/app_utils.dart';
import '../pickers/color_picker.dart';

class AddEditCategoryDialog extends StatefulWidget {
  const AddEditCategoryDialog({super.key, this.category});

  final models.Category? category;

  bool get isEditing => category != null;

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Color _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialName = widget.category?.name ?? '';
    _nameController = TextEditingController(text: initialName)
      ..addListener(() => setState(() {}));
    _selectedColor = widget.category?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _handleSubmit(),
          ),
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Dialog(
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildNameField(context),
                      const SizedBox(height: 16),
                      _buildPreviewChip(context),
                      const SizedBox(height: 24),
                      Text(
                        'Select a color',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ColorPicker(
                        selectedColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: _isSaving ? null : _handleSubmit,
                              child: Text(widget.isEditing ? 'Save' : 'Add'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          widget.isEditing ? 'Edit Category' : 'Add Category',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Close',
          onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.done,
      maxLength: AppConstants.maxCategoryNameLength,
      decoration: const InputDecoration(
        labelText: 'Category name',
        hintText: 'Enter category name',
        prefixIcon: Icon(Icons.label_outline),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Please enter a category name';
        }
        if (trimmed.length > AppConstants.maxCategoryNameLength) {
          return 'Name must be ${AppConstants.maxCategoryNameLength} characters or fewer';
        }

        final reservedMatch = AppConstants.reservedCategoryNames.any(
          (reserved) =>
              reserved.toLowerCase() == trimmed.toLowerCase(),
        );
        if (reservedMatch) {
          return '"$trimmed" is a reserved category name';
        }

        final provider = context.read<TaskProvider>();
        final existingName = widget.category?.name;
        final exists = provider.categoryExists(
          trimmed,
          excludeName: existingName,
        );
        if (exists) {
          return 'A category with this name already exists';
        }

        return null;
      },
      onFieldSubmitted: (_) => _handleSubmit(),
    );
  }

  Widget _buildPreviewChip(BuildContext context) {
    final name = _nameController.text.trim().isEmpty
        ? 'Category preview'
        : _nameController.text.trim();
    final textColor =
        _selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(name),
          labelStyle: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: _selectedColor.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSaving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final provider = context.read<TaskProvider>();
    final trimmedName = _nameController.text.trim();
    final category = models.Category(
      name: trimmedName,
      colorValue: _selectedColor.value,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await provider.updateCategory(widget.category!.name, category);
      } else {
        await provider.addCategory(category);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on CategoryOperationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save category. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}
