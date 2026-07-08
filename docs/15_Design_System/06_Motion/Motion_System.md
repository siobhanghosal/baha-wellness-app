# Motion System

## Motion Principles

- Prioritize orientation over delight.
- Never gamify crisis, consent, or distress-related moments.
- Keep student motion gentle and low amplitude.
- Use denser but quieter motion in BAHA operations to preserve throughput.
- Respect reduced-motion settings by removing non-essential transforms and shimmer.

## Animation Library

| Token | Duration | Curve | Usage |
|---|---:|---|---|
| `motion.instant` | 0 | linear | Reduced motion and state snap |
| `motion.fast` | 120ms | emphasized decelerate | Button and chip feedback |
| `motion.base` | 200ms | standard | Card reveal and tab changes |
| `motion.slow` | 280ms | emphasized | Page transitions and sheets |
| `motion.breathe` | 1600ms | ease in out | Calm breathing pulses only |

## Transition Library

| Transition | Use |
|---|---|
| Fade | Splash, settings, low-context changes |
| Shared axis X | Check-in and learning sequence steps |
| Shared axis Y | Support and case detail movement |
| Shared axis Z | Game depth and immersive entry |
| Fade through | Dashboard or list-to-peer route changes |

## Page Transitions

- Bootstrap routes use fade.
- Onboarding and wizard routes use directional slide or shared-axis X.
- Operational detail and workflow routes use shared-axis Y when moving between list and detail.

## Shared Element Transitions

- Card-to-detail transitions may animate media thumbnails, titles, and status chips when layout continuity is clear.
- Do not use shared elements for high-risk alert changes or private identifiers.

## Modal Animations

- Dialogs fade and scale slightly from 0.96 to 1.00 over `motion.base`.
- Session-expired or destructive dialogs skip bounce or spring effects.

## Bottom Sheet Animations

- Sheets rise from the bottom over `motion.slow`.
- Gesture dismissal must track the finger and respect velocity thresholds.

## FAB Animations

- FAB is reserved and should use standard Material motion if ever enabled.

## Loading Animations

- Use subtle skeleton shimmer only when reduced motion is off.
- Progress loops longer than 3 seconds require text status.

## Gesture Animations

- Pull-to-refresh preserves filter state and scroll anchor.
- Swipe back should reveal the prior route predictably and not conflict with horizontal chips or tabs.
