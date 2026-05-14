import Foundation

public struct NotesEnvelope: Codable, Equatable, Sendable {
    public var state: AppState

    public init(state: AppState) {
        self.state = state
    }
}

public struct SettingsEnvelope: Codable, Equatable, Sendable {
    public var settings: Settings

    public init(settings: Settings) {
        self.settings = settings
    }
}
