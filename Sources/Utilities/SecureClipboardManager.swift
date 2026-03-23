import Foundation
import AppKit

/// Manager for secure clipboard operations with auto-clear
final class ClipboardManager {
    static let shared = ClipboardManager()

    private var clearTimer: Timer?
    private let clearDelay: TimeInterval = 10 // seconds

    private init() {}

    /// Copy text to clipboard and schedule auto-clear
    func copy(_ text: String) {
        // Clear any existing timer
        clearTimer?.invalidate()

        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // Schedule clearing
        clearTimer = Timer.scheduledTimer(withTimeInterval: clearDelay, repeats: false) { [weak self] _ in
            self?.clearClipboard()
        }
    }

    /// Clear clipboard immediately
    func clearClipboard() {
        NSPasteboard.general.clearContents()
        clearTimer?.invalidate()
        clearTimer = nil
    }

    /// Cancel scheduled clear
    func cancelScheduledClear() {
        clearTimer?.invalidate()
        clearTimer = nil
    }
}
