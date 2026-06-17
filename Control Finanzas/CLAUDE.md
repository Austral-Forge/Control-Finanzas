# Memory — Control Finanzas

## Me
Developer on **Control Finanzas** (personal project). Building a Flutter-based personal finance app for tracking income/expenses and monthly balance.

## Projects
| Name | What | Status | Launch |
|------|------|--------|--------|
| **Control Finanzas** | Flutter finance tracker app | In Progress | 2026-07-30 |

## Stack & Tech
| Component | Choice |
|-----------|--------|
| Framework | Flutter (stable) |
| State Management | [To be chosen: Riverpod / Bloc / Provider] |
| Architecture | Clean Architecture (Domain, Data, Presentation) |
| UI Design | Material Design 3 |
| Data Models | Freezed (immutable + JSON) |
| Formatting | intl package (currency) |
| Components Folder | `/lib/presentation/widgets/` |

## Key Rules
- **Balance calc:** `balance = ingresos - egresos` (logic in Domain layer, not UI)
- **UI:** Card-based dashboard showing monthly summaries; tap to drill into category breakdown
- **Colors:** Green for savings, Red for deficit
- **Build patterns:** Freezed, immutable models, reusable widgets

## Preferences
- Solo development
- Frequent reference to Clean Architecture layers
- Focus on proper separation of concerns (UI ≠ business logic)

→ Full glossary: `memory/glossary.md`
→ Project details: `memory/projects/control-finanzas.md`
