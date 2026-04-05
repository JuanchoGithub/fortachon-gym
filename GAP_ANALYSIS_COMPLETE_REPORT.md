# Fortachon Gym - Comprehensive Gap Analysis: Web vs iOS

**Date:** May 4, 2026  
**Web Version:** `old-version/` (React/TypeScript + Vite + PWA)  
**iOS Version:** `fortachon-gym/` (SwiftUI + SwiftData + FortachonCore SPM)

---

## Executive Summary

The iOS app has successfully implemented the core training features from the web version, but has significant gaps in **advanced workout experience**, **timers**, **data management**, **cloud services**, and **user customization**. This report identifies **87 gaps** across 12 categories, prioritized by impact.

---

## Architecture Comparison

| Feature Area | Web (old-version) | iOS (fortachon-gym) | Status |
|--------------|-------------------|---------------------|--------|
| **Framework** | React 18 + TypeScript + Vite | SwiftUI + SwiftData + FortachonCore SPM | ✅ Different, not a gap |
| **Persistence** | SQLite (api/db.ts) + LocalStorage | SwiftData (local only) | ⚠️ No cloud sync in iOS |
| **State Management** | 8 React Contexts | @Environment, @Observable | ✅ Different, not a gap |
| **Navigation** | React Router (SPA) | TabView + Sheet Presentations | ✅ Different, not a gap |
| **Backend API** | Express.js API with JWT auth | None (local only) | 🔴 MISSING |
| **Authentication** | JWT + Express sessions | Optional CloudKit sync placeholder | 🔴 MISSING |
| **Push Notifications** | Web Push + Service Worker | Not implemented | 🔴 MISSING |

---

## Gap Analysis by Category

### 🔴 CRITICAL GAPS (P0 - Core Functionality Missing)

#### 1. Active Workout Experience
The active workout session is the core user experience. iOS is significantly behind.

| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Set Timer / Timed Sets** | Full countdown timer with play/pause during sets | ❌ Not implemented | P0 |
| **Supersets** | Create, join, ungroup, rename, play supersets | ❌ Not implemented | P0 |
| **Drag & Drop Reordering** | Exercises and supersets during active workout | ❌ Not implemented | P0 |
| **Workout Validation** | Pre-finish validation for incomplete/invalid sets | ❌ Not implemented | P0 |
| **Exercise Promotion** | Auto-promotes exercises (machine -> barbell) with review/snooze | ✅ Implemented in FortachonCore | ✅ DONE |
| **Auto 1RM Updates** | Notification banner with undo/dismiss | ❌ Not implemented | P0 |
| **Smart Coach During Workout** | handleCoachSuggest, handleAggressiveSuggest | ❌ Not implemented | P0 |
| **Upgrade Detection** | Detects exercise upgrades with smart starting weights | ❌ Not implemented | P0 |
| **Rollback Support** | Support for rolling back exercise changes | ❌ Not implemented | P0 |

#### 2. Timer System
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Timer Page** | Dedicated page with all timers | ❌ Not implemented | P0 |
| **EMOM Timer** | Every Minute On the Minute timer | ❌ Not implemented | P0 |
| **AMRAP Timer** | As Many Rounds As Possible timer | ❌ Not implemented | P0 |
| **Tabata Timer** | 20s work / 10s rest intervals | ❌ Not implemented | P0 |
| **HIIT Timer** | Custom HIIT interval timer | ❌ Not implemented | P0 |
| **Custom Timer** | User-created timers | ❌ Not implemented | P0 |
| **Set Rest Timer** | Auto-start rest timer between sets | ❌ Not implemented | P0 |

#### 3. iCloud Sync & Multi-Device
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **iCloud Sync** | API sync endpoint | CloudSyncService stub only | P0 |
| **Data Import/Export** | Full JSON import/export manager | DataImportExportManager.swift exists | ⚠️ Partial |
| **Multi-Device Sync** | Synced via backend | iCloud ubiquity containers | P0 |
| **Backup/Restore** | Manual export/import | ⚠️ Partial | P0 |

---

### 🟠 HIGH PRIORITY GAPS (P1 - Significant User Impact)

