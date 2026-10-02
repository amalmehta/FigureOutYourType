import SwiftUI
import TypeCore

struct PersonCard: View {
    @Environment(AppModel.self) private var model
    let number: Int
    let personID: Person.ID
    let addPhotos: () -> Void
    @State private var isTargeted = false

    var body: some View {
        if let index = model.people.firstIndex(where: { $0.id == personID }) {
            @Bindable var model = model
            let person = model.people[index]
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Person \(number)").font(.headline)
                    Spacer()
                    Button(action: addPhotos) { Image(systemName: "plus") }
                        .help("Add more photos of this person")
                    Button(role: .destructive) { model.remove(personID) } label: { Image(systemName: "trash") }
                        .help("Remove this person")
                }
                .buttonStyle(.borderless)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(person.photos) { photo in
                            Thumbnail(photo: photo)
                                .contextMenu {
                                    Button("Remove Photo", role: .destructive) {
                                        model.remove(photo: photo.id, from: personID)
                                    }
                                }
                        }
                    }
                }

                TextField("Optional: what are they like?", text: $model.people[index].note, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(14)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isTargeted ? Color.accentColor : .clear, lineWidth: 2)
            }
            .onDrop(of: [.fileURL, .image], isTargeted: $isTargeted) { model.handleDrop($0, to: personID) }
        }
    }
}

private struct Thumbnail: View {
    let photo: Photo

    var body: some View {
        Group {
            if let image = NSImage(data: photo.jpeg) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Color.gray
            }
        }
        .frame(width: 110, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
