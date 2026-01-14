# Widget Setup Instructions

The iOS widget implementation is complete! However, the Xcode project needs to be configured through Xcode's UI to properly set up the widget extension target. Follow these steps:

## Files Created

### Core Files
- ✅ `MyMacroPal/SharedConfig.swift` - Shared configuration for App Group
- ✅ `MyMacroPal/MyMacroPal.entitlements` - App entitlements with App Group
- ✅ `MyMacroPalWidgetExtension/MyMacroPalWidget.swift` - Widget implementation
- ✅ `MyMacroPalWidgetExtension/MyMacroPalWidgetBundle.swift` - Widget bundle
- ✅ `MyMacroPalWidgetExtension/MyMacroPalWidgetExtension.entitlements` - Widget entitlements

### Code Updates
- ✅ Updated `PersistenceController.swift` to use shared App Group container
- ✅ Updated `SettingsView.swift` to use shared UserDefaults
- ✅ Updated `HomeView.swift` to use shared UserDefaults
- ✅ Updated `HistoryView.swift` to use shared UserDefaults

## Xcode Configuration Steps

### 1. Configure App Group

1. Open the project in Xcode
2. Select the **MyMacroPal** project in the navigator
3. Select the **MyMacroPal** target
4. Go to the **Signing & Capabilities** tab
5. Click **+ Capability** and add **App Groups**
6. Check/Add the app group: `group.AVIDWareAthletics.MyMacroPal`

### 2. Add Widget Extension Target (if not already added)

If the widget extension target doesn't exist or isn't properly configured:

1. In Xcode, go to **File > New > Target**
2. Select **Widget Extension**
3. Name it: `MyMacroPalWidgetExtension`
4. Uncheck "Include Configuration Intent" (we don't need it)
5. Click **Finish**
6. When prompted to activate the scheme, click **Activate**

### 3. Configure Widget Target

1. Select the **MyMacroPalWidgetExtension** target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Check/Add: `group.AVIDWareAthletics.MyMacroPal`
5. Set **Code Signing Entitlements** to: `MyMacroPalWidgetExtension/MyMacroPalWidgetExtension.entitlements`

### 4. Add Files to Widget Target

The widget needs access to certain files from the main app:

1. In the Project Navigator, select these files and ensure they're included in the **MyMacroPalWidgetExtension** target:
   - `MyMacroPal/SharedConfig.swift`
   - `MyMacroPal/Models.swift` (for the extension methods)
   - `MyMacroPal/Micronutrients.swift` (for MicronutrientData)
   - `MyMacroPal/MyMacroPal.xcdatamodeld` (Core Data model)

2. To do this:
   - Click on each file in the Project Navigator
   - In the **File Inspector** (right panel), check the box next to **MyMacroPalWidgetExtension** under "Target Membership"

### 5. Configure Main App Target Entitlements

1. Select the **MyMacroPal** target
2. Go to **Build Settings**
3. Search for "Code Signing Entitlements"
4. Set it to: `MyMacroPal/MyMacroPal.entitlements`

### 6. Build and Run

1. Select the **MyMacroPal** scheme
2. Build and run the app (⌘R)
3. Add some food entries and set your goals in Settings
4. On your device/simulator, long-press the home screen
5. Tap the **+** button to add a widget
6. Search for "MyMacroPal" and add the medium-sized widget
7. The widget should display your daily macro progress!

## Testing the Widget

1. **Add food in the app** - The widget should update within an hour (or force-refresh by removing and re-adding)
2. **Change goals in Settings** - The widget will reflect new goals on next update
3. **Test across days** - The widget resets at midnight to show new day's progress

## Troubleshooting

### Widget shows "0/0" for all values
- Ensure App Groups are enabled and match on both targets
- Check that the Core Data model and SharedConfig are included in the widget target
- Try deleting and re-adding the widget

### Build errors about missing symbols
- Verify all required files are added to the widget target membership
- Clean build folder (⌘⇧K) and rebuild

### Widget not updating
- Widgets update on their own schedule (up to hourly)
- iOS may delay updates to save battery
- Force refresh by removing and re-adding the widget

## App Group Details

- **App Group ID**: `group.AVIDWareAthletics.MyMacroPal`
- **Shared UserDefaults**: Stores daily goals (calories, protein, carbs, fat, fiber)
- **Shared Core Data**: Stores food entries in the app group container

## Widget Features

- ✅ 2x2 grid layout with 4 circular progress indicators
- ✅ Calories (top-left, blue)
- ✅ Protein (top-right, green)
- ✅ Carbs (bottom-left, purple)
- ✅ Fat (bottom-right, orange)
- ✅ Shows percentage complete and current value
- ✅ Updates hourly automatically
- ✅ Matches the visual design of similar fitness tracking apps

## Notes

- The widget is read-only and displays data from the main app
- Users must open the main app to add food or change goals
- Widget size is `.systemMedium` (2x2 square grid)
- Refreshes automatically every hour or when iOS allows

