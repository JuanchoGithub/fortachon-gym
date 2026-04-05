# Workout Page Gap Analysis: Web vs iOS

**Date:** May 4, 2026  
**Web Version:** `old-version/` (React/TypeScript)  
**iOS Version:** `fortachon-gym/` (SwiftUI + FortachonCore)

---

## Executive Summary

The iOS version has achieved **basic workout tracking parity** with the web version, including set logging, weight/reps tracking, supersets, rest timers, and exercise upgrades. However, **14+ significant features** are missing from the iOS version, primarily around smart coaching, audio feedback, advanced tracking, and visual indicators.

---

## Feature Parity Matrix

| # | Feature | Web | iOS | Status |
|---|---------|-----|-----|--------|
| 1 | Basic set tracking (weight/reps) | ✅ | ✅ | **PARITY** |
| 2 | Set types (normal, warmup, drop, failure) | ✅ | ✅ | **PARITY** |
| 3 | Supersets | ✅ | ✅ | **PARITY** |
| 4 | Exercise upgrade/rollback | ✅ | ✅ | **PARITY** |
| 5 | Rest timer (multiple types) | ✅ | ✅ | **PARITY** |
| 6 | Body weight logging | ✅ | ✅ | **PARITY** |
| 7 | Supplement logging | ✅ | ✅ | **PARITY** |
| 8 | 1RM protocol | ✅ | ✅ | **PARITY** |
| 9 | Warmup set calculator (plates) | ✅ | ✅ | **PARITY** |
| 10 | Workout timer (elapsed) | ✅ | ✅ | **PARITY** |
| 11 | HIIT sessions | ✅ | ✅ | **PARITY** |
| 12 | PR tracking | ✅ | ✅ | **PARITY** |
| 13 | Finish workout validation | ✅ | ✅ | **PARITY** |
| 14 | Swipe gestures for sets | - | ✅ | **iOS Only** |
| 15 | Undo last workout | ✅ | ❌ | **GAP** |
| 16 | Smart coach suggestions | ✅ | ❌ | **GAP** |
| 17 | Auto-promotion recommendations | ✅ | ❌ | **GAP** |
| 18 | Audio feedback/coach | ✅ | ❌ | **GAP** |
| 19 | Timed exercise tracking | ✅ | ❌ | **GAP** |
| 20 | Cardio distance tracking | ✅ | ❌ | **GAP** |
| 21 | Historical weight/reps indicators | ✅ | ❌ | **GAP** |
| 22 | Muscle freshness scoring | ✅ | ❌ | **GAP** |
| 23 | Fatigue-based recommendations | ✅ | ❌ | **GAP** |
| 24 | Timed set UI (start/stop) | ✅ | ❌ | **GAP** |
| 25 | RPE display | ✅ | ❌ | **GAP** |
| 26 | Plate calculator UI | ✅ | ❌ | **GAP** |
| 27 | Exercise history modal | ✅ | ❌ | **GAP** |
| 28 | Set inheritance system | ✅ | ❌ | **GAP** |
| 29 | Routine suggestions | ✅ | ❌ | **GAP** |
| 30 | Smart starting weight calc | ✅ | ❌ | **GAP** |
| 31 | Workout notes | ✅ | ❌ | **GAP** |
| 32 | Exercise notes | ✅ | ❌ | **GAP** |
| 33 | Visual PR indicators during set | ✅ | ❌ | **GAP** |
| 34 | Muscle freshness visual indicators | ✅ | ❌ | **GAP** |
| 35 | Progress percentage displays | ✅ | ❌ | **GAP** |
| 36 | Workout validation messages | ✅ | Partial | **PARTIAL** |

---

## Detailed Gap Analysis

### HIGH PRIORITY GAPS (Missing Features)

#### 1. Smart Coach Suggestions / Auto-Promotions
**Web:** `ActiveWorkoutPage.tsx` has `smartCoachSuggestions` that automatically promotes exercises based on muscle freshness analysis. It shows a dedicated suggestions list at the bottom of the page.

