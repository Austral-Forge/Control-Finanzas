# Control Finanzas — Project Memory

**Also known as:** The app, FinApp

**Status:** In progress

**Timeline:** Launch target 2026-07-30

**Type:** Personal finance mobile app

## Vision
A Flutter-based financial control app for tracking monthly income/expenses, calculating balance (savings or deficit), and visualizing financial health through month-by-month cards.

## Architecture & Stack

### Framework & Language
- **Flutter:** Stable version (latest at time of development)
- **Dart:** Primary language

### State Management
- **Choice pending:** Riverpod, Bloc, or Provider (to be confirmed)
- Will manage transaction state, monthly summaries, and filtering

### Architectural Pattern
**Clean Architecture** with three layers:
1. **Domain Layer** — Business logic, use cases, entities
   - Transaction models (income/expense)
   - Balance calculation logic
   - Repository interfaces
2. **Data Layer** — Data sources and repositories
   - Local storage (database or shared preferences)
   - Repository implementations
3. **Presentation Layer** — UI, widgets, state management
   - Screens, widgets, view models
   - Material Design 3 components

### Design System
- **Material Design 3** — Official Flutter material design
- **Card-based layouts** for monthly views
- **Color coding:** Green (savings/positive balance), Red (deficit/negative balance)

### Dependencies
- **freezed** — Immutable data classes and JSON serialization
- **intl** — Currency formatting and localization
- **Material Design 3 widgets** — Buttons, cards, lists, etc.

## UI/UX Rules

### Dashboard (Main Screen)
- Vertical list of `Card` widgets
- Each card = one month
- Card shows:
  - Month name
  - Total ingresos (income)
  - Total egresos (expenses)
  - Balance (colored: green if positive, red if negative)

### Detail Screen
- Triggered by tapping a month card
- Shows filtered list of transactions for that month
- Grouped/displayed by category
- Allows viewing individual transaction details

### Navigation
- `onTap` on month card → DetailScreen
- Back button or navigation drawer to return to dashboard

## Codification Rules

### Data Models
- **Use freezed** for:
  - Immutable classes
  - Automatic JSON serialization/deserialization
  - Immutability guarantees
- Example structure:
  ```dart
  @freezed
  class Transaction with _$Transaction {
    const factory Transaction({
      required String id,
      required double amount,
      required String category,
      required DateTime date,
      required bool isIncome,
    }) = _Transaction;
    
    factory Transaction.fromJson(Map<String, dynamic> json) =>
        _$TransactionFromJson(json);
  }
  ```

### Currency Formatting
- **Always use `intl` package** for displaying amounts
- Respect user's locale
- Example:
  ```dart
  import 'package:intl/intl.dart';
  
  final formatter = NumberFormat.currency(
    locale: 'es_ES', // or dynamic from system
    symbol: '\$',
  );
  final formatted = formatter.format(amount);
  ```

### Reusable Components
- Location: `/lib/presentation/widgets/`
- Examples:
  - `MonthSummaryCard.dart` — Month card with summary data
  - `TransactionListTile.dart` — Individual transaction display
  - `BalanceIndicator.dart` — Color-coded balance display
- Keep widgets focused and composable

## Business Logic

### Balance Calculation
- Formula: `balance = totalIngresos - totalEgresos`
- Must reside in **Domain layer** (use cases or entities), never in UI
- Example use case:
  ```dart
  class CalculateMonthlyBalance {
    Result<double> call(List<Transaction> transactions) {
      final income = transactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expenses = transactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      return income - expenses;
    }
  }
  ```

### Transaction Management
- Add, edit, delete transactions
- Filter by month, category, type (income/expense)
- Persist to local storage

### Monthly Aggregation
- Group transactions by month
- Calculate totals per month
- Display in dashboard

## File Structure (Expected)
```
lib/
├── domain/
│   ├── entities/
│   │   └── transaction.dart
│   ├── repositories/
│   │   └── transaction_repository.dart
│   └── usecases/
│       ├── add_transaction.dart
│       ├── get_monthly_summary.dart
│       └── calculate_balance.dart
├── data/
│   ├── datasources/
│   │   └── local_transaction_datasource.dart
│   ├── models/
│   │   └── transaction_model.dart
│   └── repositories/
│       └── transaction_repository_impl.dart
├── presentation/
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   └── detail_screen.dart
│   ├── widgets/
│   │   ├── month_summary_card.dart
│   │   └── transaction_list_tile.dart
│   └── providers/ (or bloc/cubits if using Bloc)
│       └── transaction_provider.dart
└── main.dart
```

## Key Principles
1. **Separation of concerns** — UI ≠ Business Logic
2. **Immutability** — Use freezed and const constructors
3. **Reusability** — Create small, composable widgets
4. **Localization** — Use intl for formatting
5. **Type safety** — Leverage Dart's strong typing
6. **Clean layers** — Domain logic never touches Presentation

## Next Steps (Pre-launch)
- [ ] Finalize state management choice (Riverpod/Bloc/Provider)
- [ ] Set up project structure and dependencies
- [ ] Implement domain layer (entities, use cases)
- [ ] Build data layer (storage, repositories)
- [ ] Create presentation layer (screens, widgets)
- [ ] Add transaction CRUD operations
- [ ] Implement monthly aggregation
- [ ] Polish UI/UX and test thoroughly
- [ ] Prepare for release (June 30, 2026)
