import SwiftUI

/// "How far have you read?", answered on a gauge. It decides how much of
/// the story map is shown, so nobody is spoiled and nobody needs to
/// remember the whole plot.
///
/// The arc fills to your progress; a bracket splits it into three pills
/// (Finished · Partway · Not yet), the way Opal splits a score. Choosing
/// a pill saves straight away; "Partway" adds a slider.
struct ReadingGauge: View {
    let edition: Edition
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

        var symbol: String {
            switch self {
            case .finished: "checkmark.seal.fill"
            case .partway: "bookmark.fill"
            case .notStarted: "book.closed"
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
        VStack(spacing: DS.Space.s) {
            ArcGauge(value: shown, colors: edition.gradientColors) {
                VStack(spacing: DS.Space.xxs) {
                    if progress == nil {
                        Image(systemName: "book")
                            .font(DS.Typography.symbol)
                            .foregroundStyle(edition.ink)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(verbatim: "\(Int((shown * 100).rounded()))")
                                .font(DS.Typography.gauge)
                                .contentTransition(.numericText(value: shown))
                            Text(verbatim: "%")
                                .font(DS.Typography.heading)
                                .opacity(0.7)
                        }
                        .foregroundStyle(edition.ink)
                    }
                    Text(caption)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DS.Space.xl)
            }
            .accessibilityElement(children: .combine)

            BracketShape(count: 3)
                .stroke(DS.Colors.inkTertiary.opacity(0.7), style: StrokeStyle(lineWidth: DS.Size.hairline, lineCap: .round))
                .frame(height: DS.Space.l)
                .padding(.horizontal, DS.Space.xxs)
                .accessibilityHidden(true)

            HStack(spacing: DS.Space.xs) {
                ForEach(Choice.allCases, id: \.self) { option in
                    GlowPill(
                        title: option.title,
                        systemImage: option.symbol,
                        isSelected: choice == option,
                        colors: edition.gradientColors
                    ) {
                        choose(option)
                    }
                }
            }

            if choice == .partway {
                VStack(spacing: DS.Space.xxs) {
                    Slider(value: $fraction, in: 0.05...0.95, onEditingChanged: { editing in
                        if !editing { onChange(.partway(fraction)) }
                    })
                    .tint(edition.ink)
                    .accessibilityLabel("How far through the book")
                    .accessibilityValue(Text("\(Int(fraction * 100)) percent"))
                    HStack {
                        Text("Beginning")
                        Spacer()
                        Text("End")
                    }
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkTertiary)
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.vertical, DS.Space.s)
                .dsGlass()
                .padding(.top, DS.Space.xs)
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
        case nil: "How far have you read?"
        case .finished: "Finished"
        case .partway: "Read so far"
        case .notStarted: "Not started"
        }
    }

    private func fill(to value: Double) {
        withAnimation(reduceMotion ? DS.Motion.standard : DS.Motion.gauge) { shown = value }
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
    ReadingGauge(edition: Catalog.entries[0].edition, progress: progress) { progress = $0 }
        .padding(DS.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsScreen(glow: Catalog.entries[0].edition.glow)
}
