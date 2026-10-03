import SwiftUI

/// "How far have you read?" Decides how much of the story map is shown,
/// so nobody is spoiled and nobody needs to remember the whole plot.
struct ReadingProgressCard: View {
    let edition: Edition
    let initial: ReadingProgress?
    let onSave: (ReadingProgress) -> Void

    private enum Choice: CaseIterable {
        case finished, partway, notStarted

        var title: LocalizedStringKey {
            switch self {
            case .finished: "Finished"
            case .partway: "Partway"
            case .notStarted: "Not yet"
            }
        }
    }

    @State private var choice: Choice?
    @State private var fraction: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text("How far have you read?")
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                Text("You’ll only see the parts of the story you’ve reached.")
                    .font(DS.Typography.meta)
                    .foregroundStyle(DS.Colors.inkSecondary)
            }

            HStack(spacing: DS.Space.xs) {
                ForEach(Choice.allCases, id: \.self) { option in
                    pill(option)
                }
            }

            if choice == .partway {
                VStack(spacing: DS.Space.xxs) {
                    Slider(value: $fraction, in: 0.05...0.95)
                        .tint(edition.ink)
                        .accessibilityLabel("How far through the book")
                        .accessibilityValue(Text("\(Int(fraction * 100)) percent"))
                    HStack {
                        Text("Beginning")
                        Spacer()
                        Text("About \(Int((fraction * 10).rounded()) * 10)% through")
                            .foregroundStyle(edition.ink)
                            .monospacedDigit()
                        Spacer()
                        Text("End")
                    }
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkTertiary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            PrimaryButton("Open the story map", edition: edition) {
                guard let choice else { return }
                switch choice {
                case .finished: onSave(.finished)
                case .partway: onSave(.partway(fraction))
                case .notStarted: onSave(.notStarted)
                }
            }
            .disabled(choice == nil)
        }
        .padding(DS.Space.m)
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
        }
        .animation(DS.Motion.standard, value: choice)
        .onAppear {
            switch initial {
            case .finished: choice = .finished
            case .partway(let p): choice = .partway; fraction = p
            case .notStarted: choice = .notStarted
            case nil: break
            }
        }
    }

    private func pill(_ option: Choice) -> some View {
        let selected = choice == option
        return Button {
            choice = option
        } label: {
            Text(option.title)
                .font(DS.Typography.metaEmphasis)
                .foregroundStyle(selected ? edition.onInk : DS.Colors.ink)
                .frame(maxWidth: .infinity, minHeight: DS.Size.touch)
                .background(selected ? edition.ink : DS.Colors.canvas, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? .clear : DS.Colors.hairline, lineWidth: DS.Size.hairline))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The reader's progress once set: a small ribbon-marked chip that reopens the card.
struct ReadingProgressChip: View {
    let edition: Edition
    let progress: ReadingProgress
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: symbol)
                    .foregroundStyle(edition.ink)
                Text(label)
                    .foregroundStyle(DS.Colors.ink)
                Text("Change")
                    .foregroundStyle(DS.Colors.inkTertiary)
            }
            .font(DS.Typography.meta)
            .padding(.horizontal, DS.Space.s)
            .frame(minHeight: DS.Size.touch)
            .background(DS.Colors.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Changes how much of the story map is shown")
    }

    private var symbol: String {
        switch progress {
        case .finished: "checkmark.seal.fill"
        case .partway: "bookmark.fill"
        case .notStarted: "book.closed"
        }
    }

    private var label: LocalizedStringKey {
        switch progress {
        case .finished: "Finished"
        case .partway(let p): "Reading · \(Int((p * 10).rounded()) * 10)%"
        case .notStarted: "Not read yet"
        }
    }
}
