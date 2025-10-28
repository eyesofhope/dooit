# Backup File Format Documentation

## Overview

DoIt uses a human-readable JSON format for backups, making it easy to inspect, migrate, and share task data across devices.

## File Format Specification

### File Naming Convention

- **Manual Backups**: `dooit_manual_backup_YYYY-MM-DD_HHmmss.json`
- **Automatic Backups**: `dooit_auto_backup_YYYY-MM-DD_HHmmss.json`

### JSON Structure

```json
{
  "version": "1.0",
  "exportDate": "2024-01-15T10:30:00.000Z",
  "appVersion": "1.0.0",
  "schemaVersion": 1,
  "backupType": "manual",
  "taskCount": 45,
  "categoryCount": 8,
  "tasks": [...],
  "categories": [...],
  "settings": {...}
}
```

### Root Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | String | Yes | Backup format version (currently "1.0") |
| `exportDate` | String (ISO 8601) | Yes | UTC timestamp of backup creation |
| `appVersion` | String | Yes | DoIt app version that created the backup |
| `schemaVersion` | Integer | Yes | Database schema version |
| `backupType` | String | No | Type of backup: "manual" or "automatic" |
| `taskCount` | Integer | Yes | Number of tasks in backup |
| `categoryCount` | Integer | Yes | Number of categories in backup |
| `tasks` | Array | Yes | Array of task objects |
| `categories` | Array | Yes | Array of category objects |
| `settings` | Object | No | App settings (optional) |

