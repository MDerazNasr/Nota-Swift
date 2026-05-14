import Foundation

public actor PersistenceStore {
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var notesSaveTask: Task<Void, Error>?
    private var settingsSaveTask: Task<Void, Error>?

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func loadNotes() async -> AppState {
        let fallback = AppDefaults.makeDefaultAppState()

        do {
            try ensureDirectory()
            let url = notesURL()

            guard FileManager.default.fileExists(atPath: url.path()) else {
                try writeNotesNow(fallback)
                return fallback
            }

            let data = try Data(contentsOf: url)
            let envelope = try decoder.decode(NotesEnvelope.self, from: data)
            return NotesNormalizer.normalize(appState: envelope.state)
        } catch {
            NSLog("nota failed to load notes: \(String(describing: error))")
            try? writeNotesNow(fallback)
            return fallback
        }
    }

    public func saveNotes(_ appState: AppState) async throws {
        notesSaveTask?.cancel()
        let normalized = NotesNormalizer.normalize(appState: appState)

        let task = Task<Void, Error> {
            try await Task.sleep(nanoseconds: AppDefaults.saveDelayNanoseconds)
            try self.writeNotesNow(normalized)
        }

        notesSaveTask = task
        try await task.value
    }

    public func loadSettings() async -> Settings {
        let fallback = SettingsNormalizer.normalize(settings: AppDefaults.defaultSettings)

        do {
            try ensureDirectory()
            let url = settingsURL()

            guard FileManager.default.fileExists(atPath: url.path()) else {
                try writeSettingsNow(fallback)
                return fallback
            }

            let data = try Data(contentsOf: url)
            let envelope = try decoder.decode(SettingsEnvelope.self, from: data)
            return SettingsNormalizer.normalize(settings: envelope.settings)
        } catch {
            NSLog("nota failed to load settings: \(String(describing: error))")
            try? writeSettingsNow(fallback)
            return fallback
        }
    }

    public func saveSettings(_ settings: Settings) async throws {
        settingsSaveTask?.cancel()
        let normalized = SettingsNormalizer.normalize(settings: settings)

        let task = Task<Void, Error> {
            try await Task.sleep(nanoseconds: AppDefaults.saveDelayNanoseconds)
            try self.writeSettingsNow(normalized)
        }

        settingsSaveTask = task
        try await task.value
    }

    private func notesURL() -> URL {
        baseURL.appendingPathComponent(AppDefaults.notesFileName)
    }

    private func settingsURL() -> URL {
        baseURL.appendingPathComponent(AppDefaults.settingsFileName)
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private func writeNotesNow(_ appState: AppState) throws {
        try ensureDirectory()
        let data = try encoder.encode(NotesEnvelope(state: appState))
        try data.write(to: notesURL(), options: .atomic)
    }

    private func writeSettingsNow(_ settings: Settings) throws {
        try ensureDirectory()
        let data = try encoder.encode(SettingsEnvelope(settings: settings))
        try data.write(to: settingsURL(), options: .atomic)
    }
}
