import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../models/app_settings.dart';
import '../models/recurrence.dart';
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

  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  Set<int> _selectedWeekdays = {DateTime.monday};
  int? _selectedMonthDay;
  bool _useLastDayOfMonth = false;
  DateTime? _recurrenceEndDate;

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

    if (_selectedDueDate != null) {
      _selectedWeekdays = {_selectedDueDate!.weekday};
      _selectedMonthDay = _selectedDueDate!.day;
      _useLastDayOfMonth = _isLastDayOfMonth(_selectedDueDate!);
    } else {
      _selectedWeekdays = {DateTime.monday};
      _selectedMonthDay = null;
      _useLastDayOfMonth = false;
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

    final recurrenceType = task.recurrenceRule?.type ?? task.recurrenceType;
    final recurrenceRule = task.recurrenceRule;

    if (recurrenceType != null && recurrenceType != RecurrenceType.none) {
      _isRecurring = true;
      _recurrenceType = recurrenceType;
      _recurrenceInterval = task.recurrenceInterval ?? recurrenceRule?.interval ?? 1;
      _recurrenceEndDate = task.recurrenceEndDate ?? recurrenceRule?.endDate;

      if (recurrenceType == RecurrenceType.weekly) {
        final weekdays = recurrenceRule?.weekdays;
        if (weekdays != null && weekdays.isNotEmpty) {
          _selectedWeekdays = weekdays.toSet();
        } else if (task.dueDate != null) {
          _selectedWeekdays = {task.dueDate!.weekday};
        } else {
          _selectedWeekdays = {DateTime.monday};
        }
      } else {
        _selectedWeekdays = task.dueDate != null
            ? {task.dueDate!.weekday}
            : {DateTime.monday};
      }

      if (recurrenceType == RecurrenceType.monthly) {
        _useLastDayOfMonth = recurrenceRule?.useLastDayOfMonth ??
            (task.dueDate != null && _isLastDayOfMonth(task.dueDate!));
        _selectedMonthDay = recurrenceRule?.monthDay ?? task.dueDate?.day;
      } else {
        _useLastDayOfMonth = false;
        _selectedMonthDay = task.dueDate?.day;
      }
    } else {
      _isRecurring = false;
      _recurrenceType = RecurrenceType.daily;
      _recurrenceInterval = 1;
      _recurrenceEndDate = null;
      _selectedWeekdays = task.dueDate != null
          ? {task.dueDate!.weekday}
          : {DateTime.monday};
      _selectedMonthDay = task.dueDate?.day;
      _useLastDayOfMonth = task.dueDate != null && _isLastDayOfMonth(task.dueDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isLastDayOfMonth(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return date.day == lastDay;
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
                  _buildRecurrenceSection(),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(),

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
            DropdownButtonFormField<String>(
              value: categories.any((cat) => cat.name == _selectedCategory)
                  ? _selectedCategory
                  : categories.first.name,
              decoration: const InputDecoration(
                hintText: 'Select category',
                prefixIcon: Icon(Icons.category),
              ),
              items: categories.map((category) {
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
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
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

  Widget _buildRecurrenceSection() {
    final bool canEnableRecurrence = _selectedDueDate != null;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Repeat'),
          subtitle: Text(
            canEnableRecurrence
                ? _buildRecurrenceSummary()
                : 'Set a due date to enable recurrence',
          ),
          value: _isRecurring && canEnableRecurrence,
          onChanged: (value) {
            if (!canEnableRecurrence) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Set a due date before enabling recurrence'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            setState(() {
              _isRecurring = value;
              if (value) {
                if (_recurrenceType == RecurrenceType.none) {
                  _recurrenceType = RecurrenceType.daily;
                }
                _recurrenceInterval = 1;
                if (_selectedDueDate != null) {
                  _selectedWeekdays = {_selectedDueDate!.weekday};
                  _selectedMonthDay = _selectedDueDate!.day;
                  _useLastDayOfMonth = _isLastDayOfMonth(_selectedDueDate!);
                }
              } else {
                _recurrenceType = RecurrenceType.daily;
                _recurrenceInterval = 1;
                _recurrenceEndDate = null;
              }
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_isRecurring && canEnableRecurrence) ...[
          const SizedBox(height: 12),
          _buildRecurrenceTypeSelector(),
          const SizedBox(height: 12),
          _buildRecurrenceIntervalSelector(),
          if (_recurrenceType == RecurrenceType.weekly) ...[
            const SizedBox(height: 12),
            _buildWeeklyDaySelector(),
          ],
          if (_recurrenceType == RecurrenceType.monthly) ...[
            const SizedBox(height: 12),
            _buildMonthlyDaySelector(),
          ],
          const SizedBox(height: 12),
          _buildRecurrenceEndDatePicker(),
          const SizedBox(height: 8),
          Text(
            _buildRecurrenceSummary(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrenceTypeSelector() {
    final options = <RecurrenceType>[
      RecurrenceType.daily,
      RecurrenceType.weekly,
      RecurrenceType.monthly,
      RecurrenceType.yearly,
    ];

    final effectiveType = _recurrenceType == RecurrenceType.none
        ? RecurrenceType.daily
        : _recurrenceType;

    return DropdownButtonFormField<RecurrenceType>(
      value: effectiveType,
      decoration: const InputDecoration(
        labelText: 'Frequency',
        prefixIcon: Icon(Icons.repeat),
      ),
      items: options
          .map(
            (type) => DropdownMenuItem<RecurrenceType>(
              value: type,
              child: Text(_recurrenceTypeLabel(type)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _recurrenceType = value;
          _recurrenceInterval = 1;

          if (value == RecurrenceType.weekly) {
            if (_selectedWeekdays.isEmpty || _selectedWeekdays.length == 1) {
              if (_selectedDueDate != null) {
                _selectedWeekdays = {_selectedDueDate!.weekday};
              } else if (_selectedWeekdays.isEmpty) {
                _selectedWeekdays = {DateTime.monday};
              }
            }
          }

          if (value == RecurrenceType.monthly) {
            if (_selectedDueDate != null) {
              _selectedMonthDay = _selectedDueDate!.day;
              _useLastDayOfMonth = _isLastDayOfMonth(_selectedDueDate!);
            } else {
              _selectedMonthDay ??= 1;
              _useLastDayOfMonth = false;
            }
          } else {
            _useLastDayOfMonth = false;
          }
        });
      },
    );
  }

  Widget _buildRecurrenceIntervalSelector() {
    final maxInterval = _maxIntervalForType(_recurrenceType);
    if (_recurrenceInterval > maxInterval) {
      _recurrenceInterval = maxInterval;
    }

    final options = List<int>.generate(maxInterval, (index) => index + 1);

    return Row(
      children: [
        Text(
          'Every',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 88,
          child: DropdownButton<int>(
            value: _recurrenceInterval,
            isExpanded: true,
            underline: const SizedBox(),
            items: options
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _recurrenceInterval = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _intervalLabel(_recurrenceInterval),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildWeeklyDaySelector() {
    const weekdayOrder = <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekdayOrder.map((day) {
            final isSelected = _selectedWeekdays.contains(day);
            return FilterChip(
              label: Text(_weekdayLabel(day)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final updated = Set<int>.from(_selectedWeekdays);
                  if (selected) {
                    updated.add(day);
                  } else {
                    if (updated.length > 1) {
                      updated.remove(day);
                    }
                  }
                  if (updated.isEmpty) {
                    updated.add(day);
                  }
                  _selectedWeekdays = updated;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyDaySelector() {
    final options = List<int>.generate(31, (index) => index + 1);
    int fallbackDay =
        _selectedMonthDay ?? _selectedDueDate?.day ?? DateTime.now().day;
    if (fallbackDay < 1 || fallbackDay > 31) {
      fallbackDay = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On day',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: fallbackDay,
          decoration: const InputDecoration(
            labelText: 'Day of month',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          items: options
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                ),
              )
              .toList(),
          onChanged: _useLastDayOfMonth
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedMonthDay = value;
                  });
                },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use last day of each month'),
          value: _useLastDayOfMonth,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _useLastDayOfMonth = value;
              if (value) {
                _selectedMonthDay = null;
              } else if (_selectedDueDate != null) {
                _selectedMonthDay = _selectedDueDate!.day;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildRecurrenceEndDatePicker() {
    final theme = Theme.of(context);
    final DateTime baseDate = _selectedDueDate ?? DateTime.now();
    final DateTime initialDate = _recurrenceEndDate ?? baseDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End date',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.flag_circle_outlined),
                label: Text(
                  _recurrenceEndDate != null
                      ? AppUtils.formatDate(_recurrenceEndDate)
                      : 'Never',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        initialDate.isBefore(baseDate) ? baseDate : initialDate,
                    firstDate: baseDate,
                    lastDate: baseDate.add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() {
                      final hour = _selectedDueTime?.hour ??
                          _selectedDueDate?.hour ??
                          9;
                      final minute = _selectedDueTime?.minute ??
                          _selectedDueDate?.minute ??
                          0;
                      _recurrenceEndDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        hour,
                        minute,
                      );
                    });
                  }
                },
              ),
            ),
            if (_recurrenceEndDate != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _recurrenceEndDate = null;
                  });
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear end date',
              ),
          ],
        ),
      ],
    );
  }

  String _buildRecurrenceSummary() {
    if (!_isRecurring) {
      return 'Task will not repeat';
    }
    if (_selectedDueDate == null) {
      return 'Select a due date to configure recurrence';
    }

    final buffer = StringBuffer();
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        buffer.write(
          _recurrenceInterval == 1
              ? 'Repeats every day'
              : 'Repeats every $_recurrenceInterval days',
        );
        break;
      case RecurrenceType.weekly:
        final days = _selectedWeekdays.toList()..sort();
        final labels = days.map(_weekdayLabel).join(', ');
        buffer.write(
          _recurrenceInterval == 1
              ? 'Repeats weekly on $labels'
              : 'Repeats every $_recurrenceInterval weeks on $labels',
        );
        break;
      case RecurrenceType.monthly:
        String dayLabel;
        if (_useLastDayOfMonth) {
          dayLabel = 'the last day';
        } else {
          final day = _selectedMonthDay ?? _selectedDueDate!.day;
          dayLabel = 'day $day';
        }
        buffer.write(
          _recurrenceInterval == 1
              ? 'Repeats monthly on $dayLabel'
              : 'Repeats every $_recurrenceInterval months on $dayLabel',
        );
        break;
      case RecurrenceType.yearly:
        final formatted = AppUtils.formatDate(_selectedDueDate);
        buffer.write(
          _recurrenceInterval == 1
              ? 'Repeats yearly on $formatted'
              : 'Repeats every $_recurrenceInterval years on $formatted',
        );
        break;
      case RecurrenceType.none:
        return 'Task will not repeat';
    }

    if (_recurrenceEndDate != null) {
      buffer.write(' until ${AppUtils.formatDate(_recurrenceEndDate)}');
    } else {
      buffer.write(' with no end date');
    }

    return buffer.toString();
  }

  String _recurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Day';
    }
  }

  int _maxIntervalForType(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 30;
      case RecurrenceType.weekly:
        return 12;
      case RecurrenceType.monthly:
        return 12;
      case RecurrenceType.yearly:
        return 5;
      case RecurrenceType.none:
        return 30;
    }
  }

  String _intervalLabel(int intervalValue) {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return intervalValue == 1 ? 'day' : 'days';
      case RecurrenceType.weekly:
        return intervalValue == 1 ? 'week' : 'weeks';
      case RecurrenceType.monthly:
        return intervalValue == 1 ? 'month' : 'months';
      case RecurrenceType.yearly:
        return intervalValue == 1 ? 'year' : 'years';
      case RecurrenceType.none:
        return intervalValue == 1 ? 'day' : 'days';
    }
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

        if (_selectedWeekdays.length <= 1) {
          _selectedWeekdays = {date.weekday};
        }

        if (_isLastDayOfMonth(date)) {
          if (_recurrenceType == RecurrenceType.monthly) {
            _useLastDayOfMonth = true;
            _selectedMonthDay = null;
          } else if (!_useLastDayOfMonth) {
            _selectedMonthDay = date.day;
          }
        } else {
          _selectedMonthDay = date.day;
          if (_recurrenceType == RecurrenceType.monthly) {
            _useLastDayOfMonth = false;
          }
        }

        if (_recurrenceEndDate != null &&
            _recurrenceEndDate!.isBefore(
              DateTime(date.year, date.month, date.day),
            )) {
          _recurrenceEndDate = null;
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
      _isRecurring = false;
      _recurrenceType = RecurrenceType.daily;
      _recurrenceInterval = 1;
      _selectedWeekdays = {DateTime.monday};
      _selectedMonthDay = null;
      _useLastDayOfMonth = false;
      _recurrenceEndDate = null;
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

    if (_isRecurring) {
      if (dueDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a due date before enabling recurrence.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (dueDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring tasks must have a future due date.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final RecurrenceType recurrenceType =
        _isRecurring ? _recurrenceType : RecurrenceType.none;
    final int recurrenceInterval = _isRecurring ? _recurrenceInterval : 1;
    final DateTime? recurrenceEndDate =
        _isRecurring ? _recurrenceEndDate : null;
    final Recurrence? recurrenceRule = _isRecurring
        ? Recurrence(
            type: recurrenceType,
            interval: recurrenceInterval,
            endDate: recurrenceEndDate,
            weekdays: recurrenceType == RecurrenceType.weekly
                ? (_selectedWeekdays.toList()..sort())
                : null,
            monthDay: recurrenceType == RecurrenceType.monthly &&
                    !_useLastDayOfMonth
                ? (_selectedMonthDay ?? dueDateTime!.day)
                : null,
            useLastDayOfMonth:
                recurrenceType == RecurrenceType.monthly && _useLastDayOfMonth,
          )
        : null;

    if (_isEditing) {
      final existing = widget.task!;
      final updatedTask = Task(
        id: existing.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: dueDateTime,
        isCompleted: existing.isCompleted,
        createdAt: existing.createdAt,
        completedAt: existing.isCompleted ? existing.completedAt : null,
        hasNotification: _hasNotification && dueDateTime != null,
        recurrenceType: recurrenceType,
        recurrenceInterval: recurrenceInterval,
        recurrenceEndDate: recurrenceEndDate,
        parentRecurringTaskId:
            _isRecurring ? existing.parentRecurringTaskId : null,
        isRecurringInstance:
            _isRecurring ? existing.isRecurringInstance : false,
        recurrenceRule: recurrenceRule,
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
        recurrenceType: recurrenceType,
        recurrenceInterval: recurrenceInterval,
        recurrenceEndDate: recurrenceEndDate,
        recurrenceRule: recurrenceRule,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.of(context).pop();

    String message =
        _isEditing ? 'Task updated successfully' : 'Task added successfully';
    if (_hasNotification && dueDateTime != null) {
      final timeUntil = AppUtils.getTimeUntil(dueDateTime);
      message += '\nReminder set for $timeUntil';
    }
    if (_isRecurring) {
      message += '\n${_buildRecurrenceSummary()}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: _hasNotification && dueDateTime != null
            ? SnackBarAction(
                label: 'Test Now',
                onPressed: () {
                  NotificationService().showInstantNotification(
                    '📋 Task Reminder: ${_titleController.text.trim()}',
                    _descriptionController.text.trim().isNotEmpty
                        ? '${_descriptionController.text.trim()}\n\nTap to view details'
                        : 'Don\'t forget to complete this task!\n\nTap to view details',
                  );
                },
              )
            : null,
      ),
    );
  }
}
