-- ==============================================================================
-- FitStack Production Schema for Supabase (PostgreSQL)
-- ==============================================================================
-- Designed specifically for FitStack models:
-- 1. profiles (User profile, biometric stats, onboarding)
-- 2. habits (Habit items, time of day, category, reminders, streaks)
-- 3. food_items (Master food items library)
-- 4. food_logs (Logged food entries with proportional macros and meal sections)
-- 5. diet_preferences (Cuisine selections, dietary type, calorie target, meals per day)
-- 6. weekly_diet_plans (7-day planned meals per user)
-- 7. exercises (Master exercise library sourced from Free-Exercise-DB)
-- 8. workout_logs (Workout session logs with sets, reps, weight)
-- 9. weekly_workout_plans (7-day workout routine split per user)
-- 10. daily_telemetry (Daily step count and completion metrics)
--
-- Row Level Security (RLS) is ENABLED on ALL tables with auth.uid() = user_id
-- ==============================================================================

-- Enable UUID extension if not already present
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT DEFAULT 'FitStack Athlete',
    is_profile_complete BOOLEAN NOT NULL DEFAULT FALSE,
    weight_kg NUMERIC(5,2),
    height_cm NUMERIC(5,2),
    age INT,
    biological_sex TEXT CHECK (biological_sex IN ('Male', 'Female', 'Other')),
    experience_level TEXT CHECK (experience_level IN ('Beginner', 'Intermediate', 'Expert')),
    primary_goal TEXT, -- e.g. 'Build Muscle', 'Lose Weight', 'Improve Endurance', 'Maintain'
    health_concerns TEXT[] DEFAULT '{}',
    other_health_concern TEXT,
    body_type TEXT DEFAULT 'Average',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_own" ON public.profiles
    FOR DELETE TO authenticated
    USING (auth.uid() = id);


-- ------------------------------------------------------------------------------
-- 2. HABITS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    time_of_day TEXT NOT NULL CHECK (time_of_day IN ('Morning', 'Afternoon', 'Evening')),
    category TEXT NOT NULL DEFAULT 'Routine' CHECK (category IN ('Routine', 'Workout', 'Nutrition', 'Habits')),
    scheduled_time TEXT, -- e.g. '7:30 AM'
    subtitle TEXT, -- e.g. '3,000 steps', '5g monohydrate'
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    streak_days INT NOT NULL DEFAULT 0,
    scheduled_hour INT CHECK (scheduled_hour >= 0 AND scheduled_hour <= 23),
    scheduled_minute INT CHECK (scheduled_minute >= 0 AND scheduled_minute <= 59),
    reminder_minutes_before INT CHECK (reminder_minutes_before IN (5, 10)),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON public.habits(user_id);
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habits_all_own" ON public.habits
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 2b. HABIT LOGS TABLE (Daily Habit Completion Records)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(habit_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_logs_user_date ON public.habit_logs(user_id, log_date);
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habit_logs_all_own" ON public.habit_logs
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);



