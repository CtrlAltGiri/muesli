import Testing
import Foundation
@testable import MuesliNativeApp

@Suite("DictationStore", .serialized)
struct DictationStoreTests {

    @Test("migration creates tables without error")
    func migration() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.migrateIfNeeded() // idempotent
    }

    @Test("insert and retrieve dictation")
    func insertAndRetrieve() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearDictations()

        let now = Date()
        try store.insertDictation(
            text: "Test dictation text here",
            durationSeconds: 3.5,
            startedAt: now.addingTimeInterval(-3.5),
            endedAt: now
        )

        let rows = try store.recentDictations(limit: 10)
        #expect(rows.count == 1)
        #expect(rows.first!.rawText == "Test dictation text here")
        #expect(rows.first!.wordCount == 4)
    }

    @Test("insert and retrieve meeting")
    func insertAndRetrieveMeeting() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearMeetings()

        let start = Date()
        try store.insertMeeting(
            title: "Test Meeting",
            calendarEventID: nil,
            startTime: start,
            endTime: start.addingTimeInterval(600),
            rawTranscript: "Speaker one said hello. Speaker two replied.",
            formattedNotes: "## Summary\nGood meeting",
            micAudioPath: nil,
            systemAudioPath: nil
        )

        let rows = try store.recentMeetings(limit: 10)
        #expect(rows.count == 1)
        #expect(rows.first!.title == "Test Meeting")
        #expect(rows.first!.wordCount == 7)
    }

    @Test("update meeting notes and title")
    func updateMeeting() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearMeetings()

        let start = Date()
        try store.insertMeeting(
            title: "Meeting",
            calendarEventID: nil,
            startTime: start,
            endTime: start.addingTimeInterval(60),
            rawTranscript: "Some transcript",
            formattedNotes: "",
            micAudioPath: nil,
            systemAudioPath: nil
        )

        let rows = try store.recentMeetings(limit: 1)
        let meetingId = rows.first!.id

        try store.updateMeeting(id: meetingId, title: "Sprint Planning", formattedNotes: "## Summary\nPlanned the sprint")

        let updated = try store.recentMeetings(limit: 1)
        #expect(updated.first!.title == "Sprint Planning")
        #expect(updated.first!.formattedNotes == "## Summary\nPlanned the sprint")
    }

    @Test("update meeting notes only")
    func updateMeetingNotesOnly() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearMeetings()

        let start = Date()
        try store.insertMeeting(
            title: "Original Title",
            calendarEventID: nil,
            startTime: start,
            endTime: start.addingTimeInterval(60),
            rawTranscript: "Transcript",
            formattedNotes: "Old notes",
            micAudioPath: nil,
            systemAudioPath: nil
        )

        let rows = try store.recentMeetings(limit: 1)
        try store.updateMeetingNotes(id: rows.first!.id, formattedNotes: "New notes")

        let updated = try store.recentMeetings(limit: 1)
        #expect(updated.first!.title == "Original Title") // title unchanged
        #expect(updated.first!.formattedNotes == "New notes")
    }

    @Test("dictation stats aggregate correctly")
    func dictationStats() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearDictations()

        let now = Date()
        try store.insertDictation(text: "one two three", durationSeconds: 2.0, startedAt: now.addingTimeInterval(-2), endedAt: now)
        try store.insertDictation(text: "four five", durationSeconds: 1.5, startedAt: now.addingTimeInterval(-1.5), endedAt: now)

        let stats = try store.dictationStats()
        #expect(stats.totalWords == 5)
        #expect(stats.totalSessions == 2)
        #expect(stats.averageWPM > 0)
    }

    @Test("meeting stats aggregate correctly")
    func meetingStats() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearMeetings()

        let start = Date()
        try store.insertMeeting(
            title: "Stats Meeting", calendarEventID: nil,
            startTime: start, endTime: start.addingTimeInterval(300),
            rawTranscript: "This is a test transcript with several words",
            formattedNotes: "", micAudioPath: nil, systemAudioPath: nil
        )

        let stats = try store.meetingStats()
        #expect(stats.totalMeetings == 1)
        #expect(stats.totalWords == 8)
    }

    @Test("clear dictations removes all records")
    func clearDictations() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        let now = Date()
        try store.insertDictation(text: "to delete", durationSeconds: 1.0, startedAt: now, endedAt: now)
        try store.clearDictations()
        #expect(try store.recentDictations(limit: 100).isEmpty)
    }

    @Test("clear meetings removes all records")
    func clearMeetings() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        let now = Date()
        try store.insertMeeting(title: "Del", calendarEventID: nil, startTime: now, endTime: now.addingTimeInterval(60), rawTranscript: "x", formattedNotes: "", micAudioPath: nil, systemAudioPath: nil)
        try store.clearMeetings()
        #expect(try store.recentMeetings(limit: 100).isEmpty)
    }

    @Test("recent dictations respects limit")
    func limitRespected() throws {
        let store = DictationStore()
        try store.migrateIfNeeded()
        try store.clearDictations()
        let now = Date()
        for i in 0..<5 {
            try store.insertDictation(text: "Entry \(i)", durationSeconds: 1.0, startedAt: now.addingTimeInterval(Double(i)), endedAt: now.addingTimeInterval(Double(i) + 1))
        }
        #expect(try store.recentDictations(limit: 3).count == 3)
    }
}
