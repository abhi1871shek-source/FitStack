# FitStack — Comprehensive Project Summary & Feature Documentation

FitStack is a modern, cross-platform health and fitness tracking application built with **Flutter**, **Riverpod**, and **Supabase**. It helps users build daily habits, log gym workouts, track nutrition macros, and monitor long-term consistency in one low-friction app.

---

## 1. 🛠️ Technology Stack & Architecture

| Layer | Technology | Description |
| --- | --- | --- |
| **Framework** | **Flutter 3.x (Dart 3.x)** | Single codebase targeting Web, Desktop (Windows/macOS), and Mobile (iOS/Android). |
| **State Management** | **Flutter Riverpod 2.6** | Reactive state management using `NotifierProvider`, `StateNotifierProvider`, and `ConsumerWidget`. |
| **Backend & Auth** | **Supabase (`supabase_flutter`)** | Cloud authentication (Email/Password & Google OAuth) and PostgreSQL database with Row-Level Security (RLS). |
| **Theme & Persistence** | **`SharedPreferences`** | Local preference caching for persistent Light Mode / Dark Mode state. |
| **Notifications** | **`flutter_local_notifications`** | Local push notifications & scheduled habit reminders with timezone support. |
| **Typography & Styling** | **`google_fonts` (Inter)** | "Kinetic Discipline" design system featuring curated light/dark palettes, custom cards, and smooth micro-animations. |

---

## 2. 📱 Core Features & Modules

### 🔐 1. Authentication & Onboarding
- **Supabase Authentication**: Email/password login & signup with form validation and password visibility toggles.
- **Multi-Step Onboarding**:
  - Step 1: User Profile Metrics (Age, Height in cm, Weight in kg, Biological Sex).
  - Step 2: Fitness Goals & Experience (Primary Goal, Experience Level, Body Type).
  - Step 3: Health Conditions & Dietary Preferences (Multi-select health condition chips).
  - Step 4: Summary & Confirmation step syncing answers directly to Supabase `profiles` table.

---

### 🏠 2. Home Dashboard
- **Daily Overview**: Greeting, live date header, and active streak counter badge.
- **Quick-Add Actions**: One-tap modal buttons to `Add Habit`, `Add Workout`, and `Quick Add Food`.
- **Live Module Telemetry**:
  - **Today's Habits Card**: Live progress bar, completed count, and pending habit previews.
  - **Today's Workout Card**: Active muscle group focus, exercise completion progress, and quick-toggle exercise list.
  - **Diet & Nutrition Card**: Calorie counter vs daily target, progress bar, and macro breakdown pills (Protein, Carbs, Fat).
  - **Overall Daily Adherence Card**: Step count telemetry & calculated combined adherence percentage.
- **Account Dropdown & Dark Mode**:
  - Interactive profile avatar menu.
  - **Dark Mode Toggle**: Unambiguous switch toggle (`value: isDark`, label: "Dark Mode") applying dark theme app-wide.
  - Navigation link to **Account Settings**.

---

