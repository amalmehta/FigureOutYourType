import Foundation

/// One person the user is drawn to: one or more photos plus an optional note.
public struct Person: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public var photos: [Photo]
    public var note: String

    public init(photos: [Photo], note: String = "") {
        self.photos = photos
        self.note = note
    }
}

/// A photo already shrunk and re-encoded as JPEG, ready to send.
public struct Photo: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let jpeg: Data

    public init(jpeg: Data) {
        self.jpeg = jpeg
    }
}
