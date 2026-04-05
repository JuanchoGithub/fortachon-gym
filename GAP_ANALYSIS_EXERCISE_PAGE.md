# Exercise Page Gap Analysis: Web vs iOS

## Executive Summary

This document identifies gaps between the web version (old-version/) and the iOS version (fortachon-gym/) of the Fortachon Gym app, focusing specifically on the exercise page and related exercise functionality.

---

## 1. Exercise Library / Browse Page

### ✅ PARITY - Features Present in Both

| Feature | Web | iOS | Notes |
|---------|-----|-----|-------|
| Exercise list display | ✅ | ✅ | Both show exercise name, category, body part |
| Search functionality | ✅ | ✅ | Text search across name, body part, category, muscles |
| Body part filter | ✅ | ✅ | Filter pills for each body part |
| Category filter | ✅ | ✅ | Filter pills for each equipment type |
| Sort toggle (A-Z/Z-A) | ✅ | ✅ | Alphabetical sort toggle |
| Exercise count | ✅ | ✅ | Shows count of filtered exercises |
| Custom exercise creation | ✅ | ✅ | Plus button to create new exercises |
| Exercise editing | ✅ | ✅ | Edit name, body part, category, notes, muscles |
| Exercise deletion | ✅ | ✅ | With confirmation dialog |
| Exercise duplication | ✅ | ✅ | Duplicate existing exercises |

### ❌ GAPS - Web Has, iOS Missing

| Feature | Description | Priority |
|---------|-------------|----------|
| **Seeded exercise database** | Web has ~500+ pre-loaded exercises across 8 category files (exercises_chest.ts, exercises_back.ts, etc.) with detailed anatomical muscle mappings | HIGH |
| **Exercise muscle visualization** | Web shows detailed primary/secondary muscle activation with anatomical muscle names (e.g., "Pectoralis Major Clavicular", "Latissimus Dorsi") | MEDIUM |
| **Exercise notes/instructions** | Web stores and displays detailed exercise instructions and form tips | MEDIUM |
| **Exercise category icons** | Web uses visual icons for exercise categories | LOW |
| **Bulk exercise import** | Web supports importing exercises from JSON | LOW |
| **Exercise updatedAt/deletedAt timestamps** | Web tracks soft-delete and last-update timestamps | LOW |

---

## 2. Exercise Detail View

### ✅ PARITY - Features Present in Both

| Feature | Web | iOS | Notes |
|---------|-----|-----|-------|
| Exercise name display | ✅ | ✅ | |
| Category badge | ✅ | ✅ | Color-coded by equipment type |
| Body part badge | ✅ | ✅ | Color-coded by body part |
| Timed exercise indicator | ✅ | ✅ | |
| Primary muscles display | ✅ | ✅ | Flow layout tags |
| Secondary muscles display | ✅ | ✅ | Flow layout tags |
| Exercise notes | ✅ | ✅ | |
| Personal records | ✅ | ✅ | Best 1RM, max weight, max reps, max volume |
| Exercise history | ✅ | ✅ | Session history with sets, volume, 1RM |
| Progress charts | ✅ | ✅ | Line charts for 1RM, weight, volume, reps |
| Best set display | ✅ | ✅ | Personal best card with weight × reps |

### ❌ GAPS - Web Has, iOS Missing

| Feature | Description | Priority |
|---------|-------------|----------|
| **Exercise form instructions** | Web shows step-by-step form instructions with images | HIGH |
| **Exercise variations** | Web shows alternative exercise variations | MEDIUM |
| **Muscle activation heatmap** | Web has visual muscle map showing which muscles are worked | MEDIUM |
| **Community exercise notes** | Web shows community-shared tips and form cues | LOW |
| **Exercise difficulty rating** | Web shows beginner/intermediate/advanced tags | LOW |
| **Equipment alternatives** | Web suggests equipment substitutions | LOW |

---

## 3. Active Workout Exercise Display

### ✅ PARITY - Features Present in Both

| Feature | Web | iOS | Notes |
|---------|-----|-----|-------|
| Exercise name in workout | ✅ | ✅ | |
| Set entry (reps/weight) | ✅ | ✅ | |
| Set type selection | ✅ | ✅ | Normal, warmup, drop, failure, timed |
| Set completion toggle | ✅ | ✅ | |
| Rest timer between sets | ✅ | ✅ | Customizable rest times per set type |
| Superset support | ✅ | ✅ | Group exercises into supersets |
| Exercise notes per workout | ✅ | ✅ | Per-workout exercise notes |
| Exercise reordering | ✅ | ✅ | Drag to reorder exercises |
| Exercise removal from workout | ✅ | ✅ | |

