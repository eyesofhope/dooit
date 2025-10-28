import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_utils.dart';
import 'category_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _notificationsEnabled = false;
  bool _exactAlarmsEnabled = false;
  bool _isDynamicColorSupported = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _checkPermissions();
    _checkDynamicColorSupport();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _checkPermissions() async {
    final notificationService = NotificationService();
    final enabled = await notificationService.areNotificationsEnabled();
    
    bool exactAlarms = true;
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      exactAlarms = status.isGranted;
    }

    setState(() {
      _notificationsEnabled = enabled;
      _exactAlarmsEnabled = exactAlarms;
    });
  }

  Future<void> _checkDynamicColorSupport() async {
    if (Platform.isAndroid) {
      setState(() {
        _isDynamicColorSupported = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildAppearanceSection(context, colorScheme),
          _buildNotificationsSection(context, colorScheme),
          _buildDefaultsSection(context, colorScheme),
          _buildDataPrivacySection(context, colorScheme),
          _buildAboutSection(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  Widget _buildAppearanceSection(BuildContext context, ColorScheme colorScheme) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('APPEARANCE'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('Choose your preferred theme'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'system',
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: 'light',
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: 'dark',
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {settingsProvider.settings.themeMode},
                      onSelectionChanged: (Set<String> selected) {
                        settingsProvider.setThemeMode(selected.first);
                      },
                    ),
                  ),
                  if (_isDynamicColorSupported) ...[
                    _buildDivider(),
                    SwitchListTile(
                      secondary: Icon(Icons.auto_awesome, color: colorScheme.primary),
                      title: const Text('Dynamic Colors'),
                      subtitle: const Text('Use colors from your wallpaper (Android 12+)'),
                      value: settingsProvider.useDynamicColors,
                      onChanged: (value) {
                        settingsProvider.setUseDynamicColors(value);
                      },
                    ),
                  ],
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.format_size, color: colorScheme.primary),
                    title: const Text('Text Size'),
                    subtitle: Text('${(settingsProvider.textScale * 100).round()}%'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('A', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: settingsProvider.textScale,
                            min: 0.8,
                            max: 1.5,
                            divisions: 14,
                            label: '${(settingsProvider.textScale * 100).round()}%',
                            onChanged: (value) {
                              settingsProvider.setTextScale(value);
                            },
                          ),
                        ),
                        const Text('A', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsSection(BuildContext context, ColorScheme colorScheme) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('NOTIFICATIONS'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: _notificationsEnabled ? colorScheme.primary : colorScheme.error,
                    ),
                    title: const Text('Notification Permission'),
                    subtitle: Text(_notificationsEnabled ? 'Granted' : 'Not granted'),
                    trailing: !_notificationsEnabled
                        ? TextButton(
                            onPressed: () async {
                              await openAppSettings();
                              await _checkPermissions();
                            },
                            child: const Text('Open Settings'),
                          )
                        : null,
                  ),
                  if (Platform.isAndroid) ...[
                    _buildDivider(),
                    ListTile(
                      leading: Icon(
                        _exactAlarmsEnabled ? Icons.alarm_on : Icons.alarm_off,
                        color: _exactAlarmsEnabled ? colorScheme.primary : colorScheme.error,
                      ),
                      title: const Text('Exact Alarms'),
                      subtitle: Text(
                        _exactAlarmsEnabled
                            ? 'Enabled - Notifications will arrive on time'
                            : 'Required for precise notification timing',
                      ),
                      trailing: !_exactAlarmsEnabled
                          ? TextButton(
                              onPressed: () async {
                                await Permission.scheduleExactAlarm.request();
                                await _checkPermissions();
                              },
                              child: const Text('Enable'),
                            )
                          : null,
                    ),
                  ],
                  _buildDivider(),
                  SwitchListTile(
                    secondary: Icon(Icons.volume_up, color: colorScheme.primary),
                    title: const Text('Notification Sound'),
                    subtitle: const Text('Play sound with notifications'),
                    value: settingsProvider.notificationSound,
                    onChanged: (value) {
                      settingsProvider.setNotificationSound(value);
                    },
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    secondary: Icon(Icons.vibration, color: colorScheme.primary),
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate when notifications arrive'),
                    value: settingsProvider.notificationVibration,
                    onChanged: (value) {
                      settingsProvider.setNotificationVibration(value);
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: colorScheme.primary),
                    title: const Text('Test Notification'),
                    subtitle: const Text('Send a test notification'),
                    trailing: ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService().showInstantNotification(
                          '🧪 Test Notification',
                          'This is a test notification. If you see this, notifications are working!',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultsSection(BuildContext context, ColorScheme colorScheme) {
    return Consumer2<SettingsProvider, TaskProvider>(
      builder: (context, settingsProvider, taskProvider, child) {
        final categories = taskProvider.categories;
        final defaultCategoryId = settingsProvider.defaultCategoryId;
        final defaultCategoryLabel = defaultCategoryId == null
            ? 'None (Ask every time)'
            : defaultCategoryId == AppConstants.uncategorizedCategory
                ? 'Uncategorized'
                : categories.any((cat) => cat.name == defaultCategoryId)
                    ? defaultCategoryId
                    : 'Category removed';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('DEFAULT PREFERENCES'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.category_outlined, color: colorScheme.primary),
                    title: const Text('Manage Categories'),
                    subtitle: const Text('Create, edit, and reorder categories'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategoryManagerScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.flag_outlined, color: colorScheme.primary),
                    title: const Text('Default Priority'),
                    subtitle: Text(AppUtils.getPriorityLabel(settingsProvider.defaultPriority)),
                    trailing: DropdownButton<TaskPriority>(
                      value: settingsProvider.defaultPriority,
                      underline: const SizedBox(),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: AppUtils.getPriorityColor(priority),
                              ),
                              const SizedBox(width: 8),
                              Text(AppUtils.getPriorityLabel(priority)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (priority) {
                        if (priority != null) {
                          settingsProvider.setDefaultPriority(priority);
                        }
                      },
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.category_outlined, color: colorScheme.primary),
                    title: const Text('Default Category'),
                    subtitle: Text(defaultCategoryLabel),
                    trailing: DropdownButton<String?>(
                      value: settingsProvider.defaultCategoryId,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        const DropdownMenuItem(
                          value: AppConstants.uncategorizedCategory,
                          child: Text('Uncategorized'),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (categoryId) {
                        settingsProvider.setDefaultCategory(categoryId);
                      },
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.access_time, color: colorScheme.primary),
                    title: const Text('Default Reminder Time'),
                    subtitle: Text(
                      'Remind at ${settingsProvider.defaultReminderTime.format(context)} on due date',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: settingsProvider.defaultReminderTime,
                        );
                        if (time != null) {
                          settingsProvider.setDefaultReminderTime(time);
                        }
                      },
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.event_outlined, color: colorScheme.primary),
                    title: const Text('Default Due Date'),
                    subtitle: Text(_getDefaultDueDateLabel(settingsProvider.defaultDueDate)),
                    trailing: DropdownButton<DefaultDueDate>(
                      value: settingsProvider.defaultDueDate,
                      underline: const SizedBox(),
                      items: DefaultDueDate.values.map((dueDate) {
                        return DropdownMenuItem(
                          value: dueDate,
                          child: Text(_getDefaultDueDateLabel(dueDate)),
                        );
                      }).toList(),
                      onChanged: (dueDate) {
                        if (dueDate != null) {
                          settingsProvider.setDefaultDueDate(dueDate);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getDefaultDueDateLabel(DefaultDueDate dueDate) {
    switch (dueDate) {
      case DefaultDueDate.none:
        return 'None';
      case DefaultDueDate.today:
        return 'Today';
      case DefaultDueDate.tomorrow:
        return 'Tomorrow';
      case DefaultDueDate.nextWeek:
        return 'Next Week';
    }
  }

  Widget _buildDataPrivacySection(BuildContext context, ColorScheme colorScheme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('DATA & PRIVACY'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.storage_outlined, color: colorScheme.primary),
                    title: const Text('Storage Information'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildStorageRow('Total tasks', '${taskProvider.totalTasks}'),
                        _buildStorageRow('Completed tasks', '${taskProvider.completedTasks}'),
                        _buildStorageRow('Pending tasks', '${taskProvider.pendingTasks}'),
                        _buildStorageRow('Categories', '${taskProvider.categories.length}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.clear_all, color: colorScheme.primary),
                    title: const Text('Clear Completed Tasks'),
                    subtitle: Text('Delete ${taskProvider.completedTasks} completed tasks'),
                    trailing: ElevatedButton(
                      onPressed: taskProvider.completedTasks > 0
                          ? () => _showClearCompletedDialog(context, taskProvider)
                          : null,
                      child: const Text('Clear'),
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: colorScheme.error),
                    title: Text(
                      'Clear All Data',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    subtitle: const Text('Delete all tasks, categories, and settings'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed: () => _showClearAllDataDialog(context, taskProvider),
                      child: const Text('Clear All'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ABOUT'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: colorScheme.primary),
                title: const Text('App Version'),
                subtitle: Text(
                  _packageInfo != null
                      ? 'Version ${_packageInfo!.version} (Build ${_packageInfo!.buildNumber})'
                      : 'Loading...',
                ),
              ),
              _buildDivider(),
              ListTile(
                leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                title: const Text('Open Source Licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: _packageInfo?.version ?? AppConstants.appVersion,
                    applicationIcon: Icon(Icons.check_circle, size: 48, color: colorScheme.primary),
                  );
                },
              ),
              _buildDivider(),
              ListTile(
                leading: Icon(Icons.code, color: colorScheme.primary),
                title: const Text('Developer Info'),
                subtitle: const Text('Built with Flutter & Material Design 3'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDeveloperDialog(context);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showClearCompletedDialog(BuildContext context, TaskProvider taskProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks?'),
        content: Text(
          'This will permanently delete ${taskProvider.completedTasks} completed tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _clearCompletedTasks(taskProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completed tasks cleared successfully'),
          ),
        );
      }
    }
  }

  Future<void> _clearCompletedTasks(TaskProvider taskProvider) async {
    final completedTasks = taskProvider.allTasks.where((task) => task.isCompleted).toList();
    for (final task in completedTasks) {
      await taskProvider.deleteTask(task.id);
    }
  }

  Future<void> _showClearAllDataDialog(BuildContext context, TaskProvider taskProvider) async {
    final controller = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete ALL tasks, categories, and reset settings. This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Type DELETE to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              if (controller.text == 'DELETE') {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (confirmed == true && mounted) {
      await taskProvider.clearAllData();
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.resetToDefaults();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
          ),
        );
      }
    }
  }

  void _showDeveloperDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DoIt - Task Manager', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('A modern task management app built with:'),
            const SizedBox(height: 8),
            const Text('• Flutter 3.9'),
            const Text('• Material Design 3'),
            const Text('• Hive for local storage'),
            const Text('• Provider for state management'),
            const Text('• Local notifications'),
            const SizedBox(height: 16),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('• Adaptive layouts'),
            const Text('• Dark mode support'),
            const Text('• Priority levels & categories'),
            const Text('• Task reminders'),
            const Text('• Search & filter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