**iOS:** No equivalent smart suggestion system. Users must manually tap "Upgrade Exercise" buttons.

**Missing Components:**
- `WorkoutPromotionCard` (web component)
- `smartCoachSuggestions` component
- `MuscleFreshnessScore` logic integration
- `getRequestablePromotions` API equivalent

**Files to Port:**
- `old-version/components/active-workout/WorkoutPromotionCard.tsx`
- `old-version/components/active-workout/SmartCoachComponent.tsx`
- Logic from `old-version/pages/ActiveWorkoutPage.tsx` lines 72-138

---

#### 2. Audio Feedback / Audio Coach
**Web:** Has a complete audio feedback system:
- `AudioCoachComponent` - Speaks workout cues
- `useAudioCoach` hook - Manages speech synthesis
- Pre-set cues for exercise start, set completion, PR achievement

**iOS:** No audio feedback during workouts. Swift's `AVSpeechSynthesizer` is available but not integrated into workout views.

**Files to Port:**
- `old-version/components/active-workout/AudioCoachComponent.tsx`
- `old-version/hooks/active-workout/useAudioCoach.ts`
- `old-version/services/audioService.ts`

---

#### 3. Timed Exercise Tracking
**Web:** Exercises can be started/stopped as timed sets:
- `TimedExerciseCard` component
- Start/Stop/Reset timer controls
- Shows running elapsed time in real-time
- Can add multiple timed sets

**iOS:** The data model supports `TimedExercise` type but no UI exists for starting/stopping timed exercises.

**Files to Port:**
- `old-version/components/active-workout/TimedExerciseCard.tsx`
- `old-version/components/active-workout/TimerDisplay.tsx`
- `old-version/hooks/useWorkoutTimer.ts` (timer logic)

---

#### 4. Cardio Distance Tracking
**Web:** Cardio exercises support:
- Duration input (minutes)
- Distance input (kilometers)
- Speed display (km/h)
- Pace display (min/km)

**iOS:** The `CardioSession` model exists but no input UI for distance.

**Files to Port:**
- `old-version/components/active-workout/CardioExerciseCard.tsx`
- Distance/speed calculation utils

---

#### 5. Historical Weight/Reps Indicators
**Web:** Shows visual indicators when comparing to previous:
- ⬆️ Green arrow if current > historical
- ⬇️ Red arrow if current < historical
- Shows "vs last time" context

**iOS:** No historical comparison UI during active workout.

**Data Model Gap:** Web has `PerformedSet` fields:
- `historicalWeight`
- `historicalReps`
- `historicalTime`

These fields are not in the iOS model.

---

#### 6. Muscle Freshness Scoring Visual Display
**Web:** Shows colored heat indicators next to each muscle group:
- Green = Fresh (ready to train)
- Yellow = Partially recovered
- Red = Fatigued (needs rest)

**iOS:** Muscle heatmap exists in profile (`MuscleHeatmapView.swift`) but is NOT shown during active workout.

**Files to Port:**
- `old-version/components/active-workout/MuscleFreshnessIndicator.tsx`
- Integration of freshness score into exercise cards

---

#### 7. Fatigue-Based Recommendations
**Web:** Shows "Recommended exercises" section based on:
- Muscle freshness from last workout
- Recovery status
- Exercise preferences

**iOS:** Fatigue monitoring exists in profile but not integrated into workout suggestions.

**Files to Port:**
- `old-version/utils/fatigueUtils.ts`
- `old-version/components/train/FatigueRecommendationSection.tsx`

---

#### 8. Untimely Set UI
**Web:** Dedicated UI for starting and timing sets:
- Start timer button
- Running clock display
- Save timed set as performed set

**iOS:** No equivalent UI (though rest timer exists).

**Files to Port:**
- Integration with `ActiveWorkoutContext.startTimedSet`
- Real-time timer display component

---

#### 9. RPE Display
**Web:** Shows RPE (Rate of Perceived Exertion) for sets:
- 1-10 scale selector
- Visual RPE badge on each set
- Color coding based on intensity

