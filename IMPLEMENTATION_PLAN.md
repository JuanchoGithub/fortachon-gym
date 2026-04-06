# Implementation Plan: Missing Features in iOS vs Web

[Overview]
Single sentence: Identify and catalogue all features present in the web version of Fortachon Gym that are missing from the iOS (SwiftUI) version, then create an implementation roadmap.

This analysis compares the React/TypeScript web application (`old-version/`) against the native iOS SwiftUI application (`fortachon-gym/`) to catalog every feature, screen, and capability that exists in the web version but has not yet been ported to the iOS app. The goal is to produce a prioritized implementation plan for closing these gaps.

[Types]
Single sentence: No new type definitions are required — this plan catalogs existing features and their status.

The following data structures and patterns exist in the web version that need corresponding iOS implementations:

**Web Types (from `old-version/types/index.ts`) not fully mirrored:**
- `UserProfile`: Full profile including `historyChartConfigs`, `promotionSnoozes`, `goalMismatchSnoozedUntil`, `lastWorkoutFinished`
- `HistoryChartConfig`: `{ id, type: 'total-volume' | 'exercise-volume', exerciseId }` — configurable chart dashboard
- `AutoUpdateEntry`: Auto-updated 1RM tracking with undo support
- `SupplementPlanItem`: With `restDayOnly`, `trainingDayOnly`, `takenDate`, `stock`, `planId`
- `SupplementPlan`: Full plan structure with `info` containing `trainingDays`, `trainingTime`, `startDate`
- `Promotion`: `{ fromId, toId, fromName, toName, exerciseId }` — exercise replacement upgrade system
- `UnlockEvent`: Exercise unlock tracking with `fromExercise` and `toExercise`
- `CascadePair`: Parent-child exercise weight relationship (e.g., Bench Press → Dumbbell Press)
- `WorkoutSession`: Fields like `supersets`, `note`, `bodyWeightEntry`
- `SupersetDefinition`: `{ id, name, exercises: string[], color }`
- `PerformedSet`: Fields like `rpe`, `distance`, `storedBodyWeight`, `isWeightInherited`, `isRepsInherited`, `isTimeInherited`
- `LifterDNA`: `consistencyScore`, `volumeScore`, `intensityScore`, `experienceLevel`, `archetype`, `favMuscle`, `efficiencyScore`

[Files]
Single sentence: No files will be created or deleted — this is an audit document; subsequent implementation tasks will create/modify files.

**Web Pages (11 pages) → iOS Implementation Status:**

| Web Page | Description | iOS Status | Gap Severity |
|----------|-------------|------------|--------------|
| `TrainPage.tsx` | Main training dashboard | Partially implemented (`TabTrainView.swift`) | Medium |
| `ActiveWorkoutPage.tsx` | Active workout screen | Partially implemented (`ActiveWorkoutView`) | HIGH |
| `HistoryPage.tsx` | History with chart tabs | Partially implemented (`TabHistoryView.swift`) | Medium |
| `ExercisesPage.tsx` | Exercise browser | Implemented (`TabExercisesView.swift`) | Low |
| `AddExercisePage.tsx` | Add exercises to workout | Partially implemented | Medium |
| `ExerciseEditorPage.tsx` | Edit exercise details | Not implemented | Medium |
| `HistoryWorkoutEditorPage.tsx` | Edit past workout entries | Not implemented | HIGH |
| `TemplateEditorPage.tsx` | Edit workout templates | Implemented (`TemplateEditorView.swift`) | Low |
| `ProfilePage.tsx` | User profile & settings | Partially implemented (`TabProfileView.swift`) | Medium |
| `TimersPage.tsx` | Timer hub (HIIT, EMOM, Tabata, AMRAP) | Partially implemented | HIGH |
| `SupplementPage.tsx` | Supplement management | Partially implemented | Medium |

**Web Components with No iOS Equivalent:**

