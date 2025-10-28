# Performance Optimization Guide

This document outlines the performance optimizations implemented in the DoIt todo application.

## Optimizations Applied

### 1. Selector Pattern (Provider)

Replaced all `Consumer<TaskProvider>` widgets with `Selector` to minimize unnecessary rebuilds.

#### Benefits:
- **Granular rebuilds**: Only rebuild widgets when their specific data changes
- **Reduced widget tree rebuilds**: Parent widgets don't rebuild when unrelated data changes
- **Better performance**: Fewer `notifyListeners()` impacts

#### Implementation Details:

**TodoScreen:**
- `_buildAppTitle`: Selector for completion stats only (`completedTasks`, `totalTasks`)
- `_buildSearchField`: Selector for search query state
- `_buildStatsCard`: Selector for statistics data only
- `_buildFilterSection`: Multiple Selectors for categories, selected category, sort option, and filter option
- `_buildTaskList`: Selector for filtered task list

**TaskCard:**
- Uses Selector to fetch task by ID with custom `shouldRebuild` logic
- Rebuilds only when task fields actually change (title, description, dueDate, priority, category, isCompleted)

**TaskDetailScreen:**
- Selector for individual task by ID
- Rebuilds only when that specific task changes

**AddEditTaskDialog:**
- Selector for categories list in dropdown

**FilterChips:**
- Individual keys added to each chip for stable widget identity

### 2. Search Debouncing

Implemented custom `Debouncer` class (300ms delay) to prevent rapid provider updates during typing.

#### Benefits:
- Reduces `notifyListeners()` calls during typing
- Improves UI responsiveness
- Prevents CPU spikes from rapid list filtering

#### Implementation:
- `lib/utils/debouncer.dart`: Custom debouncer with dispose support
- `SearchBarWidget`: Converted to StatefulWidget with debouncing
- Shows loading indicator during debounce period
- Cancels debounce timer on widget disposal

### 3. ValueKey for ListView Items

Added `ValueKey(taskId)` to all TaskCard widgets in ListView.builder.

#### Benefits:
- Flutter can efficiently diff the widget tree
- Smooth animations during add/remove/reorder operations
- Prevents unnecessary state loss during list updates
- Stable widget identity across rebuilds

#### Implementation:
```dart
TaskCard(
  key: ValueKey(taskId),
  taskId: taskId,
  // ...
)
```

### 4. Const Constructors & Widgets

Used `const` constructors throughout the app where possible.

#### Benefits:
- Widget instances reused by Flutter
- Reduced memory allocation
- Faster widget tree reconciliation

#### Applied to:
- All stateless widgets with immutable properties
- PopupMenuItem widgets
- FilterChip widgets with const keys
- Icon, Text, SizedBox, and Padding widgets
- Separators in ListView.separated

### 5. ListView.builder Optimizations

Optimized ListView.builder configuration for better scrolling performance.

#### Optimizations:
- `const separatorBuilder`: Reuses separator widgets
- `addAutomaticKeepAlives: true`: Maintains scroll state
- `cacheExtent: 400`: Increases render cache for smoother scrolling
- `PageStorageKey`: Preserves scroll position

### 6. Performance Monitoring

Added Timeline events for critical operations in TaskProvider.

#### Monitored Operations:
- `setSearchQuery()`
- `setSortOption()`
- `setFilterOption()`
- `setSelectedCategory()`
- `_getFilteredAndSortedTasks()`

These can be viewed in Flutter DevTools Performance tab.

## Testing Performance

### Using Flutter DevTools

1. Run the app in profile mode:
   ```bash
   flutter run --profile
   ```

2. Open Flutter DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. Navigate to the Performance tab

4. Look for:
   - Frame render times (target: 16.67ms for 60fps)
   - Timeline events for TaskProvider operations
   - Widget rebuild counts

### Performance Overlay

Enable the performance overlay in the app:
```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

### Manual Testing

1. **Scrolling**: Smooth 60fps scrolling through 100+ tasks
2. **Search**: Type quickly - debouncing prevents lag
3. **Filters**: Switching filters should be instant
4. **Task Updates**: Toggling completion should only rebuild affected card

## Performance Metrics

### Before Optimization:
- TodoScreen rebuilt on every provider change
- Search triggered immediate provider updates
- No keys on ListView items
- Consumer widgets throughout

### After Optimization:
- Selective rebuilds with Selector
- 300ms search debouncing
- Stable ListView with keys
- const widgets where possible
- Timeline monitoring hooks

## Memory Optimization

### Const Widgets
All static widgets use const constructors to share instances in memory.

### Debouncer Cleanup
The debouncer properly disposes of timers to prevent memory leaks.

### Selector Efficiency
Selector only holds references to necessary data, not entire provider.

## Future Optimizations

Potential improvements for even better performance:

1. **Lazy loading**: Implement pagination for large task lists (1000+ items)
2. **Computed caching**: Cache expensive filter/sort operations with memoization
3. **Virtualized scrolling**: Use `ListView.builder` with smart itemBuilder caching
4. **Background isolates**: Move heavy operations to separate isolate
5. **Image caching**: If task attachments are added, implement proper image caching

## Best Practices for Maintainers

1. Always use `Selector` instead of `Consumer` when only specific data is needed
2. Add `const` to all stateless, immutable widgets
3. Use `ValueKey` or `ObjectKey` for list items with stable identities
4. Debounce high-frequency user inputs (search, text input)
5. Monitor performance with Timeline events for new operations
6. Test with 100+ items to ensure scalability

## Resources

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/rendering/best-practices)
- [Provider Package Documentation](https://pub.dev/packages/provider)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