**iOS:** RPE type exists in model but no input/display UI during workout.

**Files to Port:**
- `old-version/components/active-workout/RPESelector.tsx`
- RPE display on `SetItem` component

---

#### 10. Plate Calculator UI
**Web:** Shows physical plate breakdown:
- Visual representation of plates on each side
- Total weight breakdown
- Plate count display

**iOS:** Plate calculation is in `WeightUtils.swift` but no visual UI.

---

#### 11. Exercise History Modal
**Web:** Tap on exercise to see:
- All previous sessions with this exercise
- Progress chart over time
- Best weight/reps records

**iOS:** No drill-down history during active workout.

---

#### 12. Set Inheritance System
**Web:** Smart inheritance for supersets:
- `isWeightInherited` flags
- `isRepsInherited` flags
- `isTimeInherited` flags

This allows setting weight/reps once for a superset.

**iOS:** Missing these `PerformedSet` fields.

---

#### 13. Undo Workout
**Web:** "Undo last workout" button in some cases.

**iOS:** No equivalent feature.

**Data Model Gap:** iOS model missing `previousVersion` field that `WorkoutExercise` has in web.

---

#### 14. Routine Suggestions
**Web:** "Suggested for you" section at bottom of workout with:
- Muscle-based recommendations
- Progression suggestions
- Quick-add buttons

**iOS:** No equivalent suggestions during workout.

---

### MEDIUM PRIORITY GAPS (Partial Implementation)

#### 15. Workout Validation Messages
**Web:** Shows specific validation messages:
- "You haven't done any sets"
- "Exercise X is incomplete"
- Detailed per-exercise status

**iOS:** Generic validation exists ("no exercises added") but lacks granular detail.

**Location:** `ActiveWorkoutView.swift` - `showFinishConfirmation()`

---

#### 16. Visual PR Indicators During Set
**Web:** Shows PR badges on sets when achieved:
- 🏆 Max Weight badge
- 🎯 Max Reps badge  
- ⚡ Max Volume badge

**iOS:** PRs tracked in `PersonalRecord` model but no visual feedback during workout.

---

#### 17. Workout Notes
**Web:** Free-text notes per workout session.

**iOS:** No notes field on `WorkoutSession`.

---

#### 18. Exercise Notes
**Web:** Notes per exercise (form cues, observations).

**iOS:** No notes field on `WorkoutExercise`.

---

#### 19. Smart Starting Weight Calculation
**Web:** When upgrading an exercise, calculates smart starting weight:
- `Math.max(workingWeight, workingWeight * 0.9)`
- Prefers 90% of previous or full weight

**iOS:** Uses simpler 80% calculation in `WorkoutManager.swift`.

---

#### 20. Progress Percentage Displays
**Web:** Shows workout progress percentage:
- "3 of 5 exercises complete (60%)"

**iOS:** Exercise count shown but no percentage calculation.

---

## Data Model Gaps

### `PerformedSet` Missing Fields (iOS)

```swift
// Web has these fields that iOS doesn't:
var isWeightInherited: Bool = false
var isRepsInherited: Bool = false
var isTimeInherited: Bool = false
var historicalWeight: Double?  // weight from previous session
var historicalReps: Int?
var historicalTime: Int?       // seconds
var storedBodyWeight: Double?
```

### `WorkoutExercise` Missing Fields (iOS)

```swift
// Web has these fields that iOS doesn't:
var barWeight: Double = 0      // bar/kettlebell weight
var previousVersion: WorkoutExercise? // state versioning for undo
```

### `WorkoutSession` Missing Fields (iOS)

```swift
// Web has these fields that iOS doesn't:
var notes: String = ""
var validations: Map<String, ValidationMessage>
```

## Service/Logic Gaps

### Missing Services in iOS (vs Web)

