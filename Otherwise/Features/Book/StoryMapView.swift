import SwiftUI

/// The book's plot as a vine: it springs from where the story begins, opens
/// a rose at every turning point you've reached, carries closed buds for the
/// ones still ahead, and curls away at the end, by changes that aren't on the map.
/// Moments beyond the reader's progress are sealed until they choose to reveal them.
struct StoryMapView: View {
    let map: StoryMap
    let threshold: Double
    let revealAll: Bool
    let onSelect: (Moment) -> Void
    let onReveal: () -> Void
    let onFreeChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Story map")
                Spacer()
                if !map.isCurated {
                    Hint("drawn by apple intelligence")
                }
            }
            .padding(.bottom, DS.Space.xs)
            Hairline()
                .padding(.bottom, DS.Space.m)

            TimelineRow(node: .start, index: 0, isFirst: true, isLast: false) {
                Hint("where it begins")
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.l)
            }

            ForEach(Array(map.moments.enumerated()), id: \.element.id) { index, moment in
                // The first turning point is the set-up, so it's always open.
                let unlocked = revealAll || moment.position <= threshold + 0.0001 || moment.id == map.moments.first?.id
                TimelineRow(node: unlocked ? .moment : .sealed, index: index + 1, isFirst: false, isLast: false) {
                    if unlocked {
                        MomentCard(moment: moment) { onSelect(moment) }
                    } else {
                        SealedCard(moment: moment, action: onReveal)
                    }
                }
                .transition(.opacity)
            }

            TimelineRow(node: .end, index: map.moments.count + 1, isFirst: false, isLast: true) {
                Button(action: onFreeChange) {
                    HStack(spacing: DS.Space.s) {
                        Text("Change something that isn’t on the map")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.Colors.ink)
                    }
                    .padding(DS.Space.m)
                    .frame(minHeight: DS.Size.touch)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                            .strokeBorder(DS.Colors.inkTertiary, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [4, 4]))
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

// MARK: - The vine

/// What grows where a row meets the vine.
private enum VineNode: Equatable { case start, moment, sealed, end }

private struct TimelineRow<Content: View>: View {
    let node: VineNode
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.leading, DS.Size.vineGutter)
            .padding(.bottom, isLast ? 0 : DS.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                Growing(delay: 0.06 * Double(index)) { progress in
                    VineSegment(node: node, index: index, isFirst: isFirst, isLast: isLast, progress: progress)
                }
                .frame(width: DS.Size.vineGutter)
            }
    }
}

/// One row's stretch of the vine. Each stretch bows once, alternately left
/// and right, and meets the next at the centre line, so the stretches join
/// into one stem winding down the map.
private struct VineSegment: View, Animatable {
    let node: VineNode
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Where the node sits, level with the first line of a card.
    private let nodeY: CGFloat = 24

    var body: some View {
        let ink = GardenInk.current
        let muted = GardenInk.mono(DS.Colors.inkTertiary, ground: DS.Colors.canvas)
        Canvas { context, size in
            let centre: CGFloat = 12
            let bow: CGFloat = index.isMultiple(of: 2) ? 3.5 : -3.5
            func x(_ y: CGFloat) -> CGFloat { centre + bow * sin(.pi * y / max(size.height, 1)) }
            let top = isFirst ? nodeY : 0
            let bottom = isLast ? nodeY : size.height
            let points = stride(from: top, through: bottom, by: 6).map { CGPoint(x: x($0), y: $0) } + [CGPoint(x: x(bottom), y: bottom)]
            context.drawStem(Botany.stem(through: points), ink: ink, width: DS.Size.stem, progress: min(progress / 0.8, 1))
            // A leaf partway down longer stretches.
            if !isLast, size.height > 90 {
                let y = size.height * 0.62
                let up = index.isMultiple(of: 2)
                context.drawLeaf(
                    at: CGPoint(x: x(y), y: y),
                    angle: .degrees(up ? -40 : -140),
                    length: 13,
                    ink: ink,
                    open: Ease.opening(progress, start: 0.5, span: 0.3),
                    vein: false
                )
            }
            let point = CGPoint(x: x(nodeY), y: nodeY)
            switch node {
            case .start:
                context.drawStem(
                    Botany.tendril(start: point, angle: .degrees(-90), radius: 5, clockwise: true),
                    ink: ink,
                    width: 1.4,
                    progress: progress
                )
                context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(ink.stem))
            case .moment:
                context.drawRose(at: point, size: DS.Size.rose, seed: index * 7 + 3, ink: ink, open: Ease.opening(progress, start: 0.35, span: 0.5))
            case .sealed:
                context.drawBud(at: CGPoint(x: point.x, y: point.y + 7), angle: .degrees(-90), length: 14, ink: muted, open: Ease.opening(progress, start: 0.35, span: 0.5))
            case .end:
                context.drawStem(
                    Botany.tendril(start: point, angle: .degrees(90), radius: 5, clockwise: false),
                    ink: ink,
                    width: 1.4,
                    progress: Ease.opening(progress, start: 0.6, span: 0.4)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Cards

private struct MomentCard: View {
    let moment: Moment
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: DS.Space.s) {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow(verbatim: moment.chapter)
                    Text(moment.title)
                        .font(DS.Typography.heading)
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Text(moment.happened)
                        .font(DS.Typography.blurb)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.inkTertiary)
            }
            .padding(DS.Space.m)
            .dsOutline()
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Choose what happens instead")
    }
}

/// A moment beyond the reader's progress: still in bud, like an uncut page.
private struct SealedCard: View {
    let moment: Moment
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s) {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow(verbatim: moment.chapter, color: DS.Colors.inkTertiary)
                    Hint("still in bud · tap to reveal")
                }
                Spacer(minLength: 0)
                Image(systemName: "lock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.inkTertiary)
            }
            .padding(DS.Space.m)
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                    .strokeBorder(DS.Colors.hairline, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [2, 3]))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("\(moment.chapter), sealed"))
        .accessibilityHint("Reveals the rest of the map, including spoilers")
    }
}
