# Day 2 Manual Test Checklist

## Goal
Validate Hive lifecycle hardening after introducing `StorageService`.

## Preconditions
- Build runs with no compile errors.
- User can sign in with Google.
- Device has internet for backup test path.

## Test Cases

1. Fresh Launch -> Login -> Dashboard
- Open app from cold start.
- Expected: splash/login flow completes, dashboard opens without box errors.

2. Create Core Records
- Add one client.
- Add one case linked to that client.
- Add one task.
- Expected: records are visible immediately in their modules.

3. Sign Out -> Sign In
- Sign out from dashboard menu.
- Sign in again.
- Expected: app navigates cleanly; no "box closed"/Hive exceptions.

4. Backup Button Flow
- Trigger backup from dashboard app bar.
- Verify both paths:
  - auth success path (backup success snackbar)
  - auth failure path (error snackbar, retry action)
- Expected: no crashes and no navigation glitches.

5. Relaunch Smoke Test
- Force close app.
- Relaunch.
- Open dashboard, clients, and cases screens.
- Expected: screens load without Hive open/close errors.

6. Clear Data Flow
- Open profile -> Clear All Data.
- Confirm destructive action.
- Expected: app returns to login; no stale profile/core records shown after relaunch.

## Pass Criteria
- No uncaught exceptions in logs for box lifecycle.
- No user-visible crashes during all test cases.
- Core modules remain usable after sign-in/sign-out/relaunch/clear-data.
