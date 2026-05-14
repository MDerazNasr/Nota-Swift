import Foundation

struct ItemEditorVimState {
    var clipboard: String?
    var commandBuffer = ""
    var lastSearch: String?
    var pendingExCommand: String?
    var pendingSearch: String?
    var visualAnchor: Int?
}

enum ItemEditorVimBuffer {
    private static let bufferableKeys = Set(["g", "y", "d", "c"])
    private static let textObjectKeys = Set(["i", "a"])

    static func recordCommandKey(state: inout ItemEditorVimState, key: String) -> String? {
        guard key.count == 1 || key == "Backspace" || key == "Delete" else {
            return nil
        }

        if state.commandBuffer.isEmpty, bufferableKeys.contains(key) == false {
            return key
        }

        state.commandBuffer += key

        if state.commandBuffer.count == 2, state.commandBuffer.first == "c", textObjectKeys.contains(key) == false {
            let command = state.commandBuffer
            state.commandBuffer = ""
            return command
        }

        if state.commandBuffer.count >= 3 || state.commandBuffer == "gg" || state.commandBuffer == "yy" || state.commandBuffer == "dd" {
            let command = state.commandBuffer
            state.commandBuffer = ""
            return command
        }

        return state.commandBuffer
    }

    static func reset(_ state: inout ItemEditorVimState) {
        state.commandBuffer = ""
        state.pendingExCommand = nil
        state.pendingSearch = nil
    }
}
