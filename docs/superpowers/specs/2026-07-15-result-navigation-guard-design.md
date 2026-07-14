# Result Navigation Guard Design

## Goal

Prevent double taps and cross-action taps on the result screen from creating duplicate retry/menu routes.

## Behavior

- The first Retry or Main Menu tap atomically commits navigation.
- Both navigation buttons become disabled in the same frame.
- Later taps are ignored even if the callback itself is synchronous or route animation is still running.
- Feedback and JSON actions keep their existing independent guards.

## Verification

- Retry double tap calls Retry once.
- Menu double tap calls Menu once.
- Retry then Menu, and Menu then Retry, call only the first selected action.