| Component Cluster | Key Components | Purpose | Priority |
|------------------|----------------|---------|----------|
| `onerepmax/` | `OneRepMaxDetailView.tsx`, `OneRepMaxHub.tsx`, `CascadeUpdateModal.tsx` | Detailed 1RM tracking with cascade relationships | HIGH |
| `insights/` | `MuscleHeatmap.tsx` | Muscle recovery visualization | Implemented (basic) |
| `history/` | `HistoryChartsTab.tsx` | Configurable per-exercise charts | HIGH |
| `train/` | `SmartRecommendationCard.tsx`, `QuickTrainingSection.tsx`, `SupplementActionCard.tsx` | Smart coaching | Medium |
| `profile/` | `LifterDNA.tsx`, `StrengthProfile.tsx`, `FatigueMonitor.tsx`, `WeightChartModal.tsx` | Advanced analytics | Partially implemented |
| `modals/` | `PromotionReviewModal.tsx`, `CascadeUpdateModal.tsx`, `ConfirmNewWorkoutModal.tsx` | Various user flows | HIGH |
| `common/` | `FullScreenChartModal.tsx`, `ChartBlock.tsx` | Chart infrastructure | Medium |
| `components/active-workout/` | `WorkoutModalManager.tsx`, `WorkoutExerciseList.tsx` | Active workout UX | HIGH |

[Functions]
Single sentence: The following functions and logic systems exist in the web version but have no iOS equivalent.

**Active Workout Functions (Missing):**
| Function / System | Web Location | Purpose |
|-------------------|--------------|---------|
| `handleCoachSuggest()` | `ActiveWorkoutPage.tsx:203` | Coach-suggests workout based on fatigue analysis |
| `handleAggressiveSuggest()` | `ActiveWorkoutPage.tsx:257` | Ignore fatigue, suggest freshest muscle group |
| `handleRequestUpgrade()` | `ActiveWorkoutPage.tsx:125` | Offer exercise upgrade (easier variation → harder) |
| `handleConfirmUpgrade()` | `ActiveWorkoutPage.tsx:136` | Confirm exercise replacement during workout |
| `handleRollbackExercise()` | `ActiveWorkoutPage.tsx:166` | Undo a previous exercise upgrade |
| `getAvailablePromotion()` | `recommendationUtils.ts` | Check if exercise has an available upgrade |
| `validateWorkout()` | `useWorkoutInteractions.ts` | Validate sets are complete before finishing |
| Reorganize/drag-drop exercises | `useWorkoutReordering.ts` | Drag-and-drop exercise reordering |

**History/Chart Functions (Missing):**
| Function / System | Web Location | Purpose |
|-------------------|--------------|---------|
| Custom chart configuration | `HistoryChartsTab.tsx:47-64` | User-configurable chart dashboard |
| Exercise frequency analysis | `HistoryChartsTab.tsx:36-45` | Track which exercises are performed most |
| Quick add recent exercises to charts | `HistoryChartsTab.tsx:152-179` | Auto-populate charts from recent history |
| Chart reordering/drag | `HistoryChartsTab.tsx:126-136` | Reorder charts via move up/down |
| Load more pagination | `HistoryPage.tsx:74-80` | Pagination for history list |

**Supplement Stack Functions (Missing):**
| Function / System | Web Location | Purpose |
|-------------------|--------------|---------|
| Smart Stack (time-based) | `TrainPage.tsx:172-347` | Context-aware supplement recommendations |
| Post-workout stack | `TrainPage.tsx:196-247` | Special stack when in post-workout window |
| Retroactive pre-workout catch-up | `TrainPage.tsx:202-224` | Show missed pre/intra-workout supplements |
| Batch take supplements | `TrainPage.tsx:482-488` | Log multiple supplements at once |
| Batch snooze supplements | `TrainPage.tsx:490-495` | Snooze entire stack |

