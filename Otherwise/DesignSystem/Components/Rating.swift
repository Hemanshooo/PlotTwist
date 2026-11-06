import SwiftUI

/// A rating in roses. Five places along a stem: an open rose is a whole, a
/// bud is a half, and an empty place is a seed. So ★★★½ reads as three
/// roses and a bud.
///
/// Give it `onChange` and it can be rated: drag along it, or tap a place.
/// Tapping the rating it already has clears it. Without `onChange` it only shows.
struct RoseRating: View {
    /// 0…5 in halves; 0 is unrated.
    var value: Double
    var size: CGFloat = DS.Size.roseRating
    var onChange: ((Double) -> Void)? = nil

    @State private var dragStart: Double?
    @State private var changes = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spacing: CGFloat { size * 0.18 }
    private var slot: CGFloat { size * 1.1 }
    private var width: CGFloat { slot * 5 + spacing * 4 }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                place(index)
            }
        }
        .frame(width: width, height: slot)
        .contentShape(Rectangle())
        .gesture(drag, isEnabled: onChange != nil)
        .sensoryFeedback(.selection, trigger: changes)
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue(Self.spoken(value))
        .accessibilityAdjustableAction { direction in
            guard let onChange else { return }
            switch direction {
            case .increment: onChange(min(5, value + 0.5))
            case .decrement: onChange(max(0, value - 0.5))
            @unknown default: break
            }
        }
    }

    private func place(_ index: Int) -> some View {
        let fill = min(max(value - Double(index), 0), 1)
        let animation = reduceMotion ? nil : DS.Motion.bloom(index)
        return ZStack {
            Circle()
                .fill(DS.Colors.inkTertiary)
                .frame(width: max(2.5, size * 0.16), height: max(2.5, size * 0.16))
                .opacity(fill == 0 ? 1 : 0)
            Bud(size: size * 0.92, open: fill == 0.5 ? 1 : 0)
            Rose(size: size, seed: index * 3 + 2, open: fill >= 1 ? 1 : 0)
        }
        .frame(width: slot, height: slot)
        .animation(animation, value: fill)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if dragStart == nil { dragStart = value }
                set(rating(at: gesture.location.x))
            }
            .onEnded { gesture in
                let tapped = rating(at: gesture.location.x)
                // A tap on the rating it already had clears it.
                if abs(gesture.translation.width) < 4, tapped == dragStart {
                    set(0)
                }
                dragStart = nil
            }
    }

    private func rating(at x: CGFloat) -> Double {
        let raw = Double(x / width) * 5
        return min(max((raw * 2).rounded(.up) / 2, 0.5), 5)
    }

    private func set(_ newValue: Double) {
        guard newValue != value else { return }
        changes += 1
        onChange?(newValue)
    }

    /// "3½ roses", "Not rated".
    static func spoken(_ value: Double) -> String {
        guard value > 0 else { return String(localized: "Not rated") }
        let whole = Int(value)
        let half = value - Double(whole) >= 0.5
        return half ? String(localized: "\(whole) and a half roses") : String(localized: "\(whole) roses")
    }

    /// "★★★½" as text, for share sheets and plain places.
    static func stars(_ value: Double) -> String {
        guard value > 0 else { return "" }
        let whole = Int(value)
        return String(repeating: "★", count: whole) + (value - Double(whole) >= 0.5 ? "½" : "")
    }
}

/// The heart: a book you loved. Fills in the bloom colour and gives a little beat.
struct HeartToggle: View {
    let isOn: Bool
    var size: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .light))
                .foregroundStyle(isOn ? DS.Colors.bloom : DS.Colors.inkTertiary)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isOn)
                .frame(width: DS.Size.touch, height: DS.Size.touch)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel(isOn ? "Loved" : "Love this book")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// A small heart that only shows (in lists).
struct HeartMark: View {
    var size: CGFloat = 11

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(DS.Colors.bloom)
            .accessibilityLabel("Loved")
    }
}

#Preview {
    @Previewable @State var rating = 3.5
    @Previewable @State var liked = true
    VStack(spacing: DS.Space.l) {
        RoseRating(value: rating, size: 30) { rating = $0 }
        RoseRating(value: rating)
        RoseRating(value: 0)
        HeartToggle(isOn: liked) { liked.toggle() }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
