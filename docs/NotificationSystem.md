# LegalSteward Notification System

## Overview
The LegalSteward app uses local scheduled notifications to remind you about upcoming case hearings. This document explains how it works and how to troubleshoot issues on OnePlus/OPPO devices.

---

## How It Works

### When You Save a Case with a Hearing Date

The app automatically schedules **THREE strategic reminders**:

1. **2 Days Before** - at 9:00 AM
2. **1 Day Before** - at 9:00 AM  
3. **Morning Of** - at 8:00 AM

### Example Scenario

If you schedule a hearing for **November 28, 2025 at 2:00 PM**, the notifications will fire:

- ⏰ **November 26 at 9:00 AM** - "2 days before hearing: [Case Title]"
- ⏰ **November 27 at 9:00 AM** - "1 day before hearing: [Case Title]"
- ⏰ **November 28 at 8:00 AM** - "Morning of hearing: [Case Title]"

---

## Technical Details

### Notification IDs
Each case generates **3 unique notification IDs** based on the case UUID:
- `baseId + 1` → 2 days before reminder
- `baseId + 2` → 1 day before reminder
- `baseId + 3` → Morning of reminder

### Automatic Cancellation
When you:
- **Update** a case hearing date → Old reminders are cancelled, new ones scheduled
- **Delete** a hearing date → All reminders are cancelled
- **Delete** the case → All reminders are cancelled

---

## OnePlus/OPPO Device Setup

OnePlus and OPPO devices have **aggressive battery optimization** that can suppress notifications. Follow these steps:

### 1. Enable Exact Alarms Permission
```
Settings → Apps → LegalSteward → Special app access → Alarms & reminders → ✅ Allow
```

### 2. Disable Battery Optimization
```
Settings → Apps → LegalSteward → Battery → Unrestricted
```

### 3. Allow Auto-Start (OxygenOS/ColorOS)
```
Settings → Apps → Startup Manager → LegalSteward → ✅ Enable
```

### 4. Lock App in Recent Apps
- Open Recent Apps (swipe up and hold)
- Find LegalSteward
- Tap the lock icon 🔒

---

## Testing

### Startup Test Notification
When you first launch the app, it schedules a test notification for **tomorrow at 9:00 AM**. You'll also see an instant notification confirming the app started successfully.

### Checking Pending Notifications
Look at the console logs (or use the diagnostic feature) to see:
- ✅ Whether notifications are enabled
- ✅ Whether exact alarm permission is granted
- 📋 List of all pending scheduled notifications

### Example Log Output
```
[NotificationService] 📅 Scheduling id=123456
[NotificationService]    Now:    2025-11-23 13:00:00+0530
[NotificationService]    Target: 2025-11-25 09:00:00+0530
[NotificationService]    Delay:  172800s (2880m)
[NotificationService]    TZ:     Asia/Kolkata
[NotificationService] ✅ Scheduled successfully! Pending count=3
```

---

## Troubleshooting

### ❌ Notifications Not Firing

**Symptom**: Notifications show as "scheduled" but never appear.

**Solutions**:
1. Check all permissions above (especially "Alarms & reminders")
2. Make sure battery optimization is **Unrestricted**
3. Reboot the device after changing settings
4. Add app to startup manager/auto-start list

### ⚠️ "Exact Alarm Permission: UNKNOWN"

**Symptom**: Diagnostic shows null/unknown for exact alarm permission.

**Cause**: Your Android version might not fully support the exact alarm API.

**Solution**: Notifications will fall back to "inexact" scheduling (may fire a few minutes late, but should still work).

### 🔋 App Killed in Background

**Symptom**: App doesn't run in background.

**OnePlus/OPPO Specific**:
- Go to **Battery Optimization** → Select app → Choose **Don't optimize**
- Lock the app in **Recent Apps** tray
- Add to **Auto-start** list

---

## Code Integration

### Scheduling a Reminder (Automatic)
```dart
// This happens automatically when you save a case
await NotificationService.scheduleCaseHearingReminder(caseModel);
```

### Cancelling a Reminder (Automatic)
```dart
// This happens automatically when you remove a hearing date
await NotificationService.cancelCaseHearingReminder(caseModel);
```

### Manual Scheduling (Advanced)
```dart
// Schedule a custom one-off notification
await NotificationService.scheduleOneOff(
  id: 12345,
  title: 'My Custom Reminder',
  body: 'This is a custom notification',
  when: DateTime(2025, 11, 30, 9, 0), // Nov 30 at 9 AM
);
```

---

## Future Enhancements

Potential improvements for the notification system:

- [ ] User preference for reminder times (e.g., 9 AM vs 10 AM)
- [ ] Configurable lead times (2 days, 1 day, etc.)
- [ ] Option to enable/disable individual reminder slots
- [ ] Notification sound customization
- [ ] Recurring reminders for regular hearings
- [ ] In-app notification history/log viewer

---

## Technical Stack

- **Package**: `flutter_local_notifications` ^19.5.0
- **Timezone**: `timezone` ^0.10.0 with heuristic IST mapping
- **Platform**: Android (iOS support can be added)
- **Scheduling Mode**: `AndroidScheduleMode.exactAllowWhileIdle`
- **Channels**: 
  - `immediate_channel` - Instant notifications
  - `scheduled_channel` - Scheduled reminders

---

## Support

If you continue to experience issues with notifications on OnePlus/OPPO devices, it's often a manufacturer-imposed limitation. Consider:

1. Checking device-specific forums for your model
2. Updating to the latest OxygenOS/ColorOS version
3. Using a third-party reminder app as a backup

**Note**: Some OnePlus/OPPO devices have firmware bugs that prevent apps from scheduling exact alarms, even with all permissions granted. This is beyond the app's control.
