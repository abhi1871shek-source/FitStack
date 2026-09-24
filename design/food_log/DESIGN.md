---
name: Kinetic Discipline
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#3e4943'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#6e7a73'
  outline-variant: '#bdc9c1'
  surface-tint: '#006c4e'
  primary: '#005d42'
  on-primary: '#ffffff'
  primary-container: '#047857'
  on-primary-container: '#9ffdd3'
  inverse-primary: '#7bd8b1'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#863933'
  on-tertiary: '#ffffff'
  tertiary-container: '#a45049'
  on-tertiary-container: '#ffe4e0'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#97f5cc'
  primary-fixed-dim: '#7bd8b1'
  on-primary-fixed: '#002115'
  on-primary-fixed-variant: '#00513a'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ac'
  on-tertiary-fixed: '#3e0405'
  on-tertiary-fixed-variant: '#792f2a'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  metric-val:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: -0.005em
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-xs:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit-2: 0.125rem
  unit-4: 0.25rem
  unit-8: 0.5rem
  unit-12: 0.75rem
  unit-16: 1rem
  unit-24: 1.5rem
  unit-32: 2rem
  gutter-mobile: 1rem
  gutter-desktop: 1.5rem
  card-padding: 1rem
---

## Brand & Style

This design system embodies disciplined athletic performance through quiet precision. Built for individuals tracking rigorous daily routines, gym progressions, and nutritional intake, the aesthetic rejects the over-gamified, neon-drenched cliches of casual fitness apps in favor of focused utility reminiscent of Swiss horology, high-end athletic telemetry, and minimalist editorial workflows.

### Design Movement: Modern Functional Minimalism
- **Core Principles:** Uncompromising legibility, zero decorative latency, tactical color application, and tactile structural rigor.
- **Tone:** Calibrating, restrained, authoritative, and encouraging without false cheerfulness.
- **Visual Boundaries:** Strictly avoid decorative glassmorphism, multi-stop neon gradients, floating glow effects, or toy-like pill geometries. Interface elements act as low-friction data frames that prioritize metrics, telemetry, and consistent habit reinforcement.

## Colors

The palette operates on high-contrast neutral foundations punctuated by a singular performance green accent. Color is reserved as an active signaling mechanism rather than mere surface decoration.

### Functional Palette
- **Canvas / Base Canvas:** Pure `#FFFFFF` for primary workspace containers and data cards; `#F8F9FA` for overall app background framing and section segmentation.
- **Neutral Stack (Slate / Zinc):**
  - Text Primary: `#111827` (deep near-black for metrics, primary headlines, and active records)
  - Text Secondary: `#374151` (body copy, workout field labels, active tab items)
  - Text Muted: `#6B7280` (metadata, timestamp, unit indicators like "kg", "reps", "kcal")
  - Border Subdued: `#E5E7EB` (clean structural 1px dividers, card perimeters)
  - Surface Subdued: `#F3F4F6` (trackers, unfilled streak slots, disabled controls)
- **Signal Greens (Performance Accent):**
  - Primary Accent (`#047857`): Primary CTA backgrounds, high-contrast badges, complete streaks, and focused states.
  - Vivid Metric Accent (`#10B981`): Dynamic telemetry indicators, active workout timer pulses, ring completions, and streak graphs.
  - Accent Subtle (`#ECFDF5`): Active selection background fill, non-intrusive chip backgrounds, and completed workout tile highlights.
- **Restraint Rule:** Never apply green gradients or dual-color transitions. Green must never exceed 10% of any viewport, preserving its psychological value as a driver for completion and focus.

## Typography

The typography is systematic, neutral, and highly technical, standardizing on **Inter** across all UI layers.

### Hierarchy & Alignment
- **Telemetry & Numbers:** Large numerical readouts (`metric-val`, `display-lg`) leverage tabular numerals (`tnum`) and condensed letter-spacing to prevent jumpy layout shifts during live workout and interval timers.
- **Labels & Microcopy:** `label-xs` is systematically transformed to uppercase with positive letter spacing (`0.04em`) when applied to column headers, macro breakdowns (P / C / F), or exercise target definitions (SETS x REPS).
- **Body Rhythm:** Generous line heights (`1.5` ratio) are retained for habit notes and nutrition details to maintain high scanning clarity during motion.

