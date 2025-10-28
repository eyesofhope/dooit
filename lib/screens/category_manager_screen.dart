import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as models;
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/dialogs/add_edit_category_dialog.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final Set<String> _expandedCategories = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Add category',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            final entries = _buildEntries(context, provider);
            final systemCount = entries.where((entry) => entry.isSystem).length;

            if (entries.isEmpty) {
              return _buildEmptyState(context);
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              buildDefaultDragHandles: false,
              itemCount: entries.length,
              onReorder: (oldIndex, newIndex) =>
                  _handleReorder(context, provider, oldIndex, newIndex, systemCount),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final stats = provider.getCategoryStats(entry.name);
                final tasksPreview = provider.getTasksPreviewByCategory(entry.name);
                final isExpanded = _expandedCategories.contains(entry.name);
                return _buildCategoryCard(
                  context,
                  provider,
                  entry,
                  stats,
                  tasksPreview,
                  isExpanded,
                  index,
                  systemCount,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first category to better organize tasks.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  List<_CategoryEntry> _buildEntries(BuildContext context, TaskProvider provider) {
    final theme = Theme.of(context);
    final entries = <_CategoryEntry>[
      _CategoryEntry(
        name: AppConstants.systemCategoryAll,
        displayName: 'All',
        color: theme.colorScheme.primary,
        isSystem: true,
        icon: Icons.star_outline,
      ),
    ];

    entries.add(
      _CategoryEntry(
        name: AppConstants.uncategorizedCategory,
        displayName: 'Uncategorized',
        color: Colors.grey,
        isSystem: true,
        icon: Icons.inbox_outlined,
      ),
    );

    entries.addAll(
      provider.categories.map(
        (category) => _CategoryEntry(
          name: category.name,
          displayName: category.name,
          color: category.color,
          isSystem: false,
          category: category,
        ),
      ),
    );

    return entries;
  }

  Widget _buildCategoryCard(
    BuildContext context,
    TaskProvider provider,
    _CategoryEntry entry,
    CategoryStats stats,
    List<Task> previewTasks,
    bool isExpanded,
    int index,
    int systemCount,
  ) {
    final theme = Theme.of(context);
    final canReorder = !entry.isSystem;
    final canEdit = !entry.isSystem;
    final canDelete = !entry.isSystem && provider.categories.length > 1;

    final taskCountLabel = stats.totalTasks == 1
        ? '1 task'
        : '${stats.totalTasks} tasks';

    final completionLabel = stats.totalTasks == 0
        ? 'No tasks'
        : '${stats.completedTasks}/${stats.totalTasks} completed';

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey('category_${entry.name}'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedCategories.add(entry.name);
            } else {
              _expandedCategories.remove(entry.name);
            }
          });
        },
        leading: _buildLeading(context, entry, canReorder, index),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              avatar: Icon(
                Icons.assignment_outlined,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              label: Text(taskCountLabel),
              backgroundColor: theme.colorScheme.secondaryContainer,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit category',
              onPressed: canEdit ? () => _showEditCategoryDialog(entry.category!) : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: canDelete
                  ? 'Delete category'
                  : 'At least one category must remain',
              onPressed: canDelete ? () => _confirmDeleteCategory(entry.category!, provider) : null,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(context, stats),
                const SizedBox(height: 16),
                _buildQuickActions(context, provider, entry, stats),
                const SizedBox(height: 16),
                _buildTasksPreview(context, provider, entry, previewTasks),
              ],
            ),
          ),
        ],
      ),
    );

    if (entry.isSystem) {
      return KeyedSubtree(
        key: ValueKey(entry.name),
        child: card,
      );
    }

    return Dismissible(
      key: ValueKey(entry.name),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _showEditCategoryDialog(entry.category!);
          return false;
        } else {
          await _confirmDeleteCategory(entry.category!, provider);
          return false;
        }
      },
      background: _buildSwipeBackground(
        context,
        color: theme.colorScheme.primaryContainer,
        iconColor: theme.colorScheme.onPrimaryContainer,
        alignment: Alignment.centerLeft,
        icon: Icons.edit_outlined,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        color: theme.colorScheme.errorContainer,
        iconColor: theme.colorScheme.onErrorContainer,
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
      ),
      child: card,
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required Color color,
    required Color iconColor,
    required Alignment alignment,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: iconColor),
    );
  }

  Widget _buildLeading(
    BuildContext context,
    _CategoryEntry entry,
    bool canReorder,
    int index,
  ) {
    final color = entry.color;
    final circle = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: color.computeLuminance() > 0.5
              ? Colors.black.withOpacity(0.2)
              : Colors.white.withOpacity(0.6),
        ),
      ),
      child: entry.icon != null
          ? Icon(
              entry.icon,
              size: 18,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            )
          : null,
    );

    if (!canReorder) {
      return circle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Tooltip(
            message: 'Reorder',
            child: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        circle,
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, CategoryStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        final isWide = maxWidth >= 480;
        final children = <Widget>[
          _StatTile(label: 'Total', value: '${stats.totalTasks}'),
          _StatTile(label: 'Completed', value: '${stats.completedTasks}'),
          _StatTile(label: 'Pending', value: '${stats.pendingTasks}'),
          _StatTile(label: 'Overdue', value: '${stats.overdueTasks}'),
          _StatTile(
            label: 'Completion',
            value: '${stats.completionPercentage.toStringAsFixed(0)}%',
          ),
        ];

        if (isWide) {
          return Row(
            children: children
                .map(
                  (widget) => Expanded(child: widget),
                )
                .toList(),
          );
        }

        final tileWidth = maxWidth > 360 ? (maxWidth - 12) / 2 : maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (widget) => SizedBox(
                  width: tileWidth,
                  child: widget,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    TaskProvider provider,
    _CategoryEntry entry,
    CategoryStats stats,
  ) {
    final canComplete = stats.pendingTasks > 0 && !entry.isSystem;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: () {
            provider.setSelectedCategory(entry.name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category filter set to "${entry.displayName}"'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('View tasks'),
        ),
        FilledButton.icon(
          onPressed: canComplete
              ? () async {
                  final updatedCount =
                      await provider.completeAllTasksInCategory(entry.name);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        updatedCount == 0
                            ? 'No pending tasks to complete'
                            : 'Marked $updatedCount task${updatedCount == 1 ? '' : 's'} as completed',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Complete all'),
        ),
      ],
    );
  }

  Widget _buildTasksPreview(
    BuildContext context,
    TaskProvider provider,
    _CategoryEntry entry,
    List<Task> previewTasks,
  ) {
    if (previewTasks.isEmpty) {
      return Text(
        'No tasks in this category yet.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent tasks',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...previewTasks.map(
          (task) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: task.dueDate != null
                ? Text('Due ${AppUtils.formatDate(task.dueDate)}')
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _handleReorder(
    BuildContext context,
    TaskProvider provider,
    int oldIndex,
    int newIndex,
    int systemCount,
  ) async {
    if (oldIndex < systemCount) {
      return; // System categories cannot be moved.
    }

    if (newIndex <= systemCount) {
      newIndex = systemCount;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final adjustedOldIndex = oldIndex - systemCount;
    final adjustedNewIndex = newIndex - systemCount;

    if (adjustedOldIndex == adjustedNewIndex) {
      return;
    }

    final updatedOrder = List<models.Category>.from(provider.categories);
    final movedCategory = updatedOrder.removeAt(adjustedOldIndex);
    updatedOrder.insert(adjustedNewIndex, movedCategory);

    try {
      await provider.reorderCategories(updatedOrder);
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category order updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } on CategoryOperationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reorder categories. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditCategoryDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added')),
      );
    }
  }

  Future<void> _showEditCategoryDialog(models.Category category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditCategoryDialog(category: category),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated')),
      );
    }
  }

  Future<void> _confirmDeleteCategory(
    models.Category category,
    TaskProvider provider,
  ) async {
    final stats = provider.getCategoryStats(category.name);
    final hasTasks = stats.totalTasks > 0;
    String? replacement;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Delete category '${category.name}'?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTasks)
                    Text(
                      '${stats.totalTasks} task${stats.totalTasks == 1 ? '' : 's'} use this category.',
                    ),
                  if (hasTasks) const SizedBox(height: 16),
                  if (hasTasks)
                    DropdownButtonFormField<String?>(
                      value: replacement,
                      decoration: const InputDecoration(
                        labelText: 'Reassign tasks to',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Remove category from tasks'),
                        ),
                        ...provider.categories
                            .where((cat) => cat.name != category.name)
                            .map(
                              (cat) => DropdownMenuItem<String?>(
                                value: cat.name,
                                child: Text(cat.name),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (value) => setState(() => replacement = value),
                    ),
                  if (!hasTasks)
                    const Text('This category has no tasks. It will be deleted immediately.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      final updatedTasks =
          await provider.deleteCategory(category.name, replacementName: replacement);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedTasks == 0
                ? 'Category deleted'
                : 'Category deleted, $updatedTasks task${updatedTasks == 1 ? '' : 's'} updated',
          ),
        ),
      );
    } on CategoryOperationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete category. Please try again.'),
        ),
      );
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryEntry {
  const _CategoryEntry({
    required this.name,
    required this.displayName,
    required this.color,
    required this.isSystem,
    this.icon,
    this.category,
  });

  final String name;
  final String displayName;
  final Color color;
  final bool isSystem;
  final IconData? icon;
  final models.Category? category;
}