**Profile/Analytics Functions (Missing):**
| Function / System | Web Location | Purpose |
|-------------------|--------------|---------|
| `calculateLifterDNA()` | `analyticsService.ts` | Comprehensive lifter statistics |
| `inferUserProfile()` | `analyticsService.ts` | Infer user profile from history |
| `analyzeUserHabits()` | `analyticsService.ts` | Analyze exercise frequency patterns |
| `getSmartStartingWeight()` | `analyticsService.ts` | Suggest starting weight for exercises |
| Promotion snooze management | `ProfilePage.tsx:447-460` | Snooze exercise promotions |
| Weight chart visualization | `WeightChartModal.tsx` | Interactive body weight history chart |
| Import data validation | `ProfilePage.tsx:307-338` | JSON import with confirmation dialog |
| Export data generation | `ProfilePage.tsx:431` | JSON export of all user data |

**Recommendation Functions (Missing):**
| Function / System | Web Location | Purpose |
|-------------------|--------------|---------|
| Imbalance detection | `recommendationUtils.ts` | Detect muscle imbalances |
| Imbalance snoozing | `TrainPage.tsx:462-468` | Snooze imbalance warnings for 7 days |
| 1RM update snoozing | `TrainPage.tsx:476-479` | Snooze auto-calculated 1RM updates |
| Promotional exercise upgrades | `recommendationUtils.ts` | Suggest harder exercise variations |
| Expandable recommendation cards | `TrainPage.tsx:586-618` | Expandable coach/supplement cards |

[Classes]
Single sentence: Several class-like modules and service layers exist in web that need iOS equivalents.

**Services needing iOS equivalents:**

| Web Service | Purpose | iOS Equivalent Status |
|-------------|---------|----------------------|
| `analyticsService.ts` | All analytics, smart weights, lifter DNA | Not implemented |
| `recommendationUtils.ts` | Smart recommendations, promotions | Partially (FortachonCore/RecommendationEngine.swift) |
| `speechService.ts` | Text-to-speech with voice selection | Basic (AVSpeechSynthesisVoice+Extension.swift) |
| `notificationService.ts` | Push notification management | Partially (NotificationUtils.swift) |
| `audioService.ts` | Audio playback during workouts | Basic (AudioCoach.swift) |
| `explanationService.ts` | Exercise explanation text | Not implemented |
| `syncService.ts` | Cloud synchronization | Partially (ICloudSyncService.swift, CloudSyncService.swift in Core) |
| `dataService.ts` | API data operations | Not applicable (iOS uses local SwiftData) |
| `pushService.ts` | Push notifications | Not implemented (iOS uses native) |
| `supplementService.ts` | Supplement tracking | Partially |
| `timerService.ts` | Timer management | Partially |

**Key Web Contexts (state management) needing iOS ViewModels:**

| Context | Purpose | iOS Status |
|---------|---------|------------|
| `ActiveWorkoutContext` | Active workout state | Partially (ActiveWorkoutViewModel) |
| `DataContext` | Data operations | Partially (SwiftData queries) |
| `TimerContext` | Timer management | Partially |
| `StatsContext` | Cached statistics | Partially (EngagementManager) |
| `SupplementContext` | Supplement state | Partially |
| `I18nContext` | Internationalization | Not implemented (no i18n system) |
| `AuthContext` | Authentication | Not implemented (planned via AuthService) |

[Dependencies]
Single sentence: No new external dependencies are required — all missing features should be implementable with native iOS frameworks and existing FortachonCore shared code.

The FortachonCore Swift package (`FortachonCore/`) already provides shared types including:
- `Models.swift` — Data models (ExerciseM, PerformedSetM, etc.)
- `RecommendationEngine.swift` — Recommendation logic
- `RoutineGenerator.swift` — Smart routine generation
- `AnalyticsUtils.swift` — Shared analytics helpers
- `FatigueUtils.swift` — Muscle freshness calculations
- `ProgressionConstants.swift` — Progressive overload rules
- `RatioConstants.swift` — Exercise weight ratios
- `ExerciseLocalizedNames.swift` — Bilingual exercise names
- `ExerciseInstructions.swift` — Exercise instruction content
- `LifterProfile.swift` — Lifter profile data
- `FilterConstants.swift` — Filter configuration
- `MuscleConstants.swift` — Muscle group constants

