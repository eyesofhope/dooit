import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/backup_service.dart';
import '../utils/app_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDataPrivacySection(),
          const SizedBox(height: 24),
          _buildBackupSettingsSection(),
          const SizedBox(height: 24),
          _buildManageBackupsSection(),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Data & Privacy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Data'),
            subtitle: const Text('Export tasks and categories to JSON'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isExporting ? null : _showExportDialog,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Import tasks from backup file'),
            trailing: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isImporting ? null : _pickAndImportFile,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSettingsSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final settings = settingsProvider.settings;
        
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Backup Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.backup),
                title: const Text('Automatic Backups'),
                subtitle: const Text('Create backups automatically'),
                value: settings.automaticBackupsEnabled,
                onChanged: (value) {
                  settingsProvider.updateSettings(
                    settings.copyWith(automaticBackupsEnabled: value),
                  );
                },
              ),
              if (settings.automaticBackupsEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Backup Frequency'),
                  subtitle: Text(
                    settings.backupFrequency == BackupFrequency.daily
                        ? 'Daily'
                        : 'Weekly',
                  ),
                  onTap: () => _showBackupFrequencyDialog(settings),
                ),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Keep Backups'),
                  subtitle: Text('Last ${settings.backupsToKeep} backups'),
                  onTap: () => _showKeepBackupsDialog(settings),
                ),
              ],
              SwitchListTile(
                secondary: const Icon(Icons.task_alt),
                title: const Text('Include Completed Tasks'),
                subtitle: const Text('Include completed tasks in backups'),
                value: settings.includeCompletedTasks,
                onChanged: (value) {
                  settingsProvider.updateSettings(
                    settings.copyWith(includeCompletedTasks: value),
                  );
                },
              ),
              if (settings.lastBackupAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Text(
                    'Last backup: ${DateFormat('MMM dd, yyyy HH:mm').format(settings.lastBackupAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton.icon(
                  onPressed: _isBackingUp ? null : _createManualBackup,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup),
                  label: const Text('Backup Now'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageBackupsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Manage Backups',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('View All Backups'),
            subtitle: const Text('Manage and restore backups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToBackupManagement(),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog() async {
    var includeCompleted = true;
    var includeSettings = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Include completed tasks'),
                  value: includeCompleted,
                  onChanged: (value) {
                    setState(() => includeCompleted = value ?? true);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Include settings'),
                  value: includeSettings,
                  onChanged: (value) {
                    setState(() => includeSettings = value ?? false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _performExport(
        includeCompleted: includeCompleted,
        includeSettings: includeSettings,
      );
    }
  }

  Future<void> _performExport({
    required bool includeCompleted,
    required bool includeSettings,
  }) async {
    setState(() => _isExporting = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final exportService = ExportService();

      final result = await exportService.exportToJson(
        tasks: taskProvider.allTasks,
        categories: taskProvider.categories,
        includeCompleted: includeCompleted,
        includeSettings: includeSettings,
      );

      setState(() => _isExporting = false);

      if (!mounted) return;

      if (result.success && result.filePath != null) {
        _showExportSuccessDialog(result.filePath!);
      } else {
        _showErrorSnackBar('Export failed: ${result.error}');
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        _showErrorSnackBar('Export error: $e');
      }
    }
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your data has been exported successfully.'),
            const SizedBox(height: 16),
            Text(
              'Location: ${filePath.split('/').last}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _shareFile(filePath);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'DoIt Backup - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Share error: $e');
      }
    }
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        _showErrorSnackBar('Could not read file');
        return;
      }

      await _showImportPreview(file.path!);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('File picker error: $e');
      }
    }
  }

  Future<void> _showImportPreview(String filePath) async {
    setState(() => _isImporting = true);

    try {
      final importService = ImportService();
      final taskProvider = context.read<TaskProvider>();

      final file = File(filePath);
      final content = await file.readAsString();

      final preview = await importService.previewImport(
        jsonContent: content,
        existingTasks: taskProvider.allTasks,
        existingCategories: taskProvider.categories,
      );

      setState(() => _isImporting = false);

      if (!mounted) return;

      _showImportConfirmationDialog(filePath, preview);
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        _showErrorSnackBar('Import preview error: $e');
      }
    }
  }

  void _showImportConfirmationDialog(
    String filePath,
    ImportPreview preview,
  ) {
    var mode = ImportMode.merge;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Import Data'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${preview.totalTasks} tasks, ${preview.totalCategories} categories'),
                  const SizedBox(height: 16),
                  if (preview.newTasks > 0)
                    Text('• ${preview.newTasks} new tasks'),
                  if (preview.existingTasks > 0)
                    Text('• ${preview.existingTasks} existing tasks'),
                  if (preview.newCategories > 0)
                    Text('• ${preview.newCategories} new categories'),
                  const SizedBox(height: 16),
                  const Text('Import Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<ImportMode>(
                    title: const Text('Merge'),
                    subtitle: const Text('Add new items, skip existing'),
                    value: ImportMode.merge,
                    groupValue: mode,
                    onChanged: (value) {
                      setState(() => mode = value!);
                    },
                  ),
                  RadioListTile<ImportMode>(
                    title: const Text('Replace'),
                    subtitle: const Text('Delete all existing data'),
                    value: ImportMode.replace,
                    groupValue: mode,
                    onChanged: (value) {
                      setState(() => mode = value!);
                    },
                  ),
                  if (mode == ImportMode.replace)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This will delete all existing data',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performImport(filePath, mode);
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performImport(String filePath, ImportMode mode) async {
    setState(() => _isImporting = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final importService = ImportService();

      if (mode == ImportMode.replace) {
        await taskProvider.clearAllData();
      }

      final file = File(filePath);
      final content = await file.readAsString();

      final result = await importService.importFromJson(
        jsonContent: content,
        mode: mode,
        existingTasks: taskProvider.allTasks,
        existingCategories: taskProvider.categories,
      );

      if (result.success) {
        final data = await importService.parseJsonFile(filePath);
        final tasks = (data['tasks'] as List).cast<Map<String, dynamic>>();
        final categories = (data['categories'] as List).cast<Map<String, dynamic>>();

        for (final catData in categories) {
          final exists = taskProvider.categories.any(
            (c) => c.name == catData['name'],
          );
          if (!exists || mode == ImportMode.replace) {
            await taskProvider.addCategory(
              importService.categoryFromJson(catData),
            );
          }
        }

        for (final taskData in tasks) {
          final exists = taskProvider.allTasks.any(
            (t) => t.id == taskData['id'],
          );
          if (!exists || mode == ImportMode.replace) {
            await taskProvider.addTask(
              importService.taskFromJson(taskData),
            );
          }
        }
      }

      setState(() => _isImporting = false);

      if (!mounted) return;

      if (result.success) {
        _showSuccessSnackBar(
          'Imported ${result.tasksImported} tasks, ${result.categoriesImported} categories',
        );
      } else {
        _showErrorSnackBar('Import failed: ${result.error}');
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        _showErrorSnackBar('Import error: $e');
      }
    }
  }

  Future<void> _createManualBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final backupService = BackupService();

      final filePath = await backupService.createJsonBackup(
        tasks: taskProvider.allTasks,
        categories: taskProvider.categories,
        type: BackupType.manual,
        includeCompleted: settingsProvider.settings.includeCompletedTasks,
      );

      await settingsProvider.updateLastBackupDate(DateTime.now());

      setState(() => _isBackingUp = false);

      if (mounted) {
        _showSuccessSnackBar('Backup created successfully');
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        _showErrorSnackBar('Backup error: $e');
      }
    }
  }

  void _showBackupFrequencyDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<BackupFrequency>(
                title: const Text('Daily'),
                value: BackupFrequency.daily,
                groupValue: settings.backupFrequency,
                onChanged: (value) {
                  context.read<SettingsProvider>().updateSettings(
                    settings.copyWith(backupFrequency: value),
                  );
                  Navigator.pop(context);
                },
              ),
              RadioListTile<BackupFrequency>(
                title: const Text('Weekly'),
                value: BackupFrequency.weekly,
                groupValue: settings.backupFrequency,
                onChanged: (value) {
                  context.read<SettingsProvider>().updateSettings(
                    settings.copyWith(backupFrequency: value),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showKeepBackupsDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keep Backups'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [3, 7, 14, 30].map((count) {
              return RadioListTile<int>(
                title: Text('Last $count backups'),
                value: count,
                groupValue: settings.backupsToKeep,
                onChanged: (value) {
                  context.read<SettingsProvider>().updateSettings(
                    settings.copyWith(backupsToKeep: value),
                  );
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _navigateToBackupManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackupManagementScreen(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  List<BackupInfo>? _backups;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      final backupService = BackupService();
      final backups = await backupService.listJsonBackups();
      
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading backups: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Backups'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _backups == null || _backups!.isEmpty
              ? _buildEmptyState()
              : _buildBackupsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backup,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No backups found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a backup to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _backups!.length,
      itemBuilder: (context, index) {
        final backup = _backups![index];
        return Dismissible(
          key: Key(backup.path),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Backup'),
                content: const Text('Are you sure you want to delete this backup?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            await _deleteBackup(backup);
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: backup.type == BackupType.automatic
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  backup.type == BackupType.automatic
                      ? Icons.backup
                      : Icons.file_copy,
                  color: backup.type == BackupType.automatic
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                backup.type == BackupType.automatic
                    ? 'Automatic Backup'
                    : 'Manual Backup',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(backup.formattedDate),
                  Text('${backup.taskCount} tasks • ${backup.formattedSize}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleBackupAction(value, backup),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      leading: Icon(Icons.restore),
                      title: Text('Restore'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackupAction(String action, BackupInfo backup) async {
    switch (action) {
      case 'restore':
        await _restoreBackup(backup);
        break;
      case 'share':
        await _shareBackup(backup);
        break;
      case 'delete':
        await _confirmAndDeleteBackup(backup);
        break;
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'Restore from backup? Current data will be replaced. '
          'An automatic backup of your current data will be created first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final taskProvider = context.read<TaskProvider>();
      final backupService = BackupService();
      final importService = ImportService();

      await backupService.createJsonBackup(
        tasks: taskProvider.allTasks,
        categories: taskProvider.categories,
        type: BackupType.automatic,
      );

      await taskProvider.clearAllData();

      final data = await importService.parseJsonFile(backup.path);
      final tasks = (data['tasks'] as List).cast<Map<String, dynamic>>();
      final categories = (data['categories'] as List).cast<Map<String, dynamic>>();

      for (final catData in categories) {
        await taskProvider.addCategory(
          importService.categoryFromJson(catData),
        );
      }

      for (final taskData in tasks) {
        await taskProvider.addTask(
          importService.taskFromJson(taskData),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: $e')),
        );
      }
    }
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      await Share.shareXFiles(
        [XFile(backup.path)],
        text: 'DoIt Backup - ${backup.formattedDate}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBackup(backup);
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    try {
      final backupService = BackupService();
      await backupService.deleteJsonBackup(backup.path);
      
      await _loadBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete error: $e')),
        );
      }
    }
  }
}
