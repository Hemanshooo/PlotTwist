import SwiftUI

/// The one prominent action on a screen. Never more than one per screen.
/// On a book's screens it takes the book's edition ink; elsewhere the app accent.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var tint: Color
    var labelColor: Color
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        tint: Color = DS.Colors.accent,
        labelColor: Color = DS.Colors.onAccent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.labelColor = labelColor
        self.action = action
    }

    /// A primary button in a book's edition colours.
    init(_ title: LocalizedStringKey, systemImage: String? = nil, edition: Edition, action: @escaping () -> Void) {
        self.init(title, systemImage: systemImage, tint: edition.ink, labelColor: edition.onInk, action: action)
    }

    var body: some View {
        Button {
            pressCount += 1
            action()
        } label: {
            titleView
                .font(DS.Typography.emphasis)
                .frame(maxWidth: .infinity, minHeight: DS.Size.touch)
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
        .foregroundStyle(labelColor)
        .controlSize(.large)
        .sensoryFeedback(.impact(weight: .light), trigger: pressCount)
    }

    @State private var pressCount = 0

    @ViewBuilder private var titleView: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

/// Quiet, glass-backed action for everything that isn't the primary action.
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
            .frame(minHeight: DS.Size.touch)
            .padding(.horizontal, DS.Space.xs)
        }
        .buttonStyle(.glass)
        .foregroundStyle(DS.Colors.ink)
    }
}

#Preview {
    VStack(spacing: DS.Space.l) {
        PrimaryButton("Rewrite the story", systemImage: "wand.and.sparkles") {}
        PrimaryButton("Rewrite the story") {}.disabled(true)
        SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
    }
    .padding(DS.Space.screen)
    .dsScreen()
}
