# PackPlan Architecture Notes

## Current Decision

PackPlan keeps a small repository-based Flutter architecture. Production now
uses SQLite local persistence; widget and domain tests can continue to use the
in-memory implementation.

## App Shell

- `lib/main.dart` starts `PackPlanBootstrap`, which opens the SQLite store and
  then starts `PackPlanApp`.
- A database-open or backup-decode failure stays outside the product shell and
  shows a recovery screen. Users can retry without changing data or explicitly
  reset the unreadable local database after a confirmation dialog.
- `PackPlanApp` receives the production repository and provides it through
  `AppScope`. Tests can omit it and receive an in-memory repository.
- Navigation currently uses Flutter `MaterialPageRoute` directly. This is
  enough for Phase 0 and can be replaced by a router once tab navigation,
  deep links, and invite links arrive.

## State Management

- Current: `ChangeNotifier` via `PackListRepository`.
- Reason: no new package required, simple enough for the Phase 0 app shell.
- Upgrade path: Riverpod or Bloc can be introduced later if state ownership
  becomes more complex.

## Data Layer

- `PackListRepository` remains the UI-facing interface.
- Production uses `PersistentPackListRepository`, backed by
  `PackPlanDatabaseStore` and SQLite.
- `InMemoryPackListRepository` remains the mutation engine and test double.
- Seed data is written only when the database has no saved state.
- Every repository change queues a serialized database write. This includes
  list and item changes, settings changes, and imported backups.

## Local Storage Direction

The first storage schema keeps one versioned JSON snapshot in SQLite. It reuses
the same validated codec as manual backup/import, which keeps the current
implementation compact and migration-ready.

When gear locker, collaboration, or large cross-list queries arrive, migrate
the snapshot into normalized list, item, category, and settings tables. SQLite
database version upgrades and backup format versions must be migrated together.

## Domain Rules

- Internal weight unit is always gram.
- `WeightCalculator` owns totals, progress, tiers, and reduction suggestions.
- UI formatting stays in `WeightFormatters`.
- Weight visibility is stored per `PackList` and defaults to visible. Hiding
  weight changes presentation only; calculations and saved item weights remain
  intact.
- Every item has a `WeightClass`: `packed` or `worn`. Worn weight remains
  visible but is excluded from base and pack weight. Worn items cannot be
  containers or belong to a container. Legacy `consumable` values are migrated
  to `packed` while that product concept remains deferred.
- Category labels are editable display values. Stable `categoryId` values keep
  rules such as clothes quantity and luggage-container behavior independent
  from the user-facing label.
- Category order is persisted by normalizing item `sortOrder` into contiguous
  category blocks, so the current snapshot format needs no separate category
  table.

## Platform Integration

- Text sharing uses one Flutter `MethodChannel`.
- iOS presents `UIActivityViewController`.
- Android sends a `text/plain` `ACTION_SEND` intent through the system chooser.
- Clipboard copy remains available as a fallback in the share preview.
