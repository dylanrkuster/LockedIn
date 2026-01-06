# Launch Marketing Screenshot Mode

Launch the app in marketing screenshot capture mode on iPhone 14 Plus simulator.

## Steps

1. **Enable screenshot mode** in `LockedIn/LockedIn/LockedInApp.swift`:
   - Set `marketingScreenshotMode = true`

2. **Boot iPhone 14 Plus simulator** (6.7" display for App Store)

3. **Build the app** for iPhone 14 Plus

4. **Install and launch** the app on the simulator

5. **Inform the user** how to capture:
   - Tap screen to show navigation (auto-hides after 3s)
   - Use Prev/Next to navigate between 5 screenshots
   - Press Cmd+S in Simulator to save each screenshot
   - Run `/screenshots-cleanup` when done

## Important

- Do NOT commit the temporary change to `marketingScreenshotMode`
- The screenshots are defined in `LockedIn/MarketingScreenshots.swift`
- Status bar is hidden automatically in screenshot mode