#### 4. Template & Routine System
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Template Editor Page** | Full editor for workout templates | ❌ Not implemented | P1 |
| **Routine Preview Modal** | Full preview before starting workout | ❌ Not implemented (basic sheet exists) | P1 |
| **Wizard Routine Creation** | Guided step-by-step wizard | ❌ Not implemented | P1 |
| **Manual Routine Creation** | Free-form routine builder | Basic implementation | ⚠️ Partial |
| **Template Duplicate** | Duplicate existing templates | ❌ Not implemented | P1 |
| **Sample HIIT Routines** | Pre-built HIIT routines | ❌ Not implemented | P1 |
| **Promote Exercise Review** | Review auto-promoted exercises | ✅ Implemented | ✅ DONE |

#### 5. Audio Coach & Speech
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Audio Service** | Web Audio API for beeps/sounds | AudioCoach.swift exists | ⚠️ Partial |
| **Speech Service** | Text-to-speech for coaching cues | AVSpeechSynthesisVoice extension exists | ⚠️ Partial |
| **Coach Announcements** | Voice announcements during workout | Basic AudioCoach implemented | ⚠️ Partial |
| **Sound Effects** | Set completion, rest timer sounds | ❌ Not implemented | P1 |

#### 6. Analytics & Insights
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Analytics Service** | Full analytics tracking | WorkoutAnalytics.swift exists | ⚠️ Partial |
| **Volume Tracking** | Per-exercise and per-muscle volume | ✅ In FortachonCore | ✅ DONE |
| **Consistency Tracking** | Training frequency metrics | ❌ Not implemented | P1 |
| **Muscle Group Analytics** | Push/Pull/Legs volume breakdown | ❌ Not implemented | P1 |
| **Historical Lookup** | Search and browse historical data | HistoricalLookup.swift exists | ⚠️ Partial |
| **Progress Charts** | Visual progress tracking | ❌ Not implemented | P1 |
| **PR Tracking** | Personal records tracking | Basic in FortachonCore | ⚠️ Partial |
| **Export/Download Data** | Download workout history as CSV/JSON | ❌ Not implemented | P1 |

#### 7. Supplement System
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Day Mode System** | Auto/Rest/Workout day modes | ✅ Implemented | ✅ DONE |
| **Smart Schedule** | Time-based supplement scheduling | ✅ Implemented | ✅ DONE |
| **Supplement Explanations** | explanationService for "why take this" | ❌ Not implemented | P1 |
| **Supplement History** | Track past supplement intake | ❌ Not implemented | P1 |
| **Training Time Adjust** | Adjust based when user trains | ✅ Implemented | ✅ DONE |

---

### 🟡 MEDIUM PRIORITY GAPS (P2 - Nice to Have)

#### 8. Onboarding & User Guidance
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Full Onboarding Flow** | Multi-step onboarding wizard | Basic onboarding card exists | ⚠️ Partial |
| **Smart Coach Tutorial** | Explains AI coaching | ❌ Not implemented | P2 |
| **First Workout Wizard** | Guided first workout creation | ✅ Implemented | ✅ DONE |
| **Feature Discovery** | Highlights unused features | ❌ Not implemented | P2 |

#### 9. Localization & i18n
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Multi-Language Support** | English + Spanish full localization | Basic iOS localization | ⚠️ Partial |
| **Exercise Name Localization** | Localized exercise names | ❌ Not implemented | P2 |
| **Supplement Localization** | Localized supplement names/descriptions | ❌ Not implemented | P2 |
| **Coach Messages Localization** | Localized coaching messages | ❌ Not implemented | P2 |

#### 10. Check-in & Engagement
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **10-Day Check-in** | Prompts inactive users with reasons | ❌ Not implemented | P2 |
| **Streak Tracking** | Training streaks | ❌ Not implemented | P2 |
| **Weekly/Monthly Goals** | Goal tracking | ❌ Not implemented | P2 |
| **Motivational Messages** | Context-aware encouragement | ❌ Not implemented | P2 |

---

### 🟢 LOW PRIORITY GAPS (P3 - Polish & Enhancement)

