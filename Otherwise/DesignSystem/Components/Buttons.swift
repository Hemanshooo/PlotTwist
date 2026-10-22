import SwiftUI

/// The one prominent action on a screen. Never more than one per screen.
///
/// A solid capsule in the ink with the label in mono, in the ground colour,
/// like Type Garden's white "Buy me a coffee" pill on black.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var pressCount = 0

    init(_ title: LocalizedStringKey, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button {
            pressCount += 1
            action()
        } label: {
            ButtonTitle(title: title, systemImage: systemImage)
                .foregroundStyle(isEnabled ? DS.Colors.onInk : DS.Colors.inkTertiary)
                .frame(maxWidth: .infinity, minHeight: DS.Size.button)
                .background(isEnabled ? DS.Colors.ink : DS.Colors.raised, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: pressCount)
    }
}

/// An outlined capsule with a mono label, for everything that isn't the primary action.
struct SecondaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    let action: () -> Void

    init(_ title: LocalizedStringKey, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ButtonTitle(title: title, systemImage: systemImage)
                .foregroundStyle(DS.Colors.ink)
                .frame(minHeight: DS.Size.touch)
                .padding(.horizontal, DS.Space.l)
                .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// A round outlined button holding one symbol (close, back).
struct CircleButton: View {
    let systemImage: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .frame(width: DS.Size.touch - 4, height: DS.Size.touch - 4)
                .background(DS.Colors.canvas, in: Circle())
                .overlay { Circle().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }
}

/// A button's title: mono, with an optional symbol after it.
private struct ButtonTitle: View {
    let title: LocalizedStringKey
    let systemImage: String?

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Text(title)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .font(DS.Typography.label)
        .lineLimit(1)
    }
}

/// Any tappable thing: it gives a little under your finger.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(DS.Motion.quick, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: DS.Space.l) {
        PrimaryButton("Rewrite from here", systemImage: "arrow.right") {}
        PrimaryButton("Rewrite from here") {}.disabled(true)
        SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
        CircleButton(systemImage: "xmark", label: "Close") {}
    }
    .padding(DS.Space.screen)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