### ⚙️ 3. Account Settings & Profile Editing
- **Settings Screen ([`settings_screen.dart`](file:///c:/Users/ABHISHEK%20K/OneDrive/Projects/FitStack/lib/features/profile/screens/settings_screen.dart))**:
  - Allows users to view and update onboarding profile attributes:
    - Display Name / Full Name
    - Age, Weight (kg), and Height (cm)
    - Biological Sex, Primary Fitness Goal, Experience Level, Body Type
    - Health & Physical Conditions
  - **Real-Time Sync**: Saving updates the `profiles` table in Supabase and updates Riverpod `authProvider` state instantly across the app.

---

### 📋 4. Habits & To-Do List
- **Time-of-Day Grouping**: Habits organized logically into `Morning`, `Afternoon`, and `Evening` sections.
- **↔️ Bidirectional Mobile Swipe**:
  - `Dismissible` swipe right to mark complete (green accent feedback).
  - `Dismissible` swipe left to undo/incomplete.
- **Category Filter Chips**: Filter habits by `All Tasks`, `Morning`, `Afternoon`, `Evening`.
- **Notification Reminders**: Habit creation modal with customizable time picker and pre-event notifications (e.g. 5m, 10m, 15m before).
- **Streak Tracker**: Animated flame counter (`AnimatedStreakCounter`) displaying consecutive completion days.

---

### 🥗 5. Diet & Nutrition Module
- **Macro Telemetry Overview**: Live tracking of Calories, Protein (g), Carbs (g), Fat (g), and Fiber (g) against user daily targets.
- **Quick Add Food Modal**:
  - Segmented Mode Switcher: `[ Select from Library ]` vs `[ + Custom Food ]`.
  - Full Custom Food creation form (Name, Cuisine, Dietary Type, Base Weight, Calories, Protein, Carbs, Fat, Fiber).
  - Saves custom foods to Supabase `food_items` database table with local fallback logging.
- **Master Food Database**:
  - Search bar + Cuisine filter chips (`North Indian`, `South Indian`, `Kerala`, `American`, `Mediterranean`, `Chinese`, etc.).
  - Clean card design with visible cuisine badges removed to prevent visual clutter.
- **Weekly Meal Plan & Diet Preferences**:
  - 7-day auto-generated meal plan (`DietWeeklyPlanScreen`) with meal swapping functionality.
  - Diet preferences screen (`DietPreferenceScreen`) for target calorie calculation and cuisine selection.

---

### 🏋️ 6. Workout & Exercise Library
- **Today's Workout Screen**:
  - Muscle group-focused workout tracking.
  - Bidirectional swipe-to-complete on exercise sets (`Dismissible`).
  - Sets / Reps / Weight quick edit modal (`WorkoutQuickEditSheet`).
- **Exercise Library Browser**:
  - Searchable exercise library with MIT-licensed demonstration images and muscle group filtering (`Chest`, `Back`, `Legs`, `Arms`, `Shoulders`, `Core`).
  - Multi-select exercises to add directly to today's workout log.
- **7-Day Workout Plan**:
  - Weekly workout schedule (`WorkoutWeeklyPlanScreen`) highlighting today's muscle focus.
  - Interactive day focus editor dialog (`EditDayFocusDialog`).

---

### 📊 7. Progress & Analytics
- **Today's Progress Screen**:
  - Interactive step count ring, calories burned, active workout time.
  - Breakdown by category (Habits, Workout, Diet).
- **Weekly & Monthly Consistency Analytics**:
  - Consistency Matrix grid, weekly adherence trend charts (+6% vs last week), and AI health insights.

---

## 3. 📁 Directory Structure Overview

```
lib/
├── core/
│   ├── config/          # Supabase & app configuration
│   ├── services/        # Notification service & local storage
│   ├── theme/           # AppColors, AppTheme (Light & Dark), ThemeProvider
│   └── widgets/         # ResponsiveScaffold, EmojiProgressBar, AnimatedStreakCounter
├── features/
│   ├── auth/            # AuthProvider, UserModel, LoginSignupScreen
│   ├── dashboard/       # HomeDashboardScreen
│   ├── diet/            # FoodLogScreen, FoodDatabaseScreen, QuickAddFoodSheet, WeeklyDietPlan
│   ├── habits/          # TodoListScreen, HabitsProvider, HabitItem
│   ├── onboarding/      # OnboardingFlowScreen, OnboardingProfileStep, OnboardingReviewStep
│   ├── profile/         # SettingsScreen
│   ├── progress/        # ProgressTodayScreen, WeeklyMonthlyAnalyticsScreen
│   └── workout/         # WorkoutTodayScreen, WorkoutAddLibraryScreen, WorkoutWeeklyPlanScreen
├── navigation/          # MainShell, NavigationProvider
└── main.dart            # Application entry point & ProviderScope
```

---

## 4. 🚀 Running the Project

### Web Mode (Local Web Server)
```bash
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

### Windows Desktop Mode
```bash
flutter run -d windows
```

### Analysis & Lint Verification
```bash
flutter analyze
```
