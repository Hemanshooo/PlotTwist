import SwiftUI

/// The Plot Twist wordmark, as on the app icon: PLOT upright, and TWIST
/// hanging upside down from the same line, its T tucked under the P, so the
/// words turn back on themselves the way a plot does.
///
/// Set in the masthead style (small, semibold, tracked capitals). When it
/// first appears, TWIST turns over into place once.
struct Wordmark: View {
    @State private var turned = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far TWIST's T reaches in under the P.
    private let tuck: CGFloat = 7

    var body: some View {
        VStack(alignment: .hinge, spacing: -8) {
            Text("Plot")
                .alignmentGuide(.hinge) { $0[.leading] }
            Text("Twist")
                .rotationEffect(.degrees(turned ? 180 : 0))
                .alignmentGuide(.hinge) { $0[.trailing] - tuck }
        }
        .font(DS.Typography.masthead)
        .tracking(DS.Tracking.masthead)
        .textCase(.uppercase)
        .foregroundStyle(DS.Colors.ink)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Plot Twist")
        .accessibilityAddTraits(.isHeader)
        .onAppear {
            guard !turned else { return }
            if reduceMotion {
                turned = true
            } else {
                withAnimation(DS.Motion.twist.delay(0.35)) { turned = true }
            }
        }
    }
}

extension HorizontalAlignment {
    /// The line where PLOT starts and TWIST (upside down) ends.
    fileprivate enum Hinge: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[.leading] }
    }

    fileprivate static let hinge = HorizontalAlignment(Hinge.self)
}

#Preview {
    Wordmark()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsScreen()
        .dsDarkOnly()
}