| Service | Purpose | Web Location |
|---------|---------|--------------|
| `audioService` | Speech synthesis for coaching | `old-version/services/audioService.ts` |
| `speechService` | Text-to-speech queue management | `old-version/services/speechService.ts` |
| Smart promotion logic | Suggest exercise upgrades | `ActiveWorkoutPage.tsx` inline |
| Fatigue engine | Calculate muscle recovery | `old-version/utils/fatigueUtils.ts` |
| Recommendation engine | Suggest routines | `old-version/utils/recommendationUtils.ts` |

### Existing iOS Services (FortachonCore)

| Service | Status | Notes |
|---------|--------|-------|
| `WeightUtils.swift` | ✅ Exists | Plate calculator logic present |
| `WorkoutAnalytics.swift` | ✅ Exists | Analytics implemented |
| `RecommendationEngine.swift` | ✅ Exists | But not connected to workout UI |
| `ExerciseSeeder.swift` | ✅ Exists | Seed data present |
| `SupplementService.swift` | ✅ Exists | Supplements integrated |

---

## Architecture Differences

### State Management

| Aspect | Web | iOS |
|--------|-----|-----|
| Approach | React Context (`ActiveWorkoutContext`) | SwiftData + ObservableObject (`WorkoutManager`) |
| Real-time updates | Context provider re-renders | @Published property observers |
| Persistence | LocalStorage + API call | SwiftData (Core Data for Swift) |
| Undo support | State snapshots | Not implemented |

### Component Architecture

| Aspect | Web | iOS |
|--------|-----|-----|
| Exercise Cards | `ExerciseCard.tsx`, `SetItem.tsx`, `SetInput.tsx` | `ExerciseCardView.swift`, `SetRowView.swift` |
| Timed Exercises | `TimedExerciseCard.tsx` | **Not implemented** |
| Cardio | `CardioExerciseCard.tsx` | **Not implemented** |
| Coach Suggestions | `SmartCoachComponent.tsx` | **Not implemented** |
| Audio | `AudioCoachComponent.tsx` | **Not implemented** |

---

## File-by-File Comparison

### Web Workout Components (14 files)
```
old-version/components/active-workout/
├── ActiveWorkoutLayout.tsx          ✅ Partial (no audio coach)
├── AudioCoachComponent.tsx          ❌ Missing
├── WorkoutPromotionCard.tsx         ❌ Missing
├── SmartCoachComponent.tsx          ❌ Missing
├── ExerciseCard.tsx                 ✅ Implemented
├── TimedExerciseCard.tsx            ❌ Missing
├── CardioExerciseCard.tsx           ❌ Missing
├── SetItem.tsx                      ✅ Implemented
├── SetInput.tsx                     ✅ Implemented
├── RestTimerModal.tsx               ✅ Implemented
├── WarmupSetsSection.tsx            ✅ Partial (no plates UI)
├── ExerciseCardHeader.tsx           ✅ Implemented
├── ExerciseActions.tsx              ✅ Implemented
└── UpgradeExerciseModal.tsx         ✅ Implemented
```

### iOS Workout Views
```
fortachon-gym/Views/Components/
├── ActiveWorkoutView.swift          ✅ Main workout view
└── RestTimerView.swift              ✅ Rest timer overlay
```

---

## Priority Recommendations

### Phase 1: Critical Missing Features
1. **Smart Coach Suggestions** - High user impact
2. **Timed Exercise Tracking** - Core functionality gap
3. **Audio Feedback** - Unique selling point
4. **Historical Comparison** - Valuable context missing

### Phase 2: Visual Enhancements
5. **Muscle Freshness Indicators** in workout cards
6. **PR Visual Badges** during set completion
7. **Historical Arrows** (⬆️⬇️) for weight/reps
8. **Progress Percentage** display

### Phase 3: Advanced Features
9. **Cardio Distance Tracking**
10. **RPE Selector/Display**
11. **Plate Calculator Visual UI**
12. **Exercise History Modal**
13. **Set Inheritance for Supersets**
14. **Workout/Exercise Notes**

### Phase 4: Polish
15. **Undo Workout** capability
16. **Routine Suggestions** during workout
17. **Smart Starting Weight** improvement
18. **Extended Validation Messages**

---

## Code Snippets to Port

