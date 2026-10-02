import AppKit
import SwiftUI

/// Small feedback sheet. Entries are appended to a local Markdown file.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var saved = false

    static var fileURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Figure Out Your Type", isDirectory: true)
        return folder.appendingPathComponent("Feedback.md")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feedback").font(.title2.bold())
            Text("What worked, what didn't, what you'd want next.")
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .frame(height: 140)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
            if saved {
                Label("Saved to Feedback.md", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            }
            HStack {
                Button("Show File") { NSWorkspace.shared.activateFileViewerSelecting([Self.fileURL]) }
                    .disabled(!FileManager.default.fileExists(atPath: Self.fileURL.path))
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func save() {
        let url = Self.fileURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let entry = "## \(Date().formatted(date: .abbreviated, time: .shortened))\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(entry.utf8))
            try? handle.close()
        } else {
            try? Data(("# Figure Out Your Type — Feedback\n\n" + entry).utf8).write(to: url)
        }
        text = ""
        saved = true
    }
}
