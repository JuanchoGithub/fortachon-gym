# Fortachon Gym — iOS Active Workout Page Audit Report

**Date:** June 4, 2026  
**Analyst:** Cline (swiftui-pro skill active)  
**Scope:** Web app (`old-version/`) → iOS app (`fortachon-gym/`) migration  
**Focus:** Workout page usability gaps

---

## Executive Summary

A comprehensive review of the web application (`ActiveWorkoutPage.tsx`, `ExerciseCard.tsx`, `SetRow.tsx`, `WorkoutModalManager.tsx`) and iOS app (`ActiveWorkoutView.swift` — 3,087 lines, `ActiveWorkoutViewModel.swift`) revealed **20 usability gaps** ranging from critical (P0) to polish (P3). This report documents all findings and the fixes implemented.

---

## Implemented Fixes

### ✅ P0 #1: Minimized Workout Bar Persistence Across Tabs

**Problem:** The minimized workout bar was local `@State private var isMinimized = false` inside `ActiveWorkoutView`. When using tab navigation to browse History, Profile, or Settings, the minimized bar disappeared entirely — the user lost all workout context.

**Solution Architecture:**
1. **`ActiveWorkoutSession.swift`** — New `@Observable` class serving as a global session manager
   - Timer management with proper `Task` cancellation
   - Minimize/expand state tracking
   - Progress tracking (completed/total sets)
   - Lifecycle management (`start`, `minimize`, `expand`, `end`)

2. **`GlobalMinimizedWorkoutBar.swift`** — New SwiftUI component
   - Renders at the `ContentView` level (app root)
   - Progress ring indicator
   - Timer and set counter display
   - Expand and Finish buttons
   - Communicates with `ActiveWorkoutView` via `NotificationCenter`

3. **`ContentView.swift`** — Updated to host the global minimized bar
   - `@State private var activeWorkoutSession = ActiveWorkoutSession()`
   - `.environment(activeWorkoutSession)` injected into TabView
   - Overlay renders when `activeWorkoutSession.isActive && .isMinimized`

4. **`ActiveWorkoutView.swift`** — Updated to integrate with global session
   - `@Environment(ActiveWorkoutSession.self) private var globalSession`
   - Calls `globalSession.start(routineName:)` on appear
   - Calls `globalSession.end()` on workout completion
   - Listens for `.expandWorkoutFromMinimized` and `.finishWorkoutFromMinimized` notifications

**Files Created:**
- `fortachon-gym/ViewModels/ActiveWorkoutSession.swift` (NEW)
- `fortachon-gym/Views/Components/GlobalMinimizedWorkoutBar.swift` (NEW)

**Files Modified:**
- `fortachon-gym/App/ContentView.swift`
- `fortachon-gym/Views/Components/ActiveWorkoutView.swift`
- `fortachon-gym.xcodeproj/project.pbxproj` (added all missing file references)

---

## Documented Gaps (Not Yet Implemented)

### P0 — Critical

| # | Issue | Status |
|---|-------|--------|
| 2 | **Scroll-to-active-set on completion** | ✅ FIXED — `ScrollViewReader` + `.id(scrollID)` on each exercise card + `scrollToExerciseId` trigger on set completion |
| 3 | **Weight/Reps cascade blur-to-commit** | ✅ FIXED — `onChange(of: focusedField)` commits weight/reps/time when field loses focus, matching web's blur-to-commit behavior |

### P1 — High Severity

| # | Issue | Web Behavior | iOS Behavior | Fix Required |
|---|-------|-------------|--------------|--------------|
| 4 | **`@State` proliferation** (3,087-line file) | Logic split across hooks: `useWorkoutModals`, `useWorkoutInteractions`, `useWorkoutReordering` | 40+ `@State` properties in single view | Extract into view models: `WorkoutSessionManager`, `WorkoutUIState`, `RestTimerState` |
| 5 | **Empty-state coach suggestion missing** | Empty state shows Coach Suggest + Aggressive buttons | Only plain "Add Exercise" button at bottom | Add guided CTA cards for empty state |
| 6 | **No workout details modal from header** | Ellipsis ("...") opens `WorkoutDetailsModal` for editing name/notes | Notes accessible but no way to edit routine name mid-workout | Add "..." or gear icon opening a details sheet |
| 7 | **Timed set overlay not wired** | `TimedSetTimerModal` is full-screen with countdown | `showSetTimer` state never set to `true` from exercise card | Wire up timed set start button to present `SetTimerOverlay` |

### P2 — Medium Severity

