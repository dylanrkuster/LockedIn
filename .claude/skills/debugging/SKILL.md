# Debugging Skill

## Description
Systematic approach to diagnosing and fixing build failures, test failures, crashes, and unexpected behavior.

## Triggers
- Build fails
- Tests fail
- App crashes
- Unexpected behavior reported
- Error messages appear

## Diagnosis Framework

### Step 1: Capture the Error
```bash
# For build errors - get full output
xcodebuild build -scheme LockedIn ... 2>&1 | tee build.log

# For test failures
xcodebuild test -scheme LockedIn ... 2>&1 | tee test.log

# For crash logs
xcrun simctl spawn booted log stream --predicate 'process == "LockedIn"'
```

### Step 2: Classify the Error

| Error Type | Indicators | Approach |
|------------|------------|----------|
| **Compile Error** | "error:", line numbers | Fix syntax/types |
| **Linker Error** | "undefined symbol", "duplicate symbol" | Check imports, targets |
| **Runtime Crash** | EXC_BAD_ACCESS, SIGABRT | Check nil, bounds, threads |
| **Test Failure** | XCTAssert failed | Check logic, test data |
| **UI Issue** | Visual bug, layout broken | Check constraints, state |

### Step 3: Isolate the Cause

**For Compile Errors:**
1. Read the FIRST error (later errors often cascade)
2. Go to exact file:line mentioned
3. Check: typos, missing imports, type mismatches

**For Runtime Crashes:**
1. Get stack trace
2. Find the last frame in YOUR code (not Apple frameworks)
3. Check: nil unwrapping, array bounds, thread safety

**For Test Failures:**
1. Read the assertion message
2. Compare expected vs actual
3. Check: test data setup, async timing, state pollution

**For UI Issues:**
1. Take screenshot of broken state
2. Compare to expected design
3. Check: constraints, state bindings, conditional rendering

### Step 4: Form Hypothesis
Before fixing, state clearly:
- "I believe the error is caused by X"
- "This is because Y"
- "I will fix it by doing Z"

### Step 5: Fix and Verify
1. Make the minimal fix
2. Rebuild/retest
3. If still failing, return to Step 2
4. If fixed, check for similar issues elsewhere

---

## Common iOS/Swift Issues

### Nil Unwrapping
```swift
// CRASH: Fatal error: Unexpectedly found nil
let name = user.name!  // Don't force unwrap

// FIX: Use optional binding
if let name = user.name {
    // use name
}
```

### Retain Cycles
```swift
// LEAK: Self is captured strongly
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.updateUI()  // Strong capture
}

// FIX: Use weak self
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateUI()
}
```

### Main Thread Violations
```swift
// CRASH: UI updated from background thread
DispatchQueue.global().async {
    self.label.text = "Updated"  // Wrong!
}

// FIX: Dispatch to main
DispatchQueue.global().async {
    DispatchQueue.main.async {
        self.label.text = "Updated"
    }
}
```

### SwiftUI State Issues
```swift
// BUG: View not updating
class ViewModel {  // Missing ObservableObject
    var items: [Item] = []
}

// FIX: Make observable
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

### Async/Await Pitfalls
```swift
// BUG: Forgot to await
func loadData() {
    fetchItems()  // Returns immediately, data not loaded
}

// FIX: Await the result
func loadData() async {
    items = await fetchItems()
}
```

### HealthKit Authorization
```swift
// BUG: Not checking authorization status
func readWorkouts() {
    // Fails silently if not authorized
}

// FIX: Check and request authorization
func readWorkouts() async throws {
    let status = healthStore.authorizationStatus(for: HKWorkoutType.workoutType())
    guard status == .sharingAuthorized else {
        try await healthStore.requestAuthorization(toShare: [], read: [HKWorkoutType.workoutType()])
        return
    }
    // Now safe to read
}
```

### FamilyControls Authorization
```swift
// BUG: Not handling authorization failure
func setupBlocking() {
    // Crashes or fails silently without proper auth
}

// FIX: Request and verify authorization
func setupBlocking() async throws {
    let center = AuthorizationCenter.shared
    try await center.requestAuthorization(for: .individual)
    // Now can use ManagedSettings
}
```

---

## Build Error Quick Reference

| Error Message | Likely Cause | Fix |
|---------------|--------------|-----|
| "Cannot find 'X' in scope" | Missing import or typo | Add import or fix spelling |
| "Type 'X' has no member 'Y'" | Wrong type or outdated API | Check type, update API usage |
| "Cannot convert value of type" | Type mismatch | Add conversion or fix types |
| "Missing argument for parameter" | API changed or wrong call | Check function signature |
| "Circular reference" | A imports B, B imports A | Restructure dependencies |
| "Missing required entitlement" | FamilyControls not set up | Add capability in Xcode |

---

## When to Escalate

If after 3 attempts the issue isn't resolved:
1. Document what was tried
2. Capture all error output
3. Ask user for guidance
4. Consider if the approach needs rethinking

---

## Prevention

After fixing a bug, consider:
1. Can I add a test to prevent regression?
2. Is this pattern used elsewhere? Fix those too.
3. Should I add a comment explaining the fix?
4. Is there a linter rule that could catch this?