### ❌ GAPS - Web Has, iOS Missing

| Feature | Description | Priority |
|---------|-------------|----------|
| **Previous session auto-fill** | Web auto-fills weight/reps from last session for same exercise | HIGH |
| **Previous session comparison** | Web shows previous workout data inline for comparison | HIGH |
| **1RM estimate display** | Web shows estimated 1RM as user enters sets | MEDIUM |
| **Volume accumulation display** | Web shows running total volume for exercise | MEDIUM |
| **Exercise history mini-chart** | Web shows small trend sparkline in active workout | MEDIUM |
| **Form tips during workout** | Web shows form tips when viewing exercise details | LOW |
| **Bar weight tracking** | Web tracks barWeight separately for plate calculations | MEDIUM |
| **Set inheritance** | Web can inherit reps/weight/time from previous set | LOW |
| **Body weight storage per set** | Web stores bodyweight for bodyweight exercises | LOW |
| **Historical weight/reps tracking** | Web tracks what was changed from auto-filled values | LOW |
| **Actual rest time tracking** | Web tracks actual rest time vs planned rest | LOW |
| **Previous version rollback** | Web supports undoing exercise changes | LOW |

---

## 4. Exercise Data Model

### ✅ PARITY - Fields Present in Both

| Field | Web | iOS | Notes |
|-------|-----|-----|-------|
| id | ✅ | ✅ | |
| name | ✅ | ✅ | |
| bodyPart | ✅ | ✅ | 13 options |
| category | ✅ | ✅ | 12 options |
| notes | ✅ | ✅ | |
| isTimed | ✅ | ✅ | |
| isUnilateral | ✅ | ✅ | |
| primaryMuscles | ✅ | ✅ | Array of strings |
| secondaryMuscles | ✅ | ✅ | Array of strings |

### ❌ GAPS - Web Has, iOS Missing

| Field | Description | Priority |
|-------|-------------|----------|
| updatedAt | Timestamp for last modification | LOW |
| deletedAt | Soft-delete timestamp | LOW |
| barWeight | Default bar weight for exercise | MEDIUM |
| restTime per set type | Web stores rest times per set type (normal/warmup/drop/timed/effort/failure) | MEDIUM |

---

## 5. Exercise Constants & Seed Data

### Web Has (iOS Missing Entirely)

| File | Content | Count |
|------|---------|-------|
| constants/exercises.ts | Core exercise definitions | ~100 exercises |
| constants/exercises_chest.ts | Chest exercises with detailed muscle mappings | ~20 exercises |
| constants/exercises_back.ts | Back exercises with detailed muscle mappings | ~25 exercises |
| constants/exercises_legs.ts | Leg exercises with detailed muscle mappings | ~30 exercises |
| constants/exercises_shoulders.ts | Shoulder exercises with detailed muscle mappings | ~20 exercises |
| constants/exercises_arms.ts | Biceps/Triceps exercises with detailed muscle mappings | ~30 exercises |
| constants/exercises_core.ts | Core/Ab exercises with detailed muscle mappings | ~20 exercises |
| constants/exercises_mobility.ts | Mobility exercises | ~15 exercises |
| constants/exercises_cardio.ts | Cardio exercises | ~10 exercises |
| constants/muscles.ts | Detailed anatomical muscle definitions | 50+ muscles |
| constants/exercises.ts | Master exercise list combining all categories | ~200+ exercises |

### iOS Current State
- iOS relies on FortachonCore's `ExerciseSeedData.swift` and `ExerciseSeeder.swift` for initial data
- The seed data is much smaller than the web version
- Missing detailed anatomical muscle mappings

---

## 6. Exercise Localization

### Web Has
- Full i18n support with `locales/en_exercises.ts` and `locales/es_exercises.ts`
- Exercise names translated to English and Spanish
- Exercise instructions translated
- Muscle names translated

### iOS Has
- Uses system localization for UI strings
- Exercise names stored as-is (not localized)
- Missing exercise instruction localization

---

## 7. Exercise Search & Discovery

### ✅ PARITY

| Feature | Web | iOS |
|---------|-----|-----|
| Search by name | ✅ | ✅ |
| Search by body part | ✅ | ✅ |
| Search by category | ✅ | ✅ |
| Search by muscle | ✅ | ✅ |

