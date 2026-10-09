import SwiftUI
import TypeCore

/// The quick survey sheet. Every question is optional.
struct SurveyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Survey").font(.title2.bold())
                Text("Five optional questions about you. They help Claude read your emotional and spiritual type.")
                    .foregroundStyle(.secondary)
            }
            .padding(20)

            Form {
                Section("1. What do you notice first?") {
                    ChoiceChips(options: Survey.noticeFirstOptions, isSelected: { model.survey.noticeFirst == $0 }) {
                        model.survey.noticeFirst = model.survey.noticeFirst == $0 ? nil : $0
                    }
                }
                Section("2. Which qualities draw you in most? (up to \(Survey.maxQualities))") {
                    ChoiceChips(options: Survey.qualityOptions, isSelected: { model.survey.qualities.contains($0) }) {
                        model.survey.toggleQuality($0)
                    }
                }
                Section("3. How much do shared spiritual beliefs or values matter?") {
                    ChoiceChips(options: Survey.valuesOptions, isSelected: { model.survey.values == $0 }) {
                        model.survey.values = model.survey.values == $0 ? nil : $0
                    }
                }
                Section("4. Any deal-breakers?") {
                    TextField("e.g. smoking, no sense of humor", text: $model.survey.dealBreakers, axis: .vertical)
                        .lineLimit(1...3)
                        .labelsHidden()
                }
                Section("5. Anything else about what you're looking for?") {
                    TextField("Optional", text: $model.survey.anythingElse, axis: .vertical)
                        .lineLimit(2...4)
                        .labelsHidden()
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Clear Answers") { model.survey = Survey() }
                    .disabled(model.survey.isEmpty)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 520, height: 640)
    }
}

/// Wrapping row of selectable capsules.
private struct ChoiceChips: View {
    let options: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let selected = isSelected(option)
                Button { toggle(option) } label: {
                    Text(option)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selected ? Color.pink : Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(selected ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (subview, origin) in zip(subviews, result.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