### Task Object Structure

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Buy groceries",
  "description": "Milk, bread, eggs",
  "dueDate": "2024-01-20T14:00:00.000Z",
  "priority": "medium",
  "category": "Personal",
  "isCompleted": false,
  "createdAt": "2024-01-15T10:00:00.000Z",
  "completedAt": null,
  "hasNotification": true
}
```

#### Task Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique task identifier |
| `title` | String | Yes | Task title (cannot be empty) |
| `description` | String | Yes | Task description (can be empty string) |
| `dueDate` | String (ISO 8601) or null | Yes | Due date/time in UTC |
| `priority` | String | Yes | Priority level: "low", "medium", or "high" |
| `category` | String | Yes | Category name |
| `isCompleted` | Boolean | Yes | Completion status |
| `createdAt` | String (ISO 8601) | Yes | Creation timestamp in UTC |
| `completedAt` | String (ISO 8601) or null | Yes | Completion timestamp in UTC |
| `hasNotification` | Boolean | Yes | Whether notifications are enabled |

### Category Object Structure

```json
{
  "name": "Personal",
  "colorValue": 4280391411
}
```

#### Category Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | Category name (unique) |
| `colorValue` | Integer | Yes | ARGB color value (Flutter Color.value) |

### Settings Object Structure (Optional)

```json
{
  "automaticBackupsEnabled": true,
  "backupFrequency": "daily",
  "backupsToKeep": 7,
  "includeCompletedTasks": true,
  "backupOnAppClose": false
}
```

## Import Modes

### Merge Mode

- Adds new tasks and categories from the backup
- Skips items that already exist (matched by ID for tasks, name for categories)
- Preserves all existing data
- Recommended for syncing data from another device

### Replace Mode

- Deletes all existing tasks and categories
- Imports all data from the backup
- Creates an automatic backup of current data before replacing
- Use with caution - recommended only for full restore operations

## Version Compatibility

### Current Version: 1.0

- Supports all task and category fields listed above
- Compatible with app version 1.0.0+
- Schema version 1

### Future Versions

The backup system is designed to be forward-compatible:
- Version field allows detection of format changes
- Schema version enables data migrations during import
- Unknown fields are safely ignored during import
- Old format backups can be migrated to new formats

## Validation Rules

### During Import

1. **Structure Validation**
   - All required root fields must be present
   - Tasks and categories must be arrays
   - Version must be supported

2. **Task Validation**
   - ID and title are required
   - Title cannot be empty
   - Priority must be "low", "medium", or "high"
   - Dates must be valid ISO 8601 format
   - Booleans must be true or false

3. **Category Validation**
   - Name is required
   - ColorValue must be a valid integer

4. **Error Handling**
   - Invalid items are skipped with warnings
   - Import continues for valid items
   - Detailed error report provided at end

## Backup Storage Locations

### Android
- **Internal**: `/data/data/com.example.dooit/files/backups/`
- **Shared**: App documents directory (accessible via file manager)

### iOS
- **Location**: App documents directory
- **Access**: Files app integration
- **Sharing**: Available via share sheet

### Desktop (Windows/macOS/Linux)
- **Location**: `~/Documents/DoIt/backups/`
- **Format**: Standard JSON files accessible via file explorer

### Web
- **Export**: Triggers browser download
- **Import**: File upload dialog
- **Storage**: Not persistent (download only)

## Automatic Backup Behavior

### Schedule
- **Daily**: Creates backup once per day
- **Weekly**: Creates backup once per week
- Checks performed on app launch

### Cleanup
- Automatically deletes old backups based on settings
- Keeps last N backups (configurable: 3, 7, 14, or 30)
- Applies separately to manual and automatic backups

### Trigger Points
1. App launch (if schedule requires)
2. Before import operations (safety backup)
3. Manual backup button in settings

## Best Practices

### For Users

1. **Regular Backups**
   - Enable automatic backups
   - Manually backup before major changes
   - Keep backups when uninstalling app

2. **Before Device Migration**
   - Create manual backup
   - Share via email or cloud storage
   - Verify backup file is readable

3. **Data Safety**
   - Store important backups outside app
   - Test restore process periodically
   - Keep multiple backup generations

### For Developers

1. **Extending Format**
   - Add new fields with default values
   - Increment version on breaking changes
   - Maintain backward compatibility
   - Document all format changes

2. **Testing Imports**
   - Test with various backup versions
   - Validate error handling
   - Check edge cases (empty data, corrupted files)
   - Test large datasets

3. **Migration Support**
   - Implement version converters
   - Validate converted data
   - Provide clear error messages
   - Log migration operations

## Example Backup File

```json
{
  "version": "1.0",
  "exportDate": "2024-01-15T10:30:00.000Z",
  "appVersion": "1.0.0",
  "schemaVersion": 1,
  "backupType": "manual",
  "taskCount": 2,
  "categoryCount": 2,
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Buy groceries",
      "description": "Milk, bread, eggs",
      "dueDate": "2024-01-20T14:00:00.000Z",
      "priority": "medium",
      "category": "Personal",
      "isCompleted": false,
      "createdAt": "2024-01-15T10:00:00.000Z",
      "completedAt": null,
      "hasNotification": true
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "title": "Team meeting",
      "description": "Discuss Q1 goals",
      "dueDate": "2024-01-18T09:00:00.000Z",
      "priority": "high",
      "category": "Work",
      "isCompleted": false,
      "createdAt": "2024-01-15T10:05:00.000Z",
      "completedAt": null,
      "hasNotification": true
    }
  ],
  "categories": [
    {
      "name": "Personal",
      "colorValue": 4280391411
    },
    {
      "name": "Work",
      "colorValue": 4294940672
    }
  ]
}
```

## Troubleshooting

### Import Errors

**"Invalid JSON format"**
- File is corrupted or not valid JSON
- Try opening in text editor to verify format
- Re-export from source device

**"Unsupported version"**
- Backup was created with newer app version
- Update DoIt app to latest version
- Contact support if issue persists

**"Missing required field"**
- Backup file is incomplete
- May indicate corrupted export
- Try alternative backup if available

### Export Issues

**"Permission denied"**
- Android: Grant storage permissions in app settings
- iOS: Check Files app permissions
- Desktop: Verify write access to documents folder

**"Storage full"**
- Free up device storage
- Delete old backups
- Export to external storage

## Related Documentation

- [Migration Guide](MIGRATION_GUIDE.md) - Database schema migrations
- [README](README.md) - General app documentation
- [Performance Optimization](PERFORMANCE_OPTIMIZATION.md) - App optimization guide