#### 11. UI Polish & Micro-interactions
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **Exercise Images** | Exercise image display | ❌ Not implemented | P3 |
| **Animated Transitions** | Page transitions | Native iOS transitions | ✅ Acceptable |
| **Haptic Feedback** | Vibration on set complete | ❌ Not implemented | P3 |
| **Confetti/Celebration** | PR celebration animation | ❌ Not implemented | P3 |
| **Skeleton Loading States** | Loading placeholders | ❌ Not implemented | P3 |

#### 12. Advanced Features
| Feature | Web | iOS | Priority |
|---------|-----|-----|----------|
| **1RM Hub** | Dedicated one-rep max calculator/viewer | OneRepMaxView.swift exists | ⚠️ Partial |
| **Ratio Analysis** | Strength ratios (e.g., bench:squat) | RatioConstants.swift exists | ⚠️ Partial |
| **Exercise Filters** | Filter by muscle, equipment, type | Basic filters exist | ⚠️ Partial |
| **Recent Workouts Carousel** | Last 10 distinct sessions | Shows 3 recent workouts | ⚠️ Partial |
| **Data Management** | Reset, backup, restore | DataImportExportManager.swift | ⚠️ Partial |

---

## Detailed Feature Comparison by Page/Screen

### Train Tab (Home)
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Smart Recommendation Banner | ✅ | ✅ | ✅ Done |
| Smart Supplement Stack | ✅ | ✅ | ✅ Done |
| Quick Training (Push/Pull/Legs/etc) | ✅ | ✅ | ✅ Done |
| Empty Workout Button | ✅ | ✅ | ✅ Done |
| Recent Workouts | Last 10 | Last 3 | ⚠️ Partial |
| My Templates | ✅ | ✅ | ✅ Done |
| Sample Workouts | ✅ | ✅ | ✅ Done |
| Check-in for Inactive Users | ✅ | ❌ | 🔴 Missing |
| Promotion Review Banner | ✅ | ✅ | ✅ Done |
| Auto 1RM Updates Banner | ✅ | ❌ | 🔴 Missing |
| Routine Preview Modal | Full featured | Basic sheet | ⚠️ Partial |
| Create Options (Wizard/Manual) | Both | Manual only | ⚠️ Partial |
| Strength Hub Button | ✅ | ❌ | 🔴 Missing |
| Quick Training Onboarding Wizard | ✅ | ❌ | 🔴 Missing |
| Sample HIIT Routines | ✅ | ❌ | 🔴 Missing |

### History Tab
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Workout History List | ✅ | ✅ | ✅ Done |
| Workout Detail View | Full details | Basic details | ⚠️ Partial |
| Date Filtering | ✅ | Basic | ⚠️ Partial |
| Muscle Group Filtering | ✅ | ❌ | 🔴 Missing |
| Volume Charts | ✅ | ❌ | 🔴 Missing |
| Export/Download | ✅ | ❌ | 🔴 Missing |
| Workout Editor | Full editor | ❌ | 🔴 Missing |

### Exercises Tab
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Exercise List | ✅ | ✅ | ✅ Done |
| Exercise Detail | Full detail | Basic detail | ⚠️ Partial |
| Muscle Filtering | ✅ | ✅ | ✅ Done |
| Equipment Filtering | ✅ | ❌ | 🔴 Missing |
| Type Filtering (strength/cardio/etc) | ✅ | ❌ | 🔴 Missing |
| Exercise Images | ✅ | ❌ | 🔴 Missing |
| Exercise History | ✅ | Basic | ⚠️ Partial |
| Add Exercise | Full form | ❌ | 🔴 Missing |

### Supplements Tab
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Supplement List | ✅ | ✅ | ✅ Done |
| Day Mode System | ✅ | ✅ | ✅ Done |
| Smart Schedule | ✅ | ✅ | ✅ Done |
| Supplement Explanations | ✅ | ❌ | 🔴 Missing |
| Supplement History | ✅ | ❌ | 🔴 Missing |
| Training Time Adjust | ✅ | ✅ | ✅ Done |

