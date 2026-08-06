# Design Token Map
## Future Times Events — Web → Flutter Mapping

All values extracted from `app/globals.css` and `tailwind.config.ts`.

---

## Colors

### Primary Brand

| Token | Hex | Flutter Usage |
|-------|-----|--------------|
| `--accent` | `#7222E3` | `AppColors.violet` (primary) |
| `--accent-light` | `#9B5EFF` | `AppColors.violetLight` |
| brand.pink | `#FF55C2` | `AppColors.pink` |
| brand.cyan | `#2CC4EA` | `AppColors.cyan` |
| brand.purple | `#533885` | `AppColors.purple` |
| brand.orange | `#FFBC73` | `AppColors.orange` |
| brand.magenta | `#FF00B9` | `AppColors.magenta` |
| brand.mint | `#46FFAB` | `AppColors.mint` |
| brand.grape | `#A02EFF` | `AppColors.grape` |
| brand.blue | `#1D5BFF` | `AppColors.blue` |
| brand.lime | `#C7FE17` | `AppColors.lime` |
| brand.fuchsia | `#DD1FFF` | `AppColors.fuchsia` |
| brand.sky | `#24D8FB` | `AppColors.sky` |

### Light Mode Surface Palette

| CSS Token | Value | Flutter Token |
|-----------|-------|--------------|
| `--bg` | `#ffffff` | `AppColors.background` |
| `--bg-secondary` | `#f7f7fa` | `AppColors.backgroundSecondary` |
| `--bg-tertiary` | `#efeff5` | `AppColors.backgroundTertiary` |
| `--bg-card` | `rgba(255,255,255,0.92)` | `AppColors.card` |
| `--bg-glass` | `rgba(255,255,255,0.78)` | `AppColors.glass` |

### Text Colors

| CSS Token | Value | Flutter Token |
|-----------|-------|--------------|
| `--text` | `#0a0a14` | `AppColors.text` |
| `--text-secondary` | `#38384e` | `AppColors.textSecondary` |
| `--text-muted` | `#78788c` | `AppColors.textMuted` |

### Border Colors

| CSS Token | Value | Flutter Token |
|-----------|-------|--------------|
| `--border` | `rgba(0,0,0,0.07)` | `AppColors.border` |
| `--border-hover` | `rgba(114,34,227,0.3)` | `AppColors.borderHover` |

### Semantic Colors

| Token | Value | Flutter Token |
|-------|-------|--------------|
| `.badge-success` bg | `rgba(70,255,171,0.12)` + `#22c55e` | `AppColors.success` |
| `.badge-warn` bg | `rgba(255,188,115,0.14)` + `#f59e0b` | `AppColors.warning` |
| `.badge-error` bg | `rgba(239,68,68,0.10)` + `#ef4444` | `AppColors.error` |
| `.badge-info` bg | `rgba(44,196,234,0.12)` + `#0ea5e9` | `AppColors.info` |

---

## Gradients

| CSS Token | Direction | Colors | Flutter Gradient |
|-----------|-----------|--------|-----------------|
| `--grad-primary` | 135° | `#FF55C2` → `#7222E3` | `AppGradients.primary` |
| `--grad-ocean` | 135° | `#2CC4EA` → `#533885` | `AppGradients.ocean` |
| `--grad-emerald` | 135° | `#46FFAB` → `#A02EFF` | `AppGradients.emerald` |
| `--grad-fire` | 135° | `#FFBC73` → `#FF00B9` | `AppGradients.fire` |
| `--grad-electric` | 135° | `#1D5BFF` → `#C7FE17` | `AppGradients.electric` |
| `--grad-cosmic` | 135° | `#DD1FFF` → `#24D8FB` | `AppGradients.cosmic` |

---

## Typography

### Font Families

| Role | Font | Weight | Flutter |
|------|------|--------|---------|
| Body / UI | Inter | 400 | `AppTypography.fontBody` |
| Headings (H1) | Space Grotesk | 700 | `AppTypography.fontDisplay` |
| Sub-headings (H2, H3) | Raleway | 600 | `AppTypography.fontSub` |

