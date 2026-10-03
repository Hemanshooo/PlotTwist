import SwiftUI

/// Cloth stamped with the edition's foil pattern, tiled to fill any size.
/// Used for covers, spines, and the header band of a book screen.
struct EditionPattern: View {
    let edition: Edition
    /// Size of one pattern tile in points. Covers use smaller tiles than headers.
    var tile: CGFloat = 18
    /// How strongly the foil reads against the cloth (0…1).
    var intensity: Double = 0.55

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(edition.clothColor))
            let foil = GraphicsContext.Shading.color(edition.foilColor.opacity(intensity))
            Self.draw(edition.pattern, in: &context, size: size, tile: tile, foil: foil)
        }
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private static func draw(
        _ pattern: Edition.Pattern,
        in context: inout GraphicsContext,
        size: CGSize,
        tile s: CGFloat,
        foil: GraphicsContext.Shading
    ) {
        let cols = Int(size.width / s) + 2
        let rows = Int(size.height / s) + 2
        let line = max(1, s * 0.09)

        func each(_ body: (_ x: CGFloat, _ y: CGFloat, _ row: Int, _ col: Int) -> Void) {
            for row in -1..<rows {
                for col in -1..<cols {
                    body(CGFloat(col) * s, CGFloat(row) * s, row, col)
                }
            }
        }

        switch pattern {
        case .dots:
            // Staggered polka dots.
            each { x, y, row, _ in
                let offset = row.isMultiple(of: 2) ? 0 : s / 2
                let r = s * 0.14
                context.fill(Path(ellipseIn: CGRect(x: x + offset - r, y: y - r, width: r * 2, height: r * 2)), with: foil)
            }

        case .waves:
            // Rows of gentle sine waves.
            for row in -1..<rows {
                var path = Path()
                let y = CGFloat(row) * s * 0.75
                path.move(to: CGPoint(x: -s, y: y))
                var x = -s
                while x <= size.width + s {
                    path.addQuadCurve(to: CGPoint(x: x + s / 2, y: y), control: CGPoint(x: x + s / 4, y: y - s * 0.28))
                    path.addQuadCurve(to: CGPoint(x: x + s, y: y), control: CGPoint(x: x + s * 0.75, y: y + s * 0.28))
                    x += s
                }
                context.stroke(path, with: foil, lineWidth: line)
            }

        case .lattice:
            // Diagonal trellis.
            var path = Path()
            let span = size.width + size.height
            var d: CGFloat = -size.height
            while d <= span {
                path.move(to: CGPoint(x: d, y: 0))
                path.addLine(to: CGPoint(x: d + size.height, y: size.height))
                path.move(to: CGPoint(x: d + size.height, y: 0))
                path.addLine(to: CGPoint(x: d, y: size.height))
                d += s
            }
            context.stroke(path, with: foil, lineWidth: line * 0.8)

        case .stars:
            // Four-pointed stars, staggered.
            each { x, y, row, _ in
                let offset = row.isMultiple(of: 2) ? 0 : s / 2
                let c = CGPoint(x: x + offset, y: y)
                let outer = s * 0.3, inner = s * 0.08
                var star = Path()
                for i in 0..<8 {
                    let angle = CGFloat(i) * .pi / 4 - .pi / 2
                    let r = i.isMultiple(of: 2) ? outer : inner
                    let p = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
                    if i == 0 { star.move(to: p) } else { star.addLine(to: p) }
                }
                star.closeSubpath()
                context.fill(star, with: foil)
            }

        case .chevrons:
            // Zig-zag rows, like lightning or a herringbone weave.
            for row in -1..<rows {
                var path = Path()
                let y = CGFloat(row) * s * 0.8
                path.move(to: CGPoint(x: -s, y: y))
                var x = -s
                var up = true
                while x <= size.width + s {
                    x += s / 2
                    path.addLine(to: CGPoint(x: x, y: y + (up ? -s * 0.25 : s * 0.25)))
                    up.toggle()
                }
                context.stroke(path, with: foil, style: StrokeStyle(lineWidth: line, lineJoin: .miter))
            }

        case .leaves:
            // Sprigs: pairs of tilted leaves, alternating direction.
            each { x, y, row, col in
                let offset = row.isMultiple(of: 2) ? 0 : s / 2
                let c = CGPoint(x: x + offset, y: y)
                let leaf = Path(ellipseIn: CGRect(x: -s * 0.08, y: -s * 0.2, width: s * 0.16, height: s * 0.4))
                let tilt: CGFloat = (row + col).isMultiple(of: 2) ? .pi / 5 : -.pi / 5
                for side in [-1.0, 1.0] {
                    let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: tilt * side)
                    context.fill(leaf.applying(t), with: foil)
                }
            }

        case .checks:
            // Gingham: alternate squares, plus a lighter overlap.
            each { x, y, row, col in
                guard (row + col).isMultiple(of: 2) else { return }
                context.fill(Path(CGRect(x: x, y: y, width: s / 2, height: s / 2)), with: foil)
            }
            var stripes = Path()
            for col in -1..<cols { stripes.addRect(CGRect(x: CGFloat(col) * s, y: 0, width: s / 2, height: size.height)) }
            context.opacity = 0.35
            context.fill(stripes, with: foil)
            context.opacity = 1

        case .scallops:
            // Overlapping half-circles: fish scales, bat wings, peacock feathers.
            for row in -1..<(rows * 2) {
                let y = CGFloat(row) * s * 0.5
                let offset = row.isMultiple(of: 2) ? 0 : s / 2
                for col in -1..<cols {
                    var arc = Path()
                    let cx = CGFloat(col) * s + offset
                    arc.addArc(center: CGPoint(x: cx, y: y), radius: s / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    context.stroke(arc, with: foil, lineWidth: line)
                }
            }

        case .diamonds:
            // Art-deco diamonds: an outline with a solid jewel inside.
            each { x, y, row, _ in
                let offset = row.isMultiple(of: 2) ? 0 : s / 2
                let c = CGPoint(x: x + offset, y: y)
                func diamond(_ r: CGFloat) -> Path {
                    var p = Path()
                    p.move(to: CGPoint(x: c.x, y: c.y - r))
                    p.addLine(to: CGPoint(x: c.x + r * 0.7, y: c.y))
                    p.addLine(to: CGPoint(x: c.x, y: c.y + r))
                    p.addLine(to: CGPoint(x: c.x - r * 0.7, y: c.y))
                    p.closeSubpath()
                    return p
                }
                context.stroke(diamond(s * 0.42), with: foil, lineWidth: line * 0.8)
                context.fill(diamond(s * 0.14), with: foil)
            }
        }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: DS.Space.m) {
            ForEach(Array(Edition.Pattern.allCases.enumerated()), id: \.offset) { index, pattern in
                let pair = Edition.palettes[index % Edition.palettes.count]
                VStack {
                    EditionPattern(edition: Edition(cloth: pair.cloth, foil: pair.foil, pattern: pattern))
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover))
                    Text(pattern.rawValue).font(DS.Typography.caption)
                }
            }
        }
        .padding()
    }
    .background(DS.Colors.canvas)
}