The main gap is in the iOS app layer — views, view models, and business logic that should consume these shared types.

[Testing]
Single sentence: Testing strategy should follow the web version's patterns — unit test all analytics/recommendation logic, then integration test the UI flows.

**Testing Areas:**
- Unit tests for `AnalyticsUtils` (lifter DNA, smart weights)
- Unit tests for `RecommendationEngine` (imbalance detection, promotions)
- Unit tests for `RoutineGenerator` (smart routine generation)
- Integration tests for active workout flow (coach suggest, upgrade, rollback)
- Integration tests for configurable chart dashboard
- Integration tests for supplement stack logic
- UI tests for history list with pagination
- UI tests for workout completion validation
- Visual regression tests against web version (where applicable)

[Implementation Order]
Single sentence: Implement features in order of user impact and complexity, starting with the most visible gaps and working toward refinements.

**Phase 1 — Active Workout Enhancements (HIGH IMPACT, user-facing)**
1. ActiveWorkoutViewModel: Add coach suggestion system (normal + aggressive mode)
2. ActiveWorkoutView: Add coach suggest button + suggestion modal
3. Add exercise promotion/upgrade system during workouts (simpler → harder exercise)
4. Add exercise rollback capability (undo upgrade)
5. Add workout completion validation (check for incomplete sets before finishing)
6. Add drag-and-drop exercise reordering mode

**Phase 2 — History Charts & Analytics (HIGH IMPACT, user-facing)**
7. History page: Add configurable chart dashboard (per-exercise volume charts)
8. History page: Add chart edit mode (add/remove/reorder charts)
9. History page: Add "add last exercises" quick-fill feature
10. History page: Add history workout editor page (edit past sessions)
11. History page: Add load more pagination
12. History page: Improve save-as-template from history flow

**Phase 3 — One Rep Max System (HIGH IMPACT, power users)**
13. OneRepMaxDetailView: Full 1RM history chart per exercise (expand existing OneRepMaxView)
14. OneRepMaxHub: Overview of all 1RMs with progress tracking
15. CascadeUpdateModal: When parent exercise 1RM updates, propagate to child exercises
16. Auto-update 1RM notifications with undo/dismiss

**Phase 4 — Train Page Smart Features (MEDIUM IMPACT, daily use)**
17. SmartRecommendationCard: Add expandable/collapsible state
18. SupplementActionCard: Add smart stack logic (time-based + post-workout context)
19. Imbalance detection and snoozing (7-day snooze)
20. Promotion system (exercise upgrade suggestions across all templates)
21. PromotionReviewModal: Review and apply promotions with snooze option
22. Create template modal: Add wizard option (OnboardingWizard equivalent)

**Phase 5 — Timers Expansion (HIGH IMPACT, frequent use)**
23. Timers page: Add EMOM timer mode
24. Timers page: Add Tabata timer mode
25. Timers page: Add AMRAP timer mode
26. Timers page: Add Stopwatch timer mode
27. TimerContext: Unified timer state management

**Phase 6 — Profile & Settings Enhancements (MEDIUM IMPACT)**
28. ExerciseEditorPage: Full exercise editing (instructions, muscles, timed flag)
29. AddExercisePage: Improved exercise selection with search/filter
30. Profile: Supplement detail page with stock tracking
31. Profile: Weight chart improvements
32. Profile: Import data validation with detailed summary modal
33. i18n system: Full internationalization support (currently hardcoded English/Spanish)

**Phase 7 — Polish & Edge Cases (LOW IMPACT, refinements)**
34. Full-screen chart modal for all chart views
35. RPE tracking per set
36. Distance tracking for cardio exercises
37. Body weight per set logging
38. Shared set inheritance for supersets (isWeightInherited, isRepsInherited)
39. Audio improvements (superset player audio cues)
40. Cloud sync conflict resolution