## Layout & Spacing

A strict 8px incremental spatial scale governs all structural flow, with half-step (4px) units allocated exclusively for internal component alignment (e.g., metric label to value offsets).

### Architecture
- **Mobile First:** Single continuous vertical column pinned to a 390px-to-428px standard width. Viewports retain a `16px` outer horizontal margin on mobile screens, expanding to structured max-width containers (`640px` for workout logs, `1024px` for dashboard analytics) on larger viewports.
- **Density Model:** Information density is compact yet breathable. Component groupings leverage `8px` gaps for tight peer associations (e.g., reps/weight inputs) and `16px` gaps between distinct routine blocks. Section dividers use `24px` to `32px` vertical clearance.

## Elevation & Depth

This design system avoids multi-layered z-plane illusions, opting for a clean, architectural flat model anchored by structural borders and subtle micro-shadows.

### Layer Hierarchy
- **Base Level (Canvas):** Tone `#F8F9FA` establishes ground zero.
- **Container Level (Surface):** Pure `#FFFFFF` surfaces defined by a sharp 1px border (`#E5E7EB`) and an imperceptible micro-shadow (`box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.04)`). No ambient colored halos or directional drop-shadows are permitted.
- **Floating Modals & Sheets:** Floating bottom sheets and active exercise drawers introduce an intentional, controlled scrim (`rgba(17, 24, 39, 0.4)`) coupled with a restrained surface shadow (`box-shadow: 0 4px 16px -2px rgba(17, 24, 39, 0.08)`), preserving clean borders without blur filters.

## Shapes

Corner geometry stays grounded in standard iOS/modern mobile ergonomics, targeting a disciplined 12px to 16px radius across cards and actionable controls.

### Radius Assignments
- **Primary Data Cards & Module Panels:** Standardized at `12px` (mobile viewport) to `16px` (tablet/desktop modal frames).
- **Interactive Controls (Buttons, Inputs):** Set uniformly to `10px` or `12px` to balance internal content without collapsing into full pill shapes.
- **Micro UI (Badges, Status Tags, Habit Dots):** Set to `6px` or explicit circular boundaries (`rounded-full`) exclusively for streak indicators and avatar portraits. Overly bulbous and toy-like corners are explicitly disallowed.

## Components

### Buttons & Action Controls
- **Primary Action:** Solid `#047857` background, pure `#FFFFFF` typography (`label-md`), 12px corner radius, zero border. Height fixed at 48px for reliable touch targets during workouts.
- **Secondary / Ghost Action:** `#FFFFFF` background, 1px solid `#E5E7EB` border, `#111827` text. On pressed state: surface transitions to `#F3F4F6`.
- **Tertiary Utility:** Monoline stroke icon + text, transparent background, text `#374151`, zero border.

### Input Fields & Metric Steppers
- **Gym Log Inputs (Weight / Reps):** Compact boxes featuring centered, high-contrast `metric-val` text, `#F9FAFB` fill, and a crisp 1px `#E5E7EB` border that transitions cleanly to a 1.5px `#047857` border on focus. No glowing focus rings.
- **Standard Text Fields:** 44px height, 12px radius, neutral placeholder text `#9CA3AF`, subtle `#111827` active cursor.

### Cards & Habit Trackers
- **Workout/Nutrition Summary Card:** White `#FFFFFF` card, 12px radius, 1px border `#E5E7EB`. Internal padding of 16px. Top row: exercise or meal name with time or set metadata; Middle row: bold tabular data summary; Bottom row: quiet progress bar with track in `#F3F4F6` and fill in `#047857`.
- **Streak & Habit Nodes:** Monoline 7-day horizontal habit tracker. Incomplete days render as empty circles with 1.5px `#E5E7EB` border; completed days display solid `#047857` with a centered 1.5px white check icon.

### Chips & Filter Tabs
- **Filter Chips:** 32px height, 8px radius. Unselected: transparent background, 1px `#E5E7EB` border, `#374151` text. Selected: `#ECFDF5` background, 1px `#047857` border, `#047857` text. Never uses pill shapes.

### Icons & Imagery
- **Icon Language:** Monoline 1.5px to 2px stroke weight, 20px-to-24px grid bound, straight terminal edges. Filled variations appear solely to designate completed states or active bottom navigation items.