import SwiftUI
import TypeCore

struct ReportView: View {
    let report: TypeReport
    let people: [Person]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                ForEach(report.sections, id: \.title) { item in
                    SectionCard(title: item.title, section: item.section)
                }

                if !report.commonThreads.isEmpty {
                    ListCard(title: "What they all share", symbol: "link", items: report.commonThreads)
                }
                if !report.outliers.isEmpty {
                    ListCard(title: "Who breaks the pattern", symbol: "shuffle", items: report.outliers)
                }

                Label(report.caveats, systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 30)
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
            .textSelection(.enabled)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.pink)
                .textCase(.uppercase)
            Text(report.headline)
                .font(.system(size: 34, weight: .bold, design: .serif))
            Text(report.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(people.prefix(12)) { person in
                    if let photo = person.photos.first, let image = NSImage(data: photo.jpeg) {
                        Image(nsImage: image).resizable().scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }
                }
                Text("Based on \(people.count) \(people.count == 1 ? "person" : "people")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

private struct SectionCard: View {
    let title: String
    let section: TypeSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold())
            Text(section.summary)
            ForEach(section.traits) { trait in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ConfidenceDot(confidence: trait.confidence)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trait.name).fontWeight(.semibold)
                        Text(trait.detail).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ConfidenceDot: View {
    let confidence: Confidence

    var body: some View {
        Circle()
            .fill(Color.pink.opacity(opacity))
            .frame(width: 9, height: 9)
            .help("\(confidence.rawValue.capitalized) confidence")
    }

    private var opacity: Double {
        switch confidence {
        case .high: 1
        case .medium: 0.55
        case .low: 0.2
        }
    }
}

private struct ListCard: View {
    let title: String
    let symbol: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.title3.bold())
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
            }
        }
    }
}