### 1. Smart Suggestions Logic (from ActiveWorkoutPage.tsx)
```typescript
// Lines 72-138: Exercise request upgrade/promotion
const getRequestablePromotions = (exerciseId: string): PromotionTarget[] => {
  const muscleFreshness = calculateMuscleFreshness(activeWorkout);
  return exercises
    .filter(ex => canPromote(ex, currentExercise, muscleFreshness))
    .map(ex => ({ from: exerciseId, to: ex.id }));
};

// Smart coach suggestions
const smartCoachSuggestions = useMemo(() => {
  const suggestions: CoachSuggestion[] = [];
  const fatiguedMuscles = getFatiguedMuscles(workoutHistory);
  const freshMuscles = getFreshMuscles(muscleFreshness);
  
  if (fatiguedMuscles.length > 0) {
    suggestions.push({
      type: 'avoid',
      muscles: fatiguedMuscles,
      message: `These muscles are still recovering from ${lastWorkoutName}`
    });
  }
  
  if (freshMuscles.length > 0) {
    suggestions.push({
      type: 'suggest',
      muscles: freshMuscles,
      message: `These muscles are fresh and ready to train!`
    });
  }
  
  return suggestions;
}, [activeWorkout, workoutHistory]);
```

### 2. Audio Coach Hook (from useAudioCoach.ts)
```typescript
const useAudioCoach = () => {
  const speak = useCallback((message: string) => {
    speechService.speak(message, {
      rate: 1.0,
      pitch: 1.0,
      language: currentLanguage === 'es' ? 'es-ES' : 'en-US'
    });
  }, [currentLanguage]);
  
  const announceSetComplete = useCallback((exercise: string, set: number, weight: number, reps: number) => {
    speak(`${exercise}. Set ${set}. ${weight} kilos, ${reps} reps.`);
  }, [speak]);
  
  const announcePR = useCallback((type: string, exercise: string, value: number) => {
    speak(`New ${type} record! ${exercise}: ${value}`);
  }, [speak]);
  
  return { speak, announceSetComplete, announcePR };
};
```

### 3. Historical Comparison Logic (from SetItem.tsx)
```typescript
const HistoricalIndicator: React.FC<{ current: number, historical: number | null }> = ({ current, historical }) => {
  if (!historical) return null;
  
  const diff = current - historical;
  const isPositive = diff > 0;
  
  return (
    <span className={`indicator ${isPositive ? 'positive' : 'negative'}`}>
      {isPositive ? '⬆️' : '⬇️'} {Math.abs(diff).toFixed(1)}
    </span>
  );
};
```

### 4. Muscle Freshness Score (from fatigueUtils.ts)
```typescript
export const calculateMuscleFreshness = (
  muscle: string,
  lastWorkoutDate: Date | null,
  recoveryHours: number = 48
): FreshnessScore => {
  if (!lastWorkoutDate) return 'fresh';
  
  const hoursSince = Date.now() - lastWorkoutDate.getTime();
  const recoveryMs = recoveryHours * 60 * 60 * 1000;
  
  if (hoursSince >= recoveryMs) return 'fresh';
  if (hoursSince >= recoveryMs / 2) return 'partial';
  return 'fatigued';
};
```

---

## Conclusion

The iOS version has a **solid foundation** for basic workout tracking but is missing approximately **14+ features** that enhance the workout experience. The most impactful gaps are:

1. **Smart coaching** (automatic suggestions based on recovery)
2. **Audio feedback** (hands-free workout guidance)
3. **Timed exercise tracking** (for isometric/timed workouts)
4. **Historical context** (comparing to previous sessions)
5. **Visual indicators** (freshness, PRs, progress)

The good news is that **FortachonCore already contains most of the business logic** (`RecommendationEngine.swift`, `WeightUtils.swift`, `WorkoutAnalytics.swift`). The gap is primarily in the **UI layer** - these services aren't connected to the workout views.

**Estimated effort to reach parity:** ~30-40 hours of development for the high-priority items, assuming business logic porting is straightforward.