### Scale

| Level | Size (mobile) | Size (desktop) | Weight | Flutter Style |
|-------|--------------|----------------|--------|--------------|
| H1 | 32px | 45px | 700 | `AppTypography.h1` |
| H2 | 22px | 28px | 600 | `AppTypography.h2` |
| H3 | 20px | 24px | 600 | `AppTypography.h3` |
| H4 | 16px | 18px | 600 | `AppTypography.h4` |
| Body | 16px | 17px | 400 | `AppTypography.body` |
| Caption | 14px | 16px | 500 | `AppTypography.caption` |
| Small | 14px | 14px | 400 | `AppTypography.small` |
| Overline | 11px | 11px | 700 | `AppTypography.overline` |

### Letter Spacing

| Token | Value |
|-------|-------|
| Heading | -0.01em |
| Sub | -0.005em |
| Button | 0.02em |
| Overline | 0.12em |

---

## Spacing (8px grid)

| Token | Value | Flutter Name |
|-------|-------|-------------|
| `--sp-1` | 4px | `AppSpacing.xs` |
| `--sp-2` | 8px | `AppSpacing.sm` |
| `--sp-3` | 16px | `AppSpacing.md` |
| `--sp-4` | 24px | `AppSpacing.lg` |
| `--sp-5` | 32px | `AppSpacing.xl` |
| `--sp-6` | 48px | `AppSpacing.xxl` |
| `--sp-7` | 64px | `AppSpacing.xxxl` |
| `--sp-8` | 96px | `AppSpacing.huge` |

---

## Border Radius

| Token | Value | Flutter Name |
|-------|-------|-------------|
| `--r-xs` | 6px | `AppRadius.xs` |
| `--r-sm` | 8px | `AppRadius.sm` |
| `--r-md` | 12px | `AppRadius.md` |
| `--r-lg` | 16px | `AppRadius.lg` |
| `--r-xl` | 20px | `AppRadius.xl` |
| `--r-2xl` | 24px | `AppRadius.xxl` |
| `--r-3xl` | 32px | `AppRadius.xxxl` |
| `--r-full` | 9999px | `AppRadius.full` |

---

## Shadows

| Token | Value | Flutter Name |
|-------|-------|-------------|
| `--shadow-xs` | `0 1px 4px rgba(0,0,0,0.04)` | `AppElevation.xs` |
| `--shadow-sm` | `0 2px 8px rgba(0,0,0,0.06)` | `AppElevation.sm` |
| `--shadow` | `0 8px 24px rgba(0,0,0,0.08)` | `AppElevation.md` |
| `--shadow-md` | `0 12px 40px rgba(0,0,0,0.10)` | `AppElevation.lg` |
| `--shadow-lg` | `0 24px 64px rgba(0,0,0,0.12)` | `AppElevation.xl` |
| `--shadow-card` | `0 2px 12px rgba(0,0,0,0.05), 0 1px 3px rgba(0,0,0,0.04)` | `AppElevation.card` |
| `--shadow-hover` | `0 16px 48px rgba(0,0,0,0.11), 0 4px 12px rgba(114,34,227,0.08)` | `AppElevation.hover` |

---

## Motion / Easing

| Token | Value | Flutter Equivalent |
|-------|-------|-------------------|
| `--ease-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | `AppMotion.spring` via `Curves.elasticOut` approx |
| `--ease-out` | `cubic-bezier(0.22, 1, 0.36, 1)` | `Curves.easeOutCubic` |
| `--ease-in-out` | `cubic-bezier(0.65, 0, 0.35, 1)` | `Curves.easeInOutCubic` |

### Duration reference
- Fast micro: 200ms
- Standard: 280ms–320ms  
- Shimmer: 1500ms loop
- Float: 7000ms–10000ms loop
- Marquee: 35000ms loop
