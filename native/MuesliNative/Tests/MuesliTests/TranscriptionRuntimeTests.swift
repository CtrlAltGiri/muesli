import Testing
import Foundation
import MuesliCore
@testable import MuesliNativeApp

@Suite("SpeechSegment")
struct SpeechSegmentTests {

    @Test("stores start, end, text")
    func basicConstruction() {
        let segment = SpeechSegment(start: 1.5, end: 3.0, text: "Hello world")
        #expect(segment.start == 1.5)
        #expect(segment.end == 3.0)
        #expect(segment.text == "Hello world")
    }
}

@Suite("SpeechTranscriptionResult")
struct SpeechTranscriptionResultTests {

    @Test("stores text and segments")
    func basicConstruction() {
        let result = SpeechTranscriptionResult(
            text: "Full text",
            segments: [
                SpeechSegment(start: 0, end: 1, text: "Full"),
                SpeechSegment(start: 1, end: 2, text: "text"),
            ]
        )
        #expect(result.text == "Full text")
        #expect(result.segments.count == 2)
    }

    @Test("empty result")
    func emptyResult() {
        let result = SpeechTranscriptionResult(text: "", segments: [])
        #expect(result.text.isEmpty)
        #expect(result.segments.isEmpty)
    }
}

@Suite("TranscriptionCoordinator routing")
struct TranscriptionCoordinatorTests {

    @Test("coordinator initializes without crash")
    func initDoesNotCrash() {
        let _ = TranscriptionCoordinator()
    }

    @Test("backend routing covers all known backends")
    func allBackendsCovered() {
        let backends = Set(BackendOption.all.map(\.backend))
        let expected: Set<String> = ["fluidaudio", "whisper", "qwen", "nemotron"]
        #expect(backends == expected, "BackendOption.all backends should match expected set")
    }
}

@Suite("TranscriptionCoordinator.removeArtifacts")
struct RemoveArtifactsTests {

    @Test("clears result when entire text is a known artifact")
    func blankAudioArtifact() {
        let input = SpeechTranscriptionResult(
            text: "[blank_audio]",
            segments: [SpeechSegment(start: 0, end: 1, text: "[blank_audio]")]
        )
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text.isEmpty)
        #expect(output.segments.isEmpty)
    }

    @Test("artifact matching is case-insensitive")
    func caseInsensitive() {
        let input = SpeechTranscriptionResult(text: "[BLANK_AUDIO]", segments: [])
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text.isEmpty)
    }

    @Test("artifact matching trims surrounding whitespace")
    func trailingWhitespace() {
        let input = SpeechTranscriptionResult(text: "  [blank_audio]  \n", segments: [])
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text.isEmpty)
    }

    @Test("passes through normal transcription unchanged")
    func normalTextUnchanged() {
        let input = SpeechTranscriptionResult(
            text: "Hello world",
            segments: [SpeechSegment(start: 0, end: 1, text: "Hello world")]
        )
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text == "Hello world")
        #expect(output.segments.count == 1)
    }

    @Test("passes through empty text unchanged")
    func emptyTextUnchanged() {
        let input = SpeechTranscriptionResult(text: "", segments: [])
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text.isEmpty)
    }

    @Test("does not strip artifact when it appears mid-sentence")
    func midSentenceNotStripped() {
        let input = SpeechTranscriptionResult(text: "Hello [blank_audio] world", segments: [])
        let output = TranscriptionCoordinator.removeArtifacts(input)
        #expect(output.text == "Hello [blank_audio] world")
    }
}
