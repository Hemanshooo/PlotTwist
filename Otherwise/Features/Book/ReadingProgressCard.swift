import SwiftUI

/// "How far have you read?", answered with a vine. It decides how much of
/// the story map is shown, so nobody is spoiled and nobody needs to
/// remember the whole plot.
///
/// A big numeral, then the vine grown as far as you've read (a bud at its
/// tip, or a rose once you've finished), then three pills: Finished ·
/// Partway · Not yet. Choosing saves straight away; "Partway" adds a slider.
struct ReadingGauge: View {
    let progress: ReadingProgress?
    let onChange: (ReadingProgress) -> Void

    @State private var fraction: Double = 0.5
    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    private var choice: Choice? {
        switch progress {
        case .finished: .finished
        case .partway: .partway
        case .notStarted: .notStarted
        case nil: nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Your reading")
                Spacer()
                Hint(caption)
            }
            Hairline()

            Group {
                if progress == nil {
                    Text("How far have you read?")
                        .dsDisplay(DS.Typography.title)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(verbatim: "\(Int((shown * 100).rounded()))")
                            .font(DS.Typography.numeral)
                            .contentTransition(.numericText(value: shown))
                        Text(verbatim: "%")
                            .font(DS.Typography.title)
                            .foregroundStyle(DS.Colors.inkSecondary)
                    }
                    .foregroundStyle(DS.Colors.ink)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(Int((shown * 100).rounded())) percent read"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VineGauge(value: shown, isFinished: choice == .finished)

            ChoicePills(
                options: Choice.allCases.map { ChoicePills<Choice>.Option(id: $0, title: $0.title) },
                selection: choice,
                onSelect: choose
            )

            if choice == .partway {
                VStack(spacing: DS.Space.xxs) {
                    Slider(value: $fraction, in: 0.05...0.95, onEditingChanged: { editing in
                        if !editing { onChange(.partway(fraction)) }
                    })
                    .tint(DS.Colors.stem)
                    .accessibilityLabel("How far through the book")
                    .accessibilityValue(Text("\(Int(fraction * 100)) percent"))
                    HStack {
                        Hint("beginning")
                        Spacer()
                        Hint("end")
                    }
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.vertical, DS.Space.s)
                .dsOutline()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(DS.Motion.standard, value: choice)
        .onAppear {
            if case .partway(let p) = progress { fraction = p }
            fill(to: target)
        }
        .onChange(of: target) { _, value in fill(to: value) }
        .onChange(of: fraction) { _, value in
            if choice == .partway { shown = value }
        }
    }

    private var target: Double {
        progress?.fraction ?? 0
    }

    private var caption: LocalizedStringKey {
        switch progress {
        case nil: "unlocks the map"
        case .finished: "finished"
        case .partway: "read so far"
        case .notStarted: "not started"
        }
    }

    private func fill(to value: Double) {
        withAnimation(reduceMotion ? DS.Motion.standard : .easeInOut(duration: 1.2)) { shown = value }
    }

    private func choose(_ option: Choice) {
        switch option {
        case .finished: onChange(.finished)
        case .partway: onChange(.partway(fraction))
        case .notStarted: onChange(.notStarted)
        }
    }
}

#Preview {
    @Previewable @State var progress: ReadingProgress? = nil
    ReadingGauge(progress: progress) { progress = $0 }
        .padding(DS.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsScreen()
}
