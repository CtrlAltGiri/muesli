<p align="center">
  <img src="assets/muesli_app_icon.png" alt="Muesli" width="128" height="128" />
</p>

<h1 align="center">Muesli</h1>

<p align="center">
  <strong>Local-first dictation & meeting transcription for macOS</strong><br>
  100% on-device speech-to-text · Zero cloud costs · Privacy by default
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License" /></a>
  <a href="https://buymeacoffee.com/phequals7"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buymeacoffee&logoColor=white" alt="Buy Me A Coffee" /></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014.2%2B-lightgrey?logo=apple" alt="macOS 14.2+" />
  <img src="https://img.shields.io/badge/Apple%20Silicon-optimized-green" alt="Apple Silicon" />
</p>

---

## What is Muesli?

Muesli is a native macOS app that combines **WisprFlow-style dictation** and **Granola-style meeting transcription** in one lightweight tool. All transcription runs locally on Apple Silicon via [MLX](https://github.com/ml-explore/mlx) — your audio never leaves your device.

### Dictation
Hold your hotkey (or double-tap for hands-free mode) → speak → release → transcribed text is pasted at your cursor. ~0.3 second latency.

### Meeting Transcription
Start a meeting recording → Muesli captures your mic (You) and system audio (Others) simultaneously → chunked transcription happens during the meeting → when you stop, the transcript is ready in seconds, not minutes. Optionally generate structured meeting notes via OpenAI or free OpenRouter models.

---

## Features

- **Local transcription** — Whisper on MLX, running on Apple Silicon GPU. No API keys needed for dictation.
- **Hold-to-talk & hands-free** — Hold hotkey for quick dictation, or double-tap for sustained recording.
- **Meeting recording** — Captures mic + system audio (including Bluetooth/AirPods) via ScreenCaptureKit.
- **Chunked meeting transcription** — Mic audio transcribed in 30-second chunks during the meeting. Only system audio needs processing at the end.
- **Silence detection** — Skips silent chunks to prevent Whisper hallucinations.
- **AI meeting notes** — BYOK (Bring Your Own Key) with OpenAI or OpenRouter. Auto-generated meeting titles. Re-summarize any meeting.
- **Personal dictionary** — Add custom words and replacement pairs. Phonetic fuzzy matching (Metaphone + Jaro-Winkler) auto-corrects Whisper output.
- **Meeting auto-detection** — Detects when Zoom, Chrome, Teams, FaceTime, or Slack activates the mic. Shows a notification to start recording.
- **Configurable hotkeys** — Choose any modifier key (Cmd, Option, Ctrl, Fn, Shift) for dictation.
- **Dark & light mode** — Adaptive theme with toggle in Settings.
- **SwiftUI dashboard** — Dictation history, meeting notes (Notes-style split view), dictionary, shortcuts, settings, about page.
- **Floating indicator** — Draggable pill showing recording state, waveform animation, click-to-stop for meetings.

---

## Install

### Download (recommended)

Download the latest `.dmg` from [Releases](https://github.com/pHequals7/muesli/releases), open it, and drag Muesli to your Applications folder.

### Build from source

**Requirements:** macOS 14.2+, Xcode 16+, Python 3.13+ with venv

```bash
# Clone
git clone https://github.com/pHequals7/muesli.git
cd muesli

# Set up Python backend
python3 -m venv .venv
.venv/bin/pip install mlx-whisper jellyfish

# Build and install
./scripts/build_native_app.sh
```

The Whisper model (~460MB) downloads automatically on first launch.

---

## Permissions

Muesli needs these macOS permissions (prompted on first use):

| Permission | Why |
|---|---|
| **Microphone** | Record audio for dictation and meetings |
| **System Audio Recording** | Capture call audio from Zoom/Meet/Teams |
| **Accessibility** | Simulate Cmd+V to paste transcribed text |
| **Input Monitoring** | Detect hotkey presses globally |
| **Calendar** *(optional)* | Auto-detect upcoming meetings |

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Swift / SwiftUI App (native macOS)              │
│  ├── HotkeyMonitor (hotkey detection)            │
│  ├── MicrophoneRecorder (AVAudioRecorder)        │
│  ├── SystemAudioRecorder (ScreenCaptureKit)      │
│  ├── MeetingSession (chunked transcription)      │
│  ├── MeetingSummaryClient (OpenAI / OpenRouter)   │
│  ├── FloatingIndicatorController (UI pill)       │
│  └── SwiftUI Dashboard (dictations, meetings,    │
│       dictionary, shortcuts, settings, about)    │
│                                                  │
│  Python Worker (bridge/worker.py via subprocess)  │
│  ├── mlx-whisper (Apple's Whisper on MLX)        │
│  ├── Silence detection (RMS energy threshold)    │
│  └── Custom word correction (jellyfish)          │
└──────────────────────────────────────────────────┘
```

The Swift app handles UI, hotkeys, audio capture, and paste. The Python subprocess handles ML inference via Apple's optimized [mlx-whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper). Communication is JSON over stdin/stdout.

---

## Tech Stack

| Component | Technology |
|---|---|
| App shell | Swift, AppKit, SwiftUI |
| Transcription | [mlx-whisper](https://github.com/ml-explore/mlx-examples) (Apple MLX) |
| System audio | ScreenCaptureKit (`SCStream`) |
| Meeting notes | OpenAI / OpenRouter (BYOK) |
| Word correction | [jellyfish](https://github.com/jamesturk/jellyfish) (Metaphone + Jaro-Winkler) |
| Storage | SQLite (WAL mode) |
| IPC | JSON over stdin/stdout |

---

## Contributing

Contributions welcome! To get started:

```bash
git clone https://github.com/pHequals7/muesli.git
cd muesli
python3 -m venv .venv
.venv/bin/pip install mlx-whisper jellyfish
swift build --package-path native/MuesliNative -c release
swift test --package-path native/MuesliNative
```

Please open an issue before submitting large PRs.

---

## Support

If Muesli saves you time, consider supporting development:

<a href="https://buymeacoffee.com/phequals7"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=for-the-badge&logo=buymeacoffee&logoColor=white" alt="Buy Me A Coffee" /></a>

---

## Acknowledgements

- [MLX](https://github.com/ml-explore/mlx) by Apple — on-device ML framework for Apple Silicon
- [mlx-whisper](https://github.com/ml-explore/mlx-examples) by Apple — optimized Whisper implementation
- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit) by Apple — system audio capture
- [jellyfish](https://github.com/jamesturk/jellyfish) — phonetic string matching

---

## License

[MIT](LICENSE) — free and open source.
