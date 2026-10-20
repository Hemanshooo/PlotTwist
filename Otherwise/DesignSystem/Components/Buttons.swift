import SwiftUI

/// The one prominent action on a screen. Never more than one per screen.
///
/// A dark glass capsule lit from inside by a gradient that pools along its
/// bottom edge and spills onto the black below, like Opal's "Continue".
/// On a book's screens the light is the book's edition; elsewhere, twilight.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var colors: [Color]
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var pressCount = 0

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        colors: [Color] = DS.Gradients.twilightColors,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.colors = colors
        self.action = action
    }

    /// A primary button lit by a book's edition.
    init(_ title: LocalizedStringKey, systemImage: String? = nil, edition: Edition, action: @escaping () -> Void) {
        self.init(title, systemImage: systemImage, colors: edition.gradientColors, action: action)
    }

    var body: some View {
        Button {
            pressCount += 1
            action()
        } label: {
            titleView
                .font(DS.Typography.label)
                .foregroundStyle(isEnabled ? DS.Colors.ink : DS.Colors.inkTertiary)
                .frame(maxWidth: .infinity, minHeight: DS.Size.button)
                .contentShape(Capsule())
        }
        .buttonStyle(GlowButtonStyle(colors: isEnabled ? colors : [DS.Colors.inkTertiary, DS.Colors.inkTertiary]))
        .sensoryFeedback(.impact(weight: .light), trigger: pressCount)
    }

    @ViewBuilder private var titleView: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

/// The glass and the light inside a primary button.
struct GlowButtonStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let gradient = LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        return configuration.label
            .background {
                ZStack {
                    Capsule().fill(DS.Gradients.glass)
                    // The light pooling along the bottom edge.
                    Capsule()
                        .fill(gradient)
                        .blur(radius: 16)
                        .opacity(pressed ? 0.85 : 0.62)
                        .offset(y: 20)
                        .clipShape(Capsule())
                    // A faint wash across the whole glass.
                    Capsule().fill(gradient).opacity(0.08)
                }
            }
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: DS.Size.hairline
                )
            }
            // The glow spilling onto the black below.
            .background {
                Capsule()
                    .fill(gradient)
                    .blur(radius: 22)
                    .opacity(pressed ? 0.42 : 0.26)
                    .offset(y: 10)
                    .padding(.horizontal, DS.Space.l)
            }
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(DS.Motion.quick, value: pressed)
    }
}

/// Quiet glass capsule for everything that isn't the primary action.
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
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(DS.Typography.label)
            .foregroundStyle(DS.Colors.ink)
            .frame(minHeight: DS.Size.touch)
            .padding(.horizontal, DS.Space.l)
            .dsGlassCapsule()
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// A round glass button holding one icon (close, back, more).
struct GlassIconButton: View {
    let systemImage: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(DS.Typography.emphasis)
                .foregroundStyle(DS.Colors.ink)
                .frame(width: DS.Size.touch, height: DS.Size.touch)
                .background(DS.Colors.surface.opacity(0.8), in: Circle())
                .overlay { Circle().strokeBorder(DS.Gradients.glassEdge, lineWidth: DS.Size.hairline) }
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }
}

/// Any tappable card: it gives a little under your finger.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(DS.Motion.quick, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: DS.Space.l) {
        PrimaryButton("Rewrite the story", systemImage: "wand.and.sparkles") {}
        PrimaryButton("Rewrite the story") {}.disabled(true)
        SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
        GlassIconButton(systemImage: "xmark", label: "Close") {}
    }
    .padding(DS.Space.screen)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