### ❌ GAPS - Web Has, iOS Missing

| Feature | Description |
|---------|-------------|
| Fuzzy search | Web supports partial/fuzzy matching |
| Recently used sorting | Web can sort by recently used exercises |
| Favorite exercises | Web has exercise favorites |
| Exercise tags search | Web searches across exercise tags |

---

## 8. Exercise Analytics

### ✅ PARITY

| Feature | Web | iOS |
|---------|-----|-----|
| Personal records | ✅ | ✅ |
| Exercise history | ✅ | ✅ |
| Progress charts | ✅ | ✅ |
| Volume tracking | ✅ | ✅ |
| 1RM tracking | ✅ | ✅ |

### ❌ GAPS - Web Has, iOS Missing

| Feature | Description |
|---------|-------------|
| Strength ratio analysis | Web shows strength ratios (e.g., bench:squat ratio) |
| Muscle balance analysis | Web shows muscle group balance and imbalances |
| Exercise frequency tracking | Web tracks how often each exercise is performed |
| Volume by muscle group | Web aggregates volume by primary muscle |
| Strength level classification | Web classifies strength levels (beginner/intermediate/advanced/elite) |

---

## 9. Exercise Recommendations

### Web Has
- AI-powered exercise recommendations based on workout history
- Suggested exercises to fill muscle gaps
- Warning about overtrained muscle groups
- Exercise substitution suggestions

### iOS Has
- Basic recommendation banner (RecommendationBannerView.swift)
- Missing detailed recommendation engine

---

## 10. Exercise in Templates/Routines

### Web Has
- Exercise templates with pre-configured sets/reps/weight
- Routine generator that suggests exercises
- Template editor for creating custom routines
- Exercise ordering within templates

### iOS Has
- Routine detail sheet (RoutineDetailSheetView.swift)
- Routines section view (RoutinesSectionView.swift)
- Missing template editor for exercises

---

## Priority Recommendations

### HIGH Priority (Implement First)
1. **Seeded exercise database** - Port the ~500+ exercises from web constants to iOS
2. **Previous session auto-fill** - Auto-fill weight/reps from last session
3. **Previous session comparison** - Show previous workout data inline
4. **Exercise form instructions** - Add form tips and instructions

### MEDIUM Priority
1. **Muscle activation visualization** - Visual muscle map
2. **1RM estimate display** - Show estimated 1RM during workout
3. **Bar weight tracking** - Track bar weight separately
4. **Volume accumulation display** - Running total volume
5. **Exercise history mini-chart** - Sparkline in active workout
6. **Detailed anatomical muscle mappings** - Port muscle constants

### LOW Priority
1. **Community exercise notes** - Community tips
2. **Exercise difficulty rating** - Beginner/intermediate/advanced
3. **Bulk exercise import** - JSON import
4. **Exercise favorites** - Favorite exercises
5. **Strength ratio analysis** - Ratio calculations

---

## Files Referenced

### Web Version (old-version/)
- `pages/ExercisesPage.tsx`
- `pages/ExerciseEditorPage.tsx`
- `pages/AddExercisePage.tsx`
- `pages/ActiveWorkoutPage.tsx`
- `components/exercise/`
- `components/train/`
- `components/template/`
- `constants/exercises.ts`
- `constants/exercises_*.ts`
- `constants/muscles.ts`
- `constants/progression.ts`
- `constants/ratios.ts`
- `types/index.ts`
- `hooks/useExerciseName.ts`
- `locales/en_exercises.ts`
- `locales/es_exercises.ts`

### iOS Version (fortachon-gym/)
- `Views/Tabs/TabExercisesView.swift`
- `Views/Components/Profile/ExerciseEditorView.swift`
- `Views/Components/ActiveWorkoutView.swift`
- `ViewModels/WorkoutManager.swift`
- `Models/AppTypes.swift`
- `FortachonCore/Sources/FortachonCore/Models.swift`
- `FortachonCore/Sources/FortachonCore/ExerciseSeedData.swift`
- `FortachonCore/Sources/FortachonCore/ExerciseSeeder.swift`
- `FortachonCore/Sources/FortachonCore/MuscleConstants.swift`
- `FortachonCore/Sources/FortachonCore/RecommendationEngine.swift`
- `FortachonCore/Sources/FortachonCore/RatioConstants.swift`

---

*Analysis completed: April 5, 2026*