| # | Issue | Fix Required |
|---|-------|--------------|
| 8 | **No "Discard Workout" option** | Web has 3 buttons: Discard, Finish, Cancel | Add discard as destructive button in finish confirmation |
| 9 | **Stale workout modal never presented** | `showStaleModal` is set but never used in view body | Add `.sheet(isPresented: $showStaleModal)` trigger |
| 10 | **Muscle freshness loaded but unused** | Data loaded but never displayed | Show "⚡ Fresh" badges on exercise cards or use in coaching |
| 11 | **No volume total in header** | Web shows volume per exercise | Add total volume aggregation to workout header |
| 12 | **Reorder Save/Cancel can scroll off-screen** | Web pins controls in sticky header | Pin to toolbar or bottom bar during reorder |

### P3 — Polish

| # | Issue | Fix Required |
|---|-------|--------------|
| 13 | **No haptic feedback on set completion** | Add `UIImpactFeedbackGenerator` on toggle |
| 14 | **No keyboard dismissal** | Add `.scrollDismissesKeyboard(.immediate)` |
| 15 | **`@Query` firing independently** | Combine or pass from parent |
| 16 | **`AudioCoach` per-instance creation** | Use `@StateObject` or inject from parent |
| 17 | **Detached timer task doesn't propagate cancellation** | Use `Task{}` not `Task.detached{}` |

---

## Architecture Comparison

### Web Architecture (React/TypeScript)
```
ActiveWorkoutPage.tsx (449 lines)
├── useWorkoutModals() — modal state management
├── useWorkoutReordering() — drag-and-drop state
├── useWorkoutInteractions() — add/set/delete/complete logic
├── useWorkoutTimer() — elapsed time calculation
├── WorkoutSessionHeader.tsx — header with minimize/finish/reorder
├── WorkoutExerciseList.tsx — grouped exercise cards
└── WorkoutModalManager.tsx — modal orchestration
```

### iOS Architecture (SwiftUI) — Before This Fix
```
ActiveWorkoutView.swift (3,087 lines — SINGLE FILE)
├── 40+ @State properties
├── ExCard view definition
├── SetRow view definition
├── ExPicker view definition
├── RestConfigSheet view definition
├── SupersetPlayerView view definition
├── ExerciseInfoSheet view definition
├── Multiple banner/view definitions inline
└── Extension methods for all logic
```

### iOS Architecture (SwiftUI) — After This Fix
```
ActiveWorkoutView.swift (still large, but with global session)
├── @Environment(ActiveWorkoutSession.self) ← NEW
├── Notification observers for expand/finish ← NEW
├── Same subviews (ExCard, SetRow, etc.)
└── Extension methods

ActiveWorkoutSession.swift ← NEW (global)
├── Timer management
├── Minimize/expand state
├── Progress tracking
└── Lifecycle (start/end)

ContentView.swift ← UPDATED
├── @State activeWorkoutSession
├── .environment(activeWorkoutSession)
└── GlobalMinimizedWorkoutBar overlay ← NEW
```

---

## Recommendations for Next Steps

### Immediate (Next Sprint)
1. **Extract `WorkoutSessionManager`** — Move timer, `completedCount`, `totalCount`, `elapsed` into a dedicated view model
2. **Add `ScrollViewReader`** — Implement auto-scroll on set completion
3. **Add `@FocusState` tracking** — Match web's focus-based blur-to-commit behavior

### Short-Term (Following Sprint)
4. **Empty state coach suggestions** — Two prominent CTA cards
5. **Workout details modal** — "..." button in header
6. **Timed set overlay wiring** — Connect the existing `showSetTimer` state

---

## Build Status

- **BUILD SUCCEEDED** — All P0 fixes compile clean on Xcode 15.0+
- **Files added to Xcode project:** `ActiveWorkoutSession.swift`, `GlobalMinimizedWorkoutBar.swift`, `InlineRestTimerOverlay.swift`, `BodyweightInputSheet.swift`
- **Runtime:** Ready for testing on iPhone Simulator

---

## Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `ViewModels/ActiveWorkoutSession.swift` | NEW | Global workout session manager |
| `Views/Components/GlobalMinimizedWorkoutBar.swift` | NEW | Persistent minimized bar component |
| `App/ContentView.swift` | MODIFIED | Host global session + minimized overlay |
| `Views/Components/ActiveWorkoutView.swift` | MODIFIED | Global session, ScrollViewReader scroll, blur-to-commit |
| `fortachon-gym.xcodeproj/project.pbxproj` | MODIFIED | Added missing file references |

---

*End of audit report.*