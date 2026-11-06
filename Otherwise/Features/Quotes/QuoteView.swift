import SwiftUI
import SwiftData

/// One quote, ready to share: the card as it will look, in the shape and the
/// palette you choose, and the share button beneath. Your note and its book follow.
struct QuoteView: View {
    let quote: Quote

    @Environment(\.dismiss) private var dismiss
    @State private var format: QuoteFormat = .post
    @State private var palette: Palette = Theme.shared.palette
    @State private var rendered: UIImage?
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                preview
                controls
                if let rendered {
                    let image = Image(uiImage: rendered)
                    ShareLink(
                        item: image,
                        preview: SharePreview(Text(verbatim: quote.title), image: image)
                    ) {
                        HStack(spacing: DS.Space.xs) {
                            Text("Share")
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .font(DS.Typography.label)
                        .foregroundStyle(DS.Colors.onInk)
                        .frame(maxWidth: .infinity, minHeight: DS.Size.button)
                        .background(DS.Colors.ink, in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                if !quote.note.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        SectionHeader("Your note")
                        Text(quote.note)
                            .font(DS.Typography.quote)
                            .foregroundStyle(DS.Colors.ink)
                            .lineSpacing(DS.Leading.relaxed)
                    }
                    .padding(.top, DS.Space.s)
                }
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader("From")
                    NavigationLink(value: quote.book) {
                        BookRow(book: quote.book)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.top, DS.Space.s)
            }
            .padding(.horizontal, DS.Space.screen)
            .frame(maxWidth: DS.Space.readingWidth)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Space.s)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
                    .font(DS.Typography.label)
            }
        }
        .sheet(isPresented: $editing) {
            QuoteEditor(book: quote.book, existing: quote) { dismiss() }
        }
        .task(id: renderKey) { render() }
        .dsScreen()
    }

    /// What the card depends on: re-rendered when any of it changes.
    private var renderKey: String {
        "\(format.rawValue)|\(palette.rawValue)|\(quote.text)|\(quote.page)"
    }

    private var preview: some View {
        let size = format.size
        return GeometryReader { proxy in
            let scale = proxy.size.width / size.width
            QuoteArt(quote: quote, palette: palette, format: format)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: size.height * scale, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                        .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
                }
        }
        .aspectRatio(size.width / size.height, contentMode: .fit)
        .animation(DS.Motion.standard, value: format)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("“\(quote.text)” \(quote.citation)"))
    }

    private var controls: some View {
        HStack(spacing: DS.Space.m) {
            ChoicePills(
                options: QuoteFormat.allCases.map { ChoicePills<QuoteFormat>.Option(id: $0, title: $0.title) },
                selection: format,
                onSelect: { format = $0 }
            )
            .frame(maxWidth: 180)
            Spacer(minLength: 0)
            HStack(spacing: DS.Space.xs) {
                ForEach(Palette.allCases) { option in
                    Button {
                        withAnimation(DS.Motion.quick) { palette = option }
                    } label: {
                        Swatch(palette: option, isSelected: option == palette)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(Text(option.name))
                    .accessibilityAddTraits(option == palette ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private func render() {
        let renderer = ImageRenderer(content: QuoteArt(quote: quote, palette: palette, format: format))
        renderer.scale = 3
        rendered = renderer.uiImage
    }
}

/// A palette as a small round swatch: its ground, with its bloom and stem as two dots.
private struct Swatch: View {
    let palette: Palette
    let isSelected: Bool

    var body: some View {
        let scheme = palette.scheme
        ZStack {
            Circle().fill(scheme.canvas)
            Circle().fill(scheme.stem).frame(width: 9, height: 9).offset(x: 3)
            Circle().fill(scheme.bloom).frame(width: 9, height: 9).offset(x: -3)
        }
        .frame(width: 30, height: 30)
        .overlay {
            Circle().strokeBorder(isSelected ? DS.Colors.ink : DS.Colors.hairline, lineWidth: isSelected ? 1.5 : DS.Size.hairline)
                .padding(isSelected ? -3 : 0)
        }
        .frame(width: DS.Size.touch - 6, height: DS.Size.touch)
        .contentShape(Rectangle())
    }
}
