import SwiftUI

/// The book's plot as a timeline: where it begins, its turning points in order,
/// and a last stop for changes that aren't on the map. Moments beyond the
/// reader's progress are sealed until they choose to reveal them.
struct StoryMapView: View {
    let map: StoryMap
    let edition: Edition
    let threshold: Double
    let revealAll: Bool
    let onSelect: (Moment) -> Void
    let onReveal: () -> Void
    let onFreeChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Story map", color: edition.ink)
                Spacer()
                if !map.isCurated {
                    Label("Drawn by Apple Intelligence", systemImage: "apple.intelligence")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.inkTertiary)
                }
            }
            .padding(.bottom, DS.Space.m)

            TimelineRow(node: .start, ink: edition.ink, isFirst: true, isLast: false) {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow("Where it begins")
                    Text(map.premise)
                        .font(DS.Typography.reading)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineSpacing(DS.Leading.relaxed)
                }
                .padding(.vertical, DS.Space.xs)
            }

            ForEach(map.moments) { moment in
                // The first turning point is the set-up, so it's always open.
                let unlocked = revealAll || moment.position <= threshold + 0.0001 || moment.id == map.moments.first?.id
                TimelineRow(node: unlocked ? .moment : .sealed, ink: edition.ink, isFirst: false, isLast: false) {
                    if unlocked {
                        MomentCard(moment: moment, edition: edition) { onSelect(moment) }
                    } else {
                        SealedCard(moment: moment, edition: edition, action: onReveal)
                    }
                }
                .transition(.opacity)
            }

            TimelineRow(node: .end, ink: edition.ink, isFirst: false, isLast: true) {
                Button(action: onFreeChange) {
                    HStack(spacing: DS.Space.s) {
                        Image(systemName: "pencil.line")
                            .foregroundStyle(edition.ink)
                        Text("Change something that isn’t on the map")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(DS.Space.m)
                    .frame(minHeight: DS.Size.touch)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                            .strokeBorder(DS.Colors.inkTertiary, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [5, 4]))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .animation(DS.Motion.standard, value: revealAll)
        .animation(DS.Motion.standard, value: threshold)
    }
}

// MARK: - Timeline row

private struct TimelineRow<Content: View>: View {
    enum Node { case start, moment, sealed, end }

    let node: Node
    let ink: Color
    let isFirst: Bool
    let isLast: Bool
    @ViewBuilder let content: Content

    /// Where the node sits, so it lines up with the first line of a card.
    private let nodeY: CGFloat = 24

    var body: some View {
        content
            .padding(.leading, DS.Size.timelineGutter)
            .padding(.bottom, isLast ? 0 : DS.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(isFirst ? .clear : ink.opacity(0.35))
                            .frame(width: DS.Size.rule, height: nodeY)
                        Rectangle()
                            .fill(isLast ? .clear : ink.opacity(0.35))
                            .frame(width: DS.Size.rule)
                            .frame(maxHeight: .infinity)
                    }
                    nodeView
                        .offset(y: nodeY - DS.Size.timelineNode / 2)
                }
                .frame(width: DS.Size.timelineNode + 8)
                .frame(maxHeight: .infinity, alignment: .top)
            }
    }

    @ViewBuilder private var nodeView: some View {
        let size = DS.Size.timelineNode
        switch node {
        case .start:
            Circle().strokeBorder(ink, lineWidth: DS.Size.rule)
                .background(Circle().fill(DS.Colors.canvas))
                .frame(width: size, height: size)
        case .moment:
            Circle().fill(ink)
                .frame(width: size, height: size)
        case .sealed:
            Circle().fill(DS.Colors.canvas)
                .overlay(Circle().strokeBorder(ink.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [2, 2])))
                .frame(width: size, height: size)
        case .end:
            Image(systemName: "plus.circle.fill")
                .font(.system(size: size + 4))
                .foregroundStyle(ink)
                .background(Circle().fill(DS.Colors.canvas))
        }
    }
}

// MARK: - Cards

private struct MomentCard: View {
    let moment: Moment
    let edition: Edition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: DS.Space.s) {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow(verbatim: moment.chapter, color: edition.ink)
                    Text(moment.title)
                        .font(DS.Typography.rowTitle)
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Text(moment.happened)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(DS.Typography.captionEmphasis)
                    .foregroundStyle(DS.Colors.inkTertiary)
            }
            .padding(DS.Space.m)
            .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                    .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Choose what happens instead")
    }
}

/// A moment beyond the reader's progress: sealed with wax, like an uncut page.
private struct SealedCard: View {
    let moment: Moment
    let edition: Edition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s) {
                ZStack {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(edition.ink)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(edition.onInk)
                }
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow(verbatim: moment.chapter, color: DS.Colors.inkTertiary)
                    Text("Sealed until you get here")
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(DS.Space.m)
            .background {
                ZStack {
                    DS.Colors.fold
                    EditionPattern(edition: edition, tile: 14, intensity: 0.5).opacity(0.08)
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("\(moment.chapter), sealed"))
        .accessibilityHint("Reveals the rest of the map, including spoilers")
    }
}