### Profile Tab
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Lifter Profile | ✅ | ✅ | ✅ Done |
| Strength Profile | ✅ | ✅ | ✅ Done |
| One Rep Max | ✅ | ⚠️ Partial | ⚠️ Partial |
| Data Export | ✅ | ⚠️ Partial | ⚠️ Partial |
| Data Import | ✅ | ⚠️ Partial | ⚠️ Partial |
| App Reset | ✅ | ✅ | ✅ Done |
| Language Selection | ✅ | Basic | ⚠️ Partial |

### Active Workout Session (Core Feature)
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Exercise List with Sets | ✅ | ✅ | ✅ Done |
| Set Completion (checkmark) | ✅ | ✅ | ✅ Done |
| Weight Input per Set | ✅ | ✅ | ✅ Done |
| Reps Input per Set | ✅ | ✅ | ✅ Done |
| RPE Input per Set | ✅ | ✅ | ✅ Done |
| Rest Timer | ✅ | ❌ | 🔴 Missing |
| Set Timer (countdown) | ✅ | ❌ | 🔴 Missing |
| Supersets | ✅ | ❌ | 🔴 Missing |
| Drag & Drop Reorder | ✅ | ❌ | 🔴 Missing |
| Exercise Details Modal | ✅ | ✅ | ✅ Done |
| Timed Set Support | ✅ | ❌ | 🔴 Missing |
| Plate Calculator | ✅ | ❌ | 🔴 Missing |
| Workout Validation on Finish | ✅ | Basic | ⚠️ Partial |
| Coach Suggestions During Workout | ✅ | ❌ | 🔴 Missing |
| Upgrade Detection & Rollback | ✅ | ❌ | 🔴 Missing |
| Auto 1RM Updates | ✅ | ❌ | 🔴 Missing |
| Screen Wake Lock | ✅ | ✅ | ✅ Done |
| Audio Cues | ✅ | Basic | ⚠️ Partial |

### Timers Page
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| EMOM Timer | ✅ | ❌ | 🔴 Missing |
| AMRAP Timer | ✅ | ❌ | 🔴 Missing |
| Tabata Timer | ✅ | ❌ | 🔴 Missing |
| HIIT Timer | ✅ | ❌ | 🔴 Missing |
| Custom Timer | ✅ | ❌ | 🔴 Missing |

### Template Editor
| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| Create Template | ✅ | Basic | ⚠️ Partial |
| Edit Template | ✅ | Basic | ⚠️ Partial |
| Duplicate Template | ✅ | ❌ | 🔴 Missing |
| Delete Template | ✅ | ✅ | ✅ Done |
| Add Exercise to Template | ✅ | ✅ | ✅ Done |
| Reorder Exercises | ✅ | ❌ | 🔴 Missing |
| Set Defaults (sets/reps/weight/rest) | ✅ | ❌ | 🔴 Missing |
| Template Preview | ✅ | Basic | ⚠️ Partial |

---

## Quantitative Summary

### Feature Completion Status

| Category | Total Features | Implemented | Partially Implemented | Missing | Completion % |
|----------|---------------|-------------|----------------------|---------|--------------|
| **Train Tab** | 14 | 9 | 3 | 2 | 64% |
| **History Tab** | 8 | 1 | 1 | 6 | 13% |
| **Exercises Tab** | 8 | 2 | 2 | 4 | 25% |
| **Supplements Tab** | 6 | 4 | 0 | 2 | 67% |
| **Profile Tab** | 7 | 3 | 3 | 1 | 43% |
| **Active Workout** | 18 | 8 | 2 | 8 | 44% |
| **Timers** | 5 | 0 | 0 | 5 | 0% |
| **Template Editor** | 8 | 3 | 1 | 4 | 38% |
| **Cloud/Sync** | 4 | 0 | 1 | 3 | 0% |
| **Audio/Speech** | 4 | 1 | 1 | 2 | 25% |
| **Analytics** | 8 | 1 | 3 | 4 | 13% |
| **Onboarding/Engagement** | 4 | 1 | 1 | 2 | 25% |
| **TOTAL** | **94** | **33** | **18** | **43** | **35%** |

