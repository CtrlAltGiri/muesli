# Context Handover — Double-Tap Toggle Dictation Mode

**Session Date:** 2026-03-15
**Repository:** muesli
**Branch:** `main`

---

## Task

Add double-tap hotkey detection for hands-free dictation. Currently only hold-to-talk exists (hold key → record → release → transcribe). WisprFlow supports double-tapping the same hotkey to enter sustained recording mode — speak as long as you want, then press the hotkey again (or click the floating indicator) to stop and transcribe.

## Current Implementation

**`HotkeyMonitor.swift`** — already supports configurable `targetKeyCode` (modifier keys). State machine:
- Key down → 150ms → `onPrepare` → 250ms → `onStart` (recording begins)
- Key up → `onStop` (recording ends, transcription starts)
- Another key pressed while held → `onCancel`

**`ShortcutsView.swift`** — already has hotkey configuration UI with key recorder.

**`HotkeyConfig` in `Models.swift`** — has `keyCode` and `label` fields.

## Implementation Plan

### 1. Add double-tap detection to HotkeyMonitor

Track key-up timestamps. If a second key-down happens within 300ms of the previous key-up (and the hold was short, <250ms — i.e., a tap not a hold), enter toggle mode.

```
State machine additions:
- Single tap (down <250ms, up): do nothing (it was too short for hold-to-talk)
- Double tap (second down within 300ms of first up): enter toggleRecording mode
  → call onToggleStart
  → sustained recording begins
  → next key press (any duration) calls onToggleStop
```

Add to HotkeyMonitor:
```swift
var onToggleStart: (() -> Void)?
var onToggleStop: (() -> Void)?
private var lastKeyUpTime: Date?
private var isToggleMode = false
```

### 2. Update MuesliController to handle toggle mode

```swift
hotkeyMonitor.onToggleStart = { [weak self] in self?.handleToggleStart() }
hotkeyMonitor.onToggleStop = { [weak self] in self?.handleToggleStop() }

private func handleToggleStart() {
    // Same as handleStart but without the hold requirement
    micActivityMonitor.suppressWhileActive()
    try recorder.prepare()
    try recorder.start()
    dictationStartedAt = Date()
    setState(.recording)
    indicator.setState(.recording, config: config) // Show "Listening" pill
}

private func handleToggleStop() {
    // Same as handleStop
    handleStop()
}
```

### 3. Update ShortcutsView UI

Add a second section for toggle mode:

```
Push to Talk
Hold to record, release to transcribe          [Left Cmd]
[Change Shortcut]

Hands-Free Mode
Double-tap to start, tap again to stop         [Same key]
Enabled: [toggle]
```

### 4. Add toggle mode preference to AppConfig

```swift
var enableDoubleTapDictation: Bool = true
```

### Key Considerations

- Double-tap window: 300ms between first key-up and second key-down
- First tap must be short (<250ms hold) to distinguish from hold-to-talk
- While in toggle mode, the floating indicator should show "Listening" with a different visual (maybe a pulsing border) to indicate it's sustained
- Clicking the floating indicator during toggle mode should stop recording (already wired via `handleClick`)
- VAD could auto-stop after extended silence (future enhancement)

## Files to Modify

| File | Change |
|---|---|
| `HotkeyMonitor.swift` | Add double-tap detection, `onToggleStart`/`onToggleStop` callbacks |
| `MuesliController.swift` | Add `handleToggleStart()`/`handleToggleStop()` handlers |
| `Models.swift` | Add `enableDoubleTapDictation` to AppConfig |
| `ShortcutsView.swift` | Add hands-free mode section with toggle |
