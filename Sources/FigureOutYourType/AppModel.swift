import AppKit
import Observation
import TypeCore
import UniformTypeIdentifiers

@MainActor @Observable
final class AppModel {
    var people: [Person] = []
    var report: TypeReport?
    var isAnalyzing = false
    var errorMessage: String?

    var photoCount: Int { people.reduce(0) { $0 + $1.photos.count } }

    // MARK: Adding photos

    /// Each image becomes a new person, or joins `personID` when given.
    func add(imageData: [Data], to personID: Person.ID? = nil) {
        let photos = imageData.compactMap(ImagePrep.jpeg(from:)).map(Photo.init(jpeg:))
        if photos.count < imageData.count {
            errorMessage = "Some files couldn't be read as images and were skipped."
        }
        guard !photos.isEmpty else { return }
        if let personID, let index = people.firstIndex(where: { $0.id == personID }) {
            people[index].photos += photos
        } else {
            people += photos.map { Person(photos: [$0]) }
        }
    }

    func add(fileURLs: [URL], to personID: Person.ID? = nil) {
        let data = fileURLs.compactMap { url -> Data? in
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            return try? Data(contentsOf: url)
        }
        add(imageData: data, to: personID)
    }

    /// Reads images (or image files) from the clipboard.
    func paste() {
        let pasteboard = NSPasteboard.general
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self],
                                             options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            add(fileURLs: urls)
            return
        }
        let images = (pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage] ?? [])
            .compactMap(\.tiffRepresentation)
        if images.isEmpty {
            errorMessage = "There's no image on the clipboard."
        } else {
            add(imageData: images)
        }
    }

    /// Handles a drop of files or raw images from Finder, Photos or a browser.
    func handleDrop(_ providers: [NSItemProvider], to personID: Person.ID? = nil) -> Bool {
        let usable = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
                || $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }
        guard !usable.isEmpty else { return false }
        Task {
            var collected: [Data] = []
            for provider in usable {
                if let data = await Self.loadData(from: provider) { collected.append(data) }
            }
            add(imageData: collected, to: personID)
        }
        return true
    }

    private static func loadData(from provider: NSItemProvider) async -> Data? {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return await withCheckedContinuation { continuation in
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    continuation.resume(returning: url.flatMap { try? Data(contentsOf: $0) })
                }
            }
        }
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    // MARK: Editing

    func remove(_ personID: Person.ID) {
        people.removeAll { $0.id == personID }
    }

    func remove(photo photoID: Photo.ID, from personID: Person.ID) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        people[index].photos.removeAll { $0.id == photoID }
        if people[index].photos.isEmpty { people.remove(at: index) }
    }

    func startOver() {
        people = []
        report = nil
    }

    // MARK: Analysis

    func figureOutType() async {
        guard let key = APIKeyStore.load() else {
            errorMessage = AnalyzerError.noAPIKey.errorDescription
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            report = try await TypeAnalyzer(apiKey: key).analyze(people)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
