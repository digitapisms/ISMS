# Feature Enforcement System Guide

## Overview
The Feature Enforcement System allows you to restrict access to features based on subscription plans. It automatically checks if a feature is enabled for the current school's plan and shows upgrade prompts when needed.

## Components

### 1. FeatureChecker Service
The core service that checks feature availability and limits.

```dart
final checker = ref.read(featureCheckerProvider);
final result = await checker.checkFeature('bulk_import', currentUsage: 5);

if (result.canUse) {
  // Feature is available and within limits
} else {
  // Feature is disabled or limit reached
  print(result.statusMessage);
}
```

### 2. FeatureGuard Widget
Wraps a widget and only shows it if the feature is enabled.

```dart
FeatureGuard(
  featureKey: 'bulk_import',
  child: BulkImportScreen(),
  fallback: Text('Feature not available'),
)
```

### 3. FeatureProtectedButton
A button that automatically disables and shows upgrade prompt if feature is not available.

```dart
FeatureProtectedButton(
  featureKey: 'bulk_import',
  child: IconButton(
    icon: Icon(Icons.upload),
    onPressed: () => _import(),
  ),
)
```

## Feature Keys

Common feature keys used in the system:
- `student_management` - Basic student management
- `bulk_import` - Bulk student import
- `advanced_reports` - Advanced reporting
- `email_notifications` - Email notifications
- `sms_notifications` - SMS notifications
- `parent_portal` - Parent portal access
- `student_portal` - Student portal access
- `api_access` - API access
- `custom_fields` - Custom fields
- `attendance_tracking` - Attendance tracking
- `gradebook` - Gradebook
- `fee_management` - Fee management
- `transport_management` - Transport management
- `analytics_dashboard` - Analytics dashboard
- `data_export` - Data export

## Usage Examples

### Example 1: Protect a Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => FeatureGuard(
      featureKey: 'bulk_import',
      child: BulkImportScreen(),
    ),
  ),
);
```

### Example 2: Protect a Button
```dart
FeatureProtectedButton(
  featureKey: 'bulk_import',
  child: FilledButton(
    onPressed: () => _import(),
    child: Text('Import Students'),
  ),
)
```

### Example 3: Check Feature with Limits
```dart
final students = await getStudents();
final checker = ref.read(featureCheckerProvider);
final result = await checker.checkFeature(
  'student_management',
  currentUsage: students.length,
);

if (!result.canUse) {
  showDialog(
    context: context,
    builder: (_) => UpgradePromptDialog(
      featureKey: 'student_management',
      currentPlan: school.subscriptionPlan,
    ),
  );
  return;
}
```

### Example 4: Show Usage Information
```dart
final result = await checker.checkFeature(
  'student_management',
  currentUsage: studentCount,
);

Text('${result.currentUsage} / ${result.limit ?? "∞"} students')
```

## Integration Points

### Already Integrated:
1. **Bulk Import** - Protected in StudentListScreen
2. **Bulk Import Screen** - Wrapped with FeatureGuard

### To Integrate:
1. **Student Management Limits** - Check student count before adding
2. **Advanced Reports** - Protect report screens
3. **Email/SMS Notifications** - Protect notification features
4. **Parent/Student Portals** - Protect portal access
5. **API Access** - Check before API calls

## Upgrade Flow

When a feature is restricted:
1. User sees a lock icon or disabled button
2. Clicking shows UpgradePromptDialog
3. Dialog shows available upgrade plans
4. User can contact support or view plans

## Testing

To test feature enforcement:
1. Set a school's subscription plan to 'free' in database
2. Try to access bulk import - should be blocked
3. Set plan to 'basic' - bulk import should work
4. Set student limit to 5 and add 6 students - should show limit message

## Database

Features are managed in:
- `plan_features` - All available features
- `plan_feature_mapping` - Feature-to-plan mappings with limits

Use the Plan Editor in Super Admin Dashboard to configure features.

