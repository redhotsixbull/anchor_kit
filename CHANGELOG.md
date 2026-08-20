## 0.1.1

- **Docs:** denser, mobile-sized screenshots (430×820) so the README images
  read clearly instead of tall, mostly-empty frames. No code changes.

## 0.1.0

- **New:** `FloatingOverlay` gains `barrierDismissible` + `onDismiss` — a
  transparent tap-outside-to-close barrier for dropdowns / selects / popovers.
- **Example:** rebuilt into a recipe gallery — placement playground, tooltip,
  dropdown, select (flips up), and a popover-with-arrow card. Deep-linkable via
  `?demo=<id>` on web. Now runs on web too.
- **Docs:** README overhauled with screenshots, concept explanations
  (offset/flip/shift/arrow) and a "Known limitations" section.
- Bundles all `0.0.2` fixes below.

## 0.0.2

- **Fix:** `FloatingOverlay` now follows the anchor when an **ancestor**
  scrolls (previously it only listened to descendant scrolls and silently
  failed to reposition). It also repositions on window resize/rotation and
  re-measures the floating child each frame so size changes stay positioned.
- **Fix:** `Flip` no longer spuriously flips a placement that already fits but
  touches a viewport edge; and when neither side fits it keeps the side that
  overflows least instead of always the original.
- **Fix:** `Shift` keeps the start edge visible when the floating element is
  larger than the viewport (was pinned to the far edge).
- **Fix:** `Arrow` no longer throws when the floating element is too small to
  honour padding — it centres the arrow instead.
- **API:** `Offset4` renamed to `OffsetMiddleware` (old name kept as a
  deprecated alias until v0.1.0).
- Lifecycle: `mounted` guards on overlay open/measurement.
- Docs: added `docs/SPEC.md`; added `FloatingOverlay` widget tests (including
  scroll-follow) and middleware edge-case tests.

## 0.0.1

- Initial scaffold: `computePosition`, `Placement`, middleware (`Offset4`, `Flip`, `Shift`, `Arrow`), `FloatingOverlay` widget.
