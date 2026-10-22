import SwiftUI

/// The swatch in the top bar: the current palette's bloom and stem, as two
/// overlapping dots in an outlined circle. Opens the palette sheet.
struct PaletteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(DS.Colors.stem).frame(width: 11, height: 11).offset(x: 3.5)
                Circle().fill(DS.Colors.bloom).frame(width: 11, height: 11).offset(x: -3.5)
            }
            .frame(width: DS.Size.navItem, height: DS.Size.navItem)
            .background(DS.Colors.canvas, in: Circle())
            .overlay { Circle().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
            .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Palette")
        .accessibilityHint("Changes the colours of the whole app")
    }
}

/// Choosing the room to read in. Each swatch shows its palette's ground,
/// type and garden; picking one recolours the whole app at once.
struct PaletteSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Eyebrow("Palette")
                    Text("Pick a room to read in")
                        .dsDisplay(DS.Typography.title)
                }
                Spacer()
                CircleButton(systemImage: "xmark", label: "Close") { dismiss() }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Space.s), GridItem(.flexible())], spacing: DS.Space.s) {
                ForEach(Palette.allCases) { palette in
                    PaletteSwatch(palette: palette, isSelected: palette == Theme.shared.palette) {
                        withAnimation(DS.Motion.palette) { Theme.shared.choose(palette) }
                    }
                }
            }
            Hint("the whole app changes with it")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.l)
        .dsScreen()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }
}

/// One palette, shown in its own colours: its ground, a rose and a leaf in
/// its garden colours, and "Aa" in its ink.
private struct PaletteSwatch: View {
    let palette: Palette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let scheme = palette.scheme
        let ink = GardenInk(stem: scheme.stem, bloom: scheme.bloom, petal: scheme.petal, ground: scheme.canvas)
        let shape = RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
        Button(action: action) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                HStack(alignment: .center, spacing: DS.Space.xs) {
                    Canvas { context, size in
                        let mid = CGPoint(x: size.width * 0.42, y: size.height / 2)
                        context.drawLeaf(at: CGPoint(x: mid.x + 4, y: mid.y + 2), angle: .degrees(-20), length: 17, ink: ink)
                        context.drawRose(at: mid, size: 20, seed: palette.rawValue.count, ink: ink)
                    }
                    .frame(width: 36, height: 28)
                    Spacer(minLength: 0)
                    Text(verbatim: "Aa")
                        .font(DS.Typography.heading)
                        .foregroundStyle(scheme.ink)
                }
                .padding(.horizontal, DS.Space.s)
                .frame(height: 64)
                .background(scheme.canvas, in: shape)
                .overlay { shape.strokeBorder(scheme.hairline, lineWidth: DS.Size.hairline) }
                Text(palette.name)
                    .font(DS.Typography.label)
                    .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.inkSecondary)
                    .padding(.horizontal, DS.Space.xxs)
            }
            .padding(DS.Space.xs)
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.m + DS.Space.xs, style: .continuous)
                    .strokeBorder(isSelected ? DS.Colors.ink : DS.Colors.hairline, lineWidth: isSelected ? 1.4 : DS.Size.hairline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text(palette.name))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { PaletteSheet() }
}
