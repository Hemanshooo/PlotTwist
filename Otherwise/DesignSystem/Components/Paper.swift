import SwiftUI

// MARK: - Ornament

/// A printer's ornament: two rules and a lozenge. Separates sections the way
/// a book does, and sits under titles on covers.
struct Ornament: View {
    var color: Color = DS.Colors.inkTertiary
    var compact: Bool = false

    var body: some View {
        let rule = compact ? DS.Space.s : DS.Space.l
        let jewel = compact ? 4.0 : 6.0
        HStack(spacing: compact ? 3 : DS.Space.xxs + 1) {
            Rectangle().frame(width: rule, height: 0.75)
            Rectangle()
                .frame(width: jewel, height: jewel)
                .rotationEffect(.degrees(45))
            Rectangle().frame(width: rule, height: 0.75)
        }
        .foregroundStyle(color)
        .accessibilityHidden(true)
    }
}

// MARK: - Dog-eared page

/// A rectangle with its top-trailing corner folded down.
struct DogEarShape: Shape {
    var fold: CGFloat = DS.Size.fold

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The triangle of paper folded over at a dog-ear.
private struct FoldShape: Shape {
    var fold: CGFloat = DS.Size.fold

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.minY + fold))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
        p.closeSubpath()
        return p
    }
}

/// A sheet of paper with a dog-eared corner. Used for "what happened in the book":
/// the page the reader has marked.
struct PageCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(DS.Space.m)
            .padding(.trailing, DS.Space.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DogEarShape().fill(DS.Colors.surface))
            .overlay(DogEarShape().stroke(DS.Colors.hairline, lineWidth: DS.Size.hairline))
            .overlay(FoldShape().fill(DS.Colors.fold))
            .overlay(FoldShape().stroke(DS.Colors.hairline, lineWidth: DS.Size.hairline))
            .dsPageShadow()
    }
}

// MARK: - Raised capital

/// A paragraph that opens with a large initial in the book's ink,
/// the way chapters open in a printed book.
struct RaisedCapText: View {
    let text: String
    let ink: Color

    var body: some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first {
            let initial = Text(String(first)).font(DS.Typography.raisedCap).foregroundStyle(ink)
            let rest = Text(String(trimmed.dropFirst())).font(DS.Typography.reading).foregroundStyle(DS.Colors.ink)
            Text("\(initial)\(rest)")
                .lineSpacing(DS.Leading.reading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Ribbon bookmark

/// A ribbon with a swallow-tail end.
struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let notch = rect.width * 0.55
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - notch))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A satin ribbon bookmark. When `isPlaced` changes it drops into place
/// (or is pulled away) from its top edge.
struct BookmarkRibbon: View {
    var color: Color
    var isPlaced: Bool = true
    var width: CGFloat = DS.Size.ribbonWidth
    var length: CGFloat = DS.Size.ribbonLength

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RibbonShape()
            .fill(color)
            // Satin sheen down the middle.
            .overlay(
                LinearGradient(colors: [.white.opacity(0), .white.opacity(0.22), .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    .clipShape(RibbonShape())
            )
            .frame(width: width, height: length)
            .shadow(color: .black.opacity(0.18), radius: 1.5, x: 0, y: 1)
            .offset(y: isPlaced ? 0 : -length - 4)
            .opacity(reduceMotion && !isPlaced ? 0 : 1)
            .animation(reduceMotion ? DS.Motion.standard : DS.Motion.ribbon, value: isPlaced)
            .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var placed = true
    VStack(spacing: DS.Space.xl) {
        Ornament()
        PageCard {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow("In the book")
                Text("Darcy calls Elizabeth tolerable, but not handsome enough to tempt him.").dsReading()
            }
        }
        RaisedCapText(text: "It was a bright cold morning when the letter arrived.", ink: DS.Colors.accent)
        HStack {
            BookmarkRibbon(color: DS.Colors.accent, isPlaced: placed)
            Button("Toggle") { placed.toggle() }
        }
        .frame(height: 60, alignment: .top)
        .clipped()
    }
    .padding(DS.Space.screen)
    .dsScreen()
}
