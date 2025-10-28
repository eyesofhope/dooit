import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../models/app_settings.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_utils.dart';

class AddEditTaskDialog extends StatefulWidget {
  final Task? task;

  const AddEditTaskDialog({super.key, this.task});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  String _selectedCategory = AppConstants.defaultCategory;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _hasNotification = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeFromTask();
    } else {
      _initializeFromSettings();
    }
  }

  void _initializeFromSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _selectedPriority = settingsProvider.defaultPriority;
    
    if (settingsProvider.defaultCategoryId != null) {
      _selectedCategory = settingsProvider.defaultCategoryId!;
    }

    switch (settingsProvider.defaultDueDate) {
      case DefaultDueDate.today:
        _selectedDueDate = DateTime.now();
        break;
      case DefaultDueDate.tomorrow:
        _selectedDueDate = DateTime.now().add(const Duration(days: 1));
        break;
      case DefaultDueDate.nextWeek:
        _selectedDueDate = DateTime.now().add(const Duration(days: 7));
        break;
      case DefaultDueDate.none:
        _selectedDueDate = null;
        break;
    }

    if (_selectedDueDate != null) {
      final defaultTime = settingsProvider.defaultReminderTime;
      _selectedDueDate = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        defaultTime.hour,
        defaultTime.minute,
      );
      _selectedDueTime = defaultTime;
    }
  }

  void _initializeFromTask() {
    final task = widget.task!;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _selectedPriority = task.priority;
    _selectedCategory = task.category;
    _selectedDueDate = task.dueDate;
    _selectedDueTime = task.dueDate != null
        ? TimeOfDay.fromDateTime(task.dueDate!)
        : null;
    _hasNotification = task.hasNotification;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildPrioritySelector(),
                  const SizedBox(height: 16),
                  _buildDueDateSelector(),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          _isEditing ? 'Edit Task' : 'Add New Task',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Task Title',
        hintText: 'Enter task title',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a task title';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
      maxLength: 100,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Enter task description',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 500,
    );
  }

  Widget _buildCategorySelector() {
    // Selector rebuilds dropdown only when categories change.
    return Selector<TaskProvider, List<models.Category>>(
      selector: (context, provider) => provider.categories,
      builder: (context, categories, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final categoryNames =
                    categories.map((category) => category.name).toList();

                if (!categoryNames.contains(AppConstants.uncategorizedCategory)) {
                  categoryNames.add(AppConstants.uncategorizedCategory);
                }

                final fallback = categories.isNotEmpty
                    ? categories.first.name
                    : AppConstants.uncategorizedCategory;
                final selectedValue = categoryNames.contains(_selectedCategory)
                    ? _selectedCategory
                    : fallback;

                if (_selectedCategory != selectedValue) {
                  _selectedCategory = selectedValue;
                }

                return DropdownButtonFormField<String>(
                  value: selectedValue,
                  decoration: const InputDecoration(
                    hintText: 'Select category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    ...categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.name,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }),
                    DropdownMenuItem<String>(
                      value: AppConstants.uncategorizedCategory,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Uncategorized'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((priority) {
            final color = AppUtils.getPriorityColor(priority);
            final label = AppUtils.getPriorityLabel(priority);
            final isSelected = _selectedPriority == priority;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    }
                  },
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? color : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date & Time (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDueDate != null
                            ? AppUtils.formatDate(_selectedDueDate)
                            : 'Select date',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _selectedDueDate != null ? _selectDueTime : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedDueDate != null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _selectedDueDate != null
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDueTime != null
                            ? _selectedDueTime!.format(context)
                            : 'Select time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedDueDate != null
                              ? null
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDueDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: _clearDueDate,
              icon: const Icon(Icons.clear),
              label: const Text('Clear due date'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: const Text('Enable Reminder'),
      subtitle: _selectedDueDate != null
          ? const Text('Get notified when this task is due')
          : const Text('Set a due date to enable reminders'),
      value: _hasNotification && _selectedDueDate != null,
      onChanged: _selectedDueDate != null
          ? (value) {
              setState(() {
                _hasNotification = value;
              });
            }
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(_isEditing ? 'Update' : 'Add Task'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
        if (_selectedDueTime == null) {
          _selectedDueTime = const TimeOfDay(hour: 9, minute: 0);
        }
      });
    }
  }

  Future<void> _selectDueTime() async {
    if (_selectedDueDate == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedDueTime = time;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
      _selectedDueTime = null;
      _hasNotification = false;
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    DateTime? dueDateTime;
    if (_selectedDueDate != null) {
      dueDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedDueTime?.hour ?? 9,
        _selectedDueTime?.minute ?? 0,
      );
    }

    if (_isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: dueDateTime,
        hasNotification: _hasNotification && dueDateTime != null,
      );
      taskProvider.updateTask(updatedTask);
    } else {
      final newTask = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: dueDateTime,
        hasNotification: _hasNotification && dueDateTime != null,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.of(context).pop();

    // Show success message with notification info
    String message = _isEditing ? 'Task updated successfully' : 'Task added successfully';
    if (_hasNotification && dueDateTime != null) {
      final timeUntil = AppUtils.getTimeUntil(dueDateTime);
      message += '\nReminder set for $timeUntil';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: _hasNotification && dueDateTime != null ? 
          SnackBarAction(
            label: 'Test Now',
            onPressed: () {
              // Show an immediate test notification
              NotificationService().showInstantNotification(
                '📋 Task Reminder: ${_titleController.text.trim()}',
                _descriptionController.text.trim().isNotEmpty 
                    ? '${_descriptionController.text.trim()}\n\nTap to view details'
                    : 'Don\'t forget to complete this task!\n\nTap to view details',
              );
            },
          ) : null,
      ),
    );
  }
}