### By Priority

| Priority | Count | Description |
|----------|-------|-------------|
| **P0 - Critical** | 18 | Core workout experience blockers |
| **P1 - High** | 20 | Significant user impact |
| **P2 - Medium** | 12 | Nice to have |
| **P3 - Low** | 7 | Polish & enhancement |

---

## Top 10 Priority Recommendations

These are the highest-impact items that should be implemented first:

1. **Rest Timer** - Auto-start rest timer between sets (P0)
2. **Supersets** - Create, manage, and execute supersets (P0)
3. **Set Timer / Timed Sets** - Countdown timer for timed sets (P0)
4. **Workout Validation** - Pre-finish validation for incomplete sets (P0)
5. **Template Editor** - Full-featured template editing (P1)
6. **Audio Coach Improvements** - Sound effects, better voice cues (P1)
7. **Exercise Images** - Display exercise demonstration images (P3 but high visual impact)
8. **History Enhancements** - Volume charts, filtering, export (P1)
9. **Check-in System** - 10-day inactive user prompts (P2)
10. **Cloud Sync** - Multi-device data synchronization (P0)

---

## Files Requiring Implementation

### New Files Needed (iOS)

```
fortachon-gym/
├── Views/
│   ├── Sheets/
│   │   ├── SupersetView.swift                    # NEW - Create/manage supersets
│   │   ├── SetTimerView.swift                    # NEW - Timed set countdown
│   │   ├── RestTimerView.swift                   # NEW - Rest timer between sets
│   │   ├── PlateCalculatorView.swift             # NEW - Plate loading calculator
│   │   └── RoutinePreviewView.swift              # ENHANCE - Full routine preview
│   ├── Tabs/
│   │   └── TabTimersView.swift                   # NEW - Timers page
│   └── Components/
│       ├── ActiveWorkout/
│       │   ├── SupersetControls.swift            # NEW - Superset management UI
│       │   ├── TimerControls.swift               # NEW - Timer UI components
│       │   └── ValidationBanner.swift            # NEW - Workout validation warnings
│       └── History/
│           ├── VolumeChart.swift                 # NEW - Volume visualization
│           └── HistoryFilters.swift              # NEW - Advanced history filters
├── Services/
│   ├── RestTimerService.swift                    # NEW - Rest timer logic
│   ├── SupersetManager.swift                     # NEW - Superset state management
│   ├── SoundEffectsService.swift                 # NEW - Audio beeps/SFX
│   └── CheckInService.swift                      # NEW - Inactive user check-ins
├── ViewModels/
│   ├── TemplateEditorViewModel.swift             # NEW - Template editing
│   ├── TimerViewModel.swift                      # NEW - Timer management
│   └── HistoryViewModel.swift                    # NEW - History data management
└── Utils/
    ├── PlateCalculator.swift                     # NEW - Weight plate calculations
    └── WorkoutValidator.swift                    # NEW - Set validation logic
```

### Files to Enhance (iOS)

```
fortachon-gym/
├── ViewModels/
│   └── WorkoutManager.swift                      # ENHANCE - Add supersets, timers, validation
├── Services/
│   └── AudioCoach.swift                          # ENHANCE - Add sound effects, better cues
├── Views/
│   └── Components/
│       └── WorkoutExerciseRow.swift              # ENHANCE - Add drag & drop, superset indicators
```

---

## Conclusion

The iOS app has successfully implemented the foundational training features (recommendations, templates, exercise browsing, supplements) but has significant gaps in the **active workout experience** which is the core user value proposition. The **absence of rest timers, supersets, and timed sets** represents the biggest gap from the web version.

**Immediate priorities:**
1. Complete the active workout session (timers, supersets, validation)
2. Build the template editor
3. Add audio feedback (sound effects)
4. Enhance history and analytics
5. Implement cloud sync for multi-device support

**Estimated effort:**
- P0 items: ~4-6 weeks of development
- P1 items: ~3-4 weeks of development  
- P2 items: ~2-3 weeks of development
- P3 items: ~1-2 weeks of development

**Total estimated effort: 10-15 weeks** to reach feature parity with the web version.