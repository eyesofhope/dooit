# Adaptive Layout System Testing Guide

## Overview
This document outlines the comprehensive testing plan for the adaptive layout system implemented across mobile, tablet, and desktop breakpoints.

## Breakpoints
The system uses Material Design 3 breakpoints:
- **Compact**: 0-599px (phone portrait)
- **Medium**: 600-839px (tablet portrait, phone landscape)
- **Expanded**: 840-1199px (tablet landscape, small desktop)
- **Large**: 1200-1599px (desktop)
- **Extra-large**: 1600px+ (large desktop)

## Testing Checklist

### 1. Compact Layout (< 600px)
- [ ] Bottom navigation bar displays with 4 destinations (Home, Calendar, Categories, Settings)
- [ ] Single-column task list with full-width cards
- [ ] FloatingActionButton appears in bottom-right corner
- [ ] Tapping task opens full-screen TaskDetailScreen
- [ ] Stats card displays above filters
- [ ] Responsive padding: 16px horizontal
- [ ] Touch targets are minimum 48x48 pixels

### 2. Medium Layout (600-839px)
- [ ] Navigation rail appears on left (collapsed)
- [ ] Two-pane layout: master (360px) + detail pane
- [ ] Tapping task shows detail in right pane
- [ ] Selected task highlighted in master pane
- [ ] Detail pane shows placeholder when no task selected
- [ ] Close button in detail pane clears selection
- [ ] Responsive padding: 24px horizontal
- [ ] No stats card in master pane (more space efficient)

### 3. Expanded Layout (840-1199px)
- [ ] Navigation rail appears on left (expanded with labels)
- [ ] Two-pane layout: master (400px) + detail pane
- [ ] Same selection behavior as medium
- [ ] Responsive padding: 32px horizontal

### 4. Large+ Layout (1200px+)
- [ ] Navigation rail expanded with labels
- [ ] Two-pane layout: master (480px) + detail pane
- [ ] Same functionality as expanded
- [ ] Responsive padding: 32px horizontal

### 5. Navigation System
- [ ] Home destination shows task list
- [ ] Calendar, Categories, Settings show "Coming Soon" placeholder
- [ ] Navigation state preserved across breakpoint changes
- [ ] Popup menu items moved to proper navigation

### 6. Task Detail Behavior
- [ ] Compact: Opens as full-screen modal with back button
- [ ] Medium+: Opens in detail pane with close button
- [ ] Edit dialog works in both modes
- [ ] Toggle complete works in both modes
- [ ] Duplicate works in both modes
- [ ] Delete works and clears selection (medium+) or navigates back (compact)

### 7. Window Resizing (Web/Desktop)
- [ ] Smooth transitions between layouts using AnimatedSwitcher
- [ ] No layout overflow errors during resize
- [ ] Selection state preserved during resize
- [ ] If in detail view on medium+ and resizing to compact, detail closes gracefully

### 8. Responsive Components
- [ ] Stats card uses responsive padding
- [ ] Filter section uses responsive padding
- [ ] Task list uses responsive padding
- [ ] All cards and buttons maintain proper spacing

### 9. Orientation Changes (Mobile)
- [ ] Portrait to landscape transition smooth
- [ ] Phone landscape (≥600px width) switches to medium layout with navigation rail
- [ ] All functionality preserved across orientation changes

### 10. Accessibility
- [ ] Touch targets maintain 48x48 minimum size
- [ ] Text remains readable at all breakpoints
- [ ] Navigation is keyboard accessible (desktop)
- [ ] Screen reader support maintained

## Test Devices/Simulators

### Phone (Compact)
- iPhone SE (375x667)
- Pixel 5 (393x851)

### Tablet (Medium/Expanded)
- iPad (810x1080) - portrait
- iPad (1080x810) - landscape

### Desktop (Large/Extra-Large)
- Chrome browser at 1280x720
- Chrome browser at 1920x1080
- Chrome browser at 2560x1440

## Known Limitations
- Calendar, Categories, and Settings screens are placeholders (planned for future phases)
- No drag-to-resize splitter between master and detail panes (optional feature)
- Stats card hidden in master pane on medium+ (design decision for space efficiency)

## Implementation Files
- `lib/utils/breakpoints.dart` - Breakpoint system
- `lib/widgets/adaptive/adaptive_scaffold.dart` - Adaptive scaffold
- `lib/widgets/adaptive/master_detail_layout.dart` - Two-pane layout
- `lib/widgets/adaptive/responsive_padding.dart` - Responsive padding
- `lib/widgets/adaptive/responsive_grid.dart` - Responsive grid (future use)
- `lib/screens/adaptive_todo_screen.dart` - Refactored todo screen
- `lib/screens/task_detail_screen.dart` - Updated with detail pane support
- `lib/screens/placeholder_screen.dart` - Placeholder for future features
- `lib/providers/task_provider.dart` - Added selection state
- `lib/widgets/task_card.dart` - Added selection highlighting