-- ------------------------------------------------------------------------------
-- 3. FOOD ITEMS TABLE (Master Food Library / Custom User Foods)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.food_items (
    id TEXT PRIMARY KEY, -- e.g. 'f_k1' or UUID string for custom foods
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for public global foods, set for custom user foods
    name TEXT NOT NULL,
    cuisine TEXT NOT NULL, -- 'Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese'
    base_serving TEXT NOT NULL, -- e.g. '100g', '1 piece (80g)'
    base_serving_grams NUMERIC(6,2) NOT NULL DEFAULT 100.0,
    calories NUMERIC(6,2) NOT NULL DEFAULT 0,
    protein_grams NUMERIC(6,2) NOT NULL DEFAULT 0,
    carbs_grams NUMERIC(6,2) NOT NULL DEFAULT 0,
    fat_grams NUMERIC(6,2) NOT NULL DEFAULT 0,
    fiber_grams NUMERIC(6,2) NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT 'Meals',
    dietary_type TEXT NOT NULL DEFAULT 'non-vegetarian' CHECK (dietary_type IN ('vegetarian', 'vegan', 'eggetarian', 'non-vegetarian')),
    image_asset TEXT DEFAULT '',
    photo_author TEXT DEFAULT 'Wikimedia Commons',
    photo_license TEXT DEFAULT 'CC BY-SA 4.0',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

-- Users can read global foods (user_id IS NULL) OR their own custom foods (auth.uid() = user_id)
CREATE POLICY "food_items_select" ON public.food_items
    FOR SELECT TO authenticated
    USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "food_items_modify_own" ON public.food_items
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 4. FOOD LOGS TABLE (User's Daily Logged Meals)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_id TEXT NOT NULL REFERENCES public.food_items(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    cuisine TEXT NOT NULL,
    meal_section TEXT NOT NULL CHECK (meal_section IN ('Breakfast', 'Lunch', 'Snacks', 'Dinner')),
    quantity_grams NUMERIC(6,2) NOT NULL DEFAULT 100.0,
    unit TEXT NOT NULL DEFAULT 'g',
    calories NUMERIC(7,2) NOT NULL,
    protein_grams NUMERIC(6,2) NOT NULL,
    carbs_grams NUMERIC(6,2) NOT NULL,
    fat_grams NUMERIC(6,2) NOT NULL,
    fiber_grams NUMERIC(6,2) NOT NULL,
    logged_time TEXT NOT NULL, -- e.g. '8:30 AM'
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    image_asset TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON public.food_logs(user_id, log_date);
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "food_logs_all_own" ON public.food_logs
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 5. DIET PREFERENCES TABLE (User Dietary Targets & Settings)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diet_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    selected_cuisines TEXT[] NOT NULL DEFAULT ARRAY['Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese'],
    dietary_type TEXT NOT NULL DEFAULT 'non-vegetarian' CHECK (dietary_type IN ('vegetarian', 'vegan', 'eggetarian', 'non-vegetarian')),
    meals_per_day INT NOT NULL DEFAULT 4 CHECK (meals_per_day IN (3, 4, 5)),
    calorie_target INT NOT NULL DEFAULT 2000,
    is_calorie_manually_overridden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diet_preferences_user_id ON public.diet_preferences(user_id);
ALTER TABLE public.diet_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "diet_preferences_all_own" ON public.diet_preferences
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 6. WEEKLY DIET PLANS TABLE (Generated 7-day Planned Meals)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.weekly_diet_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_name TEXT NOT NULL CHECK (day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    short_name TEXT NOT NULL CHECK (short_name IN ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')),
    day_index INT NOT NULL CHECK (day_index >= 0 AND day_index <= 6), -- 0=Monday, 6=Sunday
    date_num INT,
    food_id TEXT NOT NULL REFERENCES public.food_items(id) ON DELETE RESTRICT,
    meal_name TEXT NOT NULL,
    cuisine TEXT NOT NULL,
    meal_section TEXT NOT NULL CHECK (meal_section IN ('Breakfast', 'Lunch', 'Snack', 'Dinner')),
    calories NUMERIC(6,2) NOT NULL,
    protein_grams NUMERIC(6,2) NOT NULL,
    carbs_grams NUMERIC(6,2) NOT NULL,
    fat_grams NUMERIC(6,2) NOT NULL,
    serving_description TEXT NOT NULL,
    image_asset TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weekly_diet_plans_user_day ON public.weekly_diet_plans(user_id, day_index);
ALTER TABLE public.weekly_diet_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weekly_diet_plans_all_own" ON public.weekly_diet_plans
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 7. EXERCISES TABLE (Master Exercise Library / Custom Exercises)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exercises (
    id TEXT PRIMARY KEY, -- e.g. 'ex_1' or UUID string for custom exercises
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for public global library, set for custom user exercises
    name TEXT NOT NULL,
    muscle_group TEXT NOT NULL CHECK (muscle_group IN ('Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio')),
    default_sets INT NOT NULL DEFAULT 3,
    default_reps INT NOT NULL DEFAULT 10,
    default_weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0.0,
    avoid_if TEXT[] DEFAULT '{}', -- e.g. ARRAY['joint_issues', 'back_pain', 'knee_pain']
    image_url TEXT,
    is_home BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- Users can read global exercises (user_id IS NULL) OR their own custom exercises (auth.uid() = user_id)
CREATE POLICY "exercises_select" ON public.exercises
    FOR SELECT TO authenticated
    USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "exercises_modify_own" ON public.exercises
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 8. WORKOUT LOGS TABLE (User Workout Sessions & Logged Exercises)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    sets INT NOT NULL DEFAULT 3,
    reps INT NOT NULL DEFAULT 10,
    weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0.0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    image_url TEXT,
    workout_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_logs_user_date ON public.workout_logs(user_id, workout_date);
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_logs_all_own" ON public.workout_logs
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 9. WEEKLY WORKOUT PLANS TABLE (7-Day Split Schedule per User)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.weekly_workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_name TEXT NOT NULL CHECK (day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    short_name TEXT NOT NULL CHECK (short_name IN ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')),
    day_index INT NOT NULL CHECK (day_index >= 0 AND day_index <= 6), -- 0=Monday, 6=Sunday
    date_num INT,
    focus_title TEXT NOT NULL, -- e.g. 'Push Day (Chest & Triceps)', 'Rest & Recovery'
    subtitle TEXT NOT NULL, -- e.g. '4 exercises • 50m • Volume 8,420 kg'
    is_rest_day BOOLEAN NOT NULL DEFAULT FALSE,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, day_index)
);

CREATE INDEX IF NOT EXISTS idx_weekly_workout_plans_user ON public.weekly_workout_plans(user_id);
ALTER TABLE public.weekly_workout_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weekly_workout_plans_all_own" ON public.weekly_workout_plans
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 10. DAILY TELEMETRY TABLE (Daily Steps and Completion Rollups)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_telemetry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    step_count INT NOT NULL DEFAULT 0,
    habits_completed INT NOT NULL DEFAULT 0,
    habits_total INT NOT NULL DEFAULT 0,
    exercises_completed INT NOT NULL DEFAULT 0,
    exercises_total INT NOT NULL DEFAULT 0,
    calories_consumed NUMERIC(7,2) NOT NULL DEFAULT 0.0,
    calorie_target INT NOT NULL DEFAULT 2000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_telemetry_user_date ON public.daily_telemetry(user_id, log_date);
ALTER TABLE public.daily_telemetry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_telemetry_all_own" ON public.daily_telemetry
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- End of FitStack Schema
-- ==============================================================================
