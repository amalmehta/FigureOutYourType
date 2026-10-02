import SwiftUI
import TypeCore
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var showingImporter = false
    @State private var importTarget: Person.ID?
    @State private var showingFeedback = false

    var body: some View {
        Group {
            if let report = model.report {
                ReportView(report: report, people: model.people)
            } else if model.people.isEmpty {
                EmptyDropZone(showImporter: { openImporter(for: nil) })
            } else {
                peopleGrid
            }
        }
        .overlay {
            if model.isAnalyzing { AnalyzingOverlay(photoCount: model.photoCount) }
        }
        .overlay(alignment: .bottomTrailing) {
            Button("Feedback") { showingFeedback = true }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(10)
        }
        .toolbar { toolbar }
        .onPasteCommand(of: [.image, .fileURL]) { _ in model.paste() }
        .onDrop(of: [.fileURL, .image], isTargeted: nil) { model.handleDrop($0) }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.image],
                      allowsMultipleSelection: true) { result in
            if case let .success(urls) = result { model.add(fileURLs: urls, to: importTarget) }
        }
        .sheet(isPresented: $showingFeedback) { FeedbackView() }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .navigationTitle("Figure Out Your Type")
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if model.report != nil {
            ToolbarItem(placement: .navigation) {
                Button { model.report = nil } label: { Label("Back to Photos", systemImage: "chevron.left") }
            }
        } else {
            ToolbarItemGroup {
                Button { openImporter(for: nil) } label: { Label("Add Photos", systemImage: "photo.badge.plus") }
                Button { model.paste() } label: { Label("Paste", systemImage: "doc.on.clipboard") }
                Button {
                    Task { await model.figureOutType() }
                } label: {
                    Label("Figure Out My Type", systemImage: "sparkles")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.people.isEmpty || model.isAnalyzing)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
    }

    private var peopleGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(model.people.count) \(model.people.count == 1 ? "person" : "people")")
                    .font(.title2.bold())
                Text("Each new photo starts a new person. Drop more photos onto a card, or use its + button, if they're the same person. Notes are optional but help a lot with emotional and spiritual type.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top], 20)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(Array(model.people.enumerated()), id: \.element.id) { index, person in
                    PersonCard(number: index + 1, personID: person.id, addPhotos: { openImporter(for: person.id) })
                }
            }
            .padding(20)
        }
    }

    private func openImporter(for personID: Person.ID?) {
        importTarget = personID
        showingImporter = true
    }
}

private struct EmptyDropZone: View {
    let showImporter: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.pink)
            Text("Who are you drawn to?")
                .font(.largeTitle.bold())
            Text("Paste (⌘V), drop or add photos of people you'd like to date.\nAdd as many people as you like — the more, the clearer the pattern.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Add Photos…", action: showImporter)
                .controlSize(.large)
                .padding(.top, 6)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .foregroundStyle(.quaternary)
                .padding(24)
        }
    }
}

private struct AnalyzingOverlay: View {
    let photoCount: Int

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Looking at \(photoCount) \(photoCount == 1 ? "photo" : "photos")…")
                    .font(.headline)
                Text("This usually takes a minute or two.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
