# Period Cycle Feature - Implementation Guide

## Overview

A simple calendar feature for tracking period dates and creating related story entries. Available as a paid add-on ($1.99).

**Key Principles:**

- Simple UI, minimal complexity
- Use `EventDbModel.db` and `StoryDbModel.db` (not direct Box access)
- No unnecessary comments - code should be self-explanatory
- English text only (translations added separately)
- Use color scheme → theme colors → avoid static colors
- Follow existing calendar patterns

---

## Data Structure

### New Entity: `EventObjectBox`

```dart
@Entity()
class EventObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  int year;
  int month;
  int day;
  String eventType;  // "period"

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @Override
  String? lastSavedDeviceId;
}
```

### Update: `StoryObjectBox`

Add single field:

```dart
int? eventId;  // Links story to event
```

---

## Implementation Steps

### 1. Database Layer

**Create:** `lib/core/databases/adapters/objectbox/events_box.dart`

- Follow `StoriesBox` pattern
- Methods: `put()`, `delete()`, `getEventsByMonthAndType()`, `getEventById()`

**Create:** `lib/core/databases/models/event_db_model.dart`

- Use `@CopyWith()` and `@JsonSerializable()`
- Include `toJson()` and `fromJson()`
- Extends `BaseDbModel`

**Update:** `entities.dart`

- Add `EventObjectBox` entity
- Add `eventId` to `StoryObjectBox`

**Update:** `story_db_model.dart`

- Add `eventId` field

### 2. Add-on Setup

**Update:** `lib/core/types/app_product.dart`

```dart
enum AppProduct {
  relax_sounds,
  templates,
  period_calendar;  // Add this
}
```

**Update:** `lib/views/add_ons/add_ons_view_model.dart`

```dart
AddOnObject(
  type: AppProduct.period_calendar,
  title: 'Period Calendar',
  subtitle: 'Understand your cycle and feelings',
  displayPrice: '\$1.99',
  iconData: SpIcons.calendar,
  weekdayColor: 5,
)
```

### 3. Calendar Widget Refactor

**Update:** `lib/widgets/calendar/sp_calendar.dart`

- Add optional `cellBuilder` parameter
- Maintains backward compatibility (null = default)

**Create:** `lib/widgets/calendar/sp_calendar_period_date_cell.dart`

```dart
class SpCalendarPeriodDateCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isPeriodDate;
  final VoidCallback? onTap;

  // Shows soft red circle: colorScheme.error.withOpacity(0.1)
}
```

### 4. Period Cycle UI

**Create:** `lib/views/calendar/period_calendar/period_calendar_view_model.dart`

Key methods:

```dart
- _loadPeriodDates() // Load events for current month
- toggleDate(context, date) // Add/remove period event
- isPeriodDate(date) // Check if date has period event
- goToNewPage(context) // Create new story with eventId
- onMonthChanged(year, month) // Reload on month change
```

Delete confirmation:

- If event has stories: Show dialog "Remove event? This will unlink X stories"
- If no stories: Delete immediately

**Create:** `lib/views/calendar/period_calendar/period_calendar_content.dart`

Structure:

```dart
Scaffold(
  floatingActionButton: FloatingActionButton(...),
  body: NestedScrollView(
    headerSliverBuilder: [
      SpCalendar(
        cellBuilder: (context, date, isCurrentMonth, onTap) {
          return SpCalendarPeriodDateCell(
            isPeriodDate: viewModel.isPeriodDate(date),
            onTap: isCurrentMonth
              ? () => viewModel.toggleDate(context, date)
              : null,
          );
        },
      ),
    ],
    body: SpStoryList.withQuery(
      filter: SearchFilterObject(eventType: 'period'),
    ),
  ),
)
```

### 5. Calendar Integration

**Update:** `lib/views/calendar/calendar_content.dart`

Show period segment only if purchased:

```dart
final purchaseProvider = Provider.of<InAppPurchaseProvider>(context);
final hasPeriodCycle = purchaseProvider.hasPurchased(AppProduct.period_calendar);

final availableSegments = CalendarSegmentId.values.where((segment) {
  return segment != CalendarSegmentId.periodCycle || hasPeriodCycle;
}).toList();
```

---

## File Changes Summary

```
CREATE:
├── lib/core/databases/adapters/objectbox/events_box.dart
├── lib/core/databases/models/event_db_model.dart
├── lib/widgets/calendar/sp_calendar_period_date_cell.dart
├── lib/views/calendar/period_calendar/period_calendar_view_model.dart
└── lib/views/calendar/period_calendar/period_calendar_content.dart

UPDATE:
├── lib/core/databases/adapters/objectbox/entities.dart (add EventObjectBox, eventId)
├── lib/core/databases/models/story_db_model.dart (add eventId)
├── lib/core/types/app_product.dart (add period_calendar)
├── lib/views/add_ons/add_ons_view_model.dart (add period addon)
├── lib/widgets/calendar/sp_calendar.dart (add cellBuilder param)
└── lib/views/calendar/calendar_content.dart (conditional segment)
```

---

## Testing Checklist

- [ ] Toggle period dates (add/remove)
- [ ] Delete confirmation shows when event has stories
- [ ] Story creation with eventId
- [ ] Month navigation loads correct events
- [ ] Purchase flow enables segment
- [ ] Backup/restore includes events
- [ ] Existing stories calendar unchanged

---

## Key Behaviors

**Date Selection:**

- Click date → Create period event → Show soft red circle
- Click again (no stories) → Delete immediately
- Click again (has stories) → Confirm → Delete event (stories keep eventId)

**Story Creation:**

- FAB opens `EditStoryView` with `initialEventId`
- Story saves with `eventId` field
- Appears in period story list

**Visual Style:**

- Period indicator: `colorScheme.error.withOpacity(0.1)`
- Follow stories calendar layout
- Use `SpStoryList.withQuery` for story display

---

## Data Relationships

```
Event (1) ──< (N) Story
- Events store: year, month, day, eventType
- Stories link via: eventId field
- Query: StoryDbModel.db.getStoriesByEventId(eventId)
```
