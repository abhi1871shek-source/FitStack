# FitStack — Project Brief

## 1. What is FitStack

FitStack is an all-in-one health app that helps users build daily habits, log gym workouts, and track their diet — all in one place. It's designed for someone trying to stay consistent with health goals: motivating, low-friction, and not overwhelming.

## 2. Platform & Tech Stack

- **Framework:** Flutter — single codebase targeting mobile (iOS/Android) AND desktop (Windows/macOS)
- **UI design source:** Google Stitch, exported and organized into the `/design` folder (one subfolder per screen)
- **State management:** Riverpod — chosen over Provider for more power, at the cost of a steeper learning curve. Since this is a newer concept for a beginner, Antigravity should explain Riverpod-specific terms (providers, notifiers, etc.) the first time each one is introduced in code.
- **Backend:** Not yet decided. Leaning toward Firebase (Authentication + Firestore database) for ease of setup — to be confirmed before backend work begins
- **External data needed (not something the app can invent on its own):**
  - A food/nutrition database or API (for calorie/protein/fat/fiber lookups) — e.g. USDA FoodData Central, Nutritionix, or Edamam
  - An exercise database: **Free-Exercise-DB** ([https://github.com/yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db), licensed under MIT License) for real exercise demonstration images and muscle group metadata.

## 3. Core Modules

1. **Onboarding & Auth** — login/signup, user profile setup (weight, height, experience level, goal, health concerns, body type), review/confirm screen
2. **Habits / To-Do** — daily task list with swipe-to-complete, streaks, add/edit/delete
3. **Progress** — today's step count, streak bar, today's breakdown by category, weekly/monthly analytics
4. **Diet / Food** — food database search, food log with macros, calorie progress bar, diet preferences (cuisine, dietary type, calorie target), auto-generated weekly diet plan (editable)
5. **Workout** — today's workout by muscle group, swipe-to-complete, add-workout exercise library (filterable by body part), weekly workout plan

## 4. Screens (from Stitch, organized in /design)

| Folder name | What it shows |
|---|---|
| login_signup | Email/password login, Google sign-in, link to sign up |
| onboarding_profile | Weight, height, experience level, goal, health concerns, body type selection |
| onboarding_review | Summary of onboarding answers for the user to confirm/edit before continuing |
| home_dashboard | **Not exported from Stitch (decision: skip re-exporting for now).** To be composed in Flutter by reusing existing components from progress_today, todo_list, workout_today, and food_log — habits summary, workout summary, calories so far, quick-add buttons. |
| todo_list | Daily habit/task list, swipe right = done, swipe left = not done, long-press to edit/delete |
| progress_today | Step count ring, streak bar, today's breakdown by category (habits/gym/diet) |
| weeklyandmonthly_analysis | Weekly/monthly view of progress, consistency matrix, insights |
| food_database | Search and select foods to add to today's log |
| food_log | Calorie/macro progress bar, today's logged meals by section (breakfast/lunch/etc.) |
| food_log_add | Quick-add-food modal: name, quantity, unit |
| diet_preference | Cuisine preferences (multi-select), dietary type, calculated daily calorie target, meals per day |
| diet_weekly_plan | Auto-generated weekly meal plan by day, editable, with per-day calorie totals |
| workout_today | Today's workout grouped by muscle group, swipe-to-complete, long-press to edit/delete |
| workout_add_library | Browse exercises by body part, multi-select to add to today's workout |
| workout_quick_edit | Edit sets/reps/weight for a specific exercise |
| workout_weekly_plan | 7-day workout plan by muscle group, editable, highlights today |

**Confirmed screen relationships (from Antigravity's audit):**
- `food_log_add` is a bottom-sheet modal over `food_log`, not a separate route
- `workout_quick_edit` is a bottom-sheet modal over `workout_today`, not a separate route
- `onboarding_profile` + `onboarding_review` are two steps of a single multi-step onboarding flow

## 5. Design System

- Style: clean, professional, "standard app" look — explicitly NOT a generic AI-generated look (no purple/blue gradients, no glassmorphism, no oversized bubbly shapes)
- Reference apps for feel: Apple Fitness+, Strava, Notion
- Colors: neutral base (white/off-white light mode, deep charcoal/near-black dark mode) + ONE consistent accent color used for actions, progress, and streaks
- Typography: clean sans-serif, similar to system fonts (SF Pro / Inter)
- Components: flat or subtly-shadowed cards, 8px-based spacing grid, simple line icons (no 3D/gradient icons)
- Logo: FitStack wordmark + icon mark (finalized separately, see logo files)

## 6. Status Checklist

- [x] App concept and feature list defined
- [x] All screens designed in Google Stitch
- [x] Screens exported and organized into `/design` (except home_dashboard, which will be composed from other screens' components)
- [ ] Flutter project scaffolded in Antigravity
- [ ] Navigation and project structure approved
- [ ] Screens implemented in Flutter (screen by screen)
- [ ] Backend chosen and set up (auth + database)
- [ ] Screens connected to real backend data
- [ ] Food/nutrition data source integrated
- [ ] Exercise database integrated
- [ ] Testing
- [ ] Deployment
