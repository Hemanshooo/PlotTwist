import SwiftUI

/// One book in the stack, and how far you've read it (nil if it isn't on your shelf).
struct StackItem: Identifiable, Hashable {
    let book: Book
    let progress: Double?
    var id: String { book.id }
}

/// Books laid back in a deep, endless stack, like records in a crate. Each shows its
/// title strip and a tilted cover; covers near the middle of the screen lie
/// almost flat, and open up toward the top and bottom as you scroll.
/// Pressing a book tips it up toward you; releasing picks it. Holding it
/// opens its manage sheet instead.
struct BookStack: View {
    let items: [StackItem]
    /// The book currently picked out of the stack: it's hidden here while it's
    /// in your hands, and every other book fades away.
    let pickedID: String?
    /// The picked book, its cover's frame (global, untilted) and its tilt.
    let onPick: (StackItem, CGRect, Double) -> Void
    /// The book was held: open its manage sheet.
    var onHold: (StackItem) -> Void = { _ in }
    /// Endless stacks only: asked for more books as the end comes into view.
    var onNearEnd: (() -> Void)? = nil
    var isLoadingMore = false
    var loadFailed = false

    @State private var viewport: CGRect = .zero

    /// How far a cover lies back, given where its top edge sits in the viewport.
    /// Flattest at the focus line just above centre, most open at the edges.
    nonisolated static func tilt(coverTop y: CGFloat, viewportHeight: CGFloat) -> Double {
        guard viewportHeight > 0 else { return -62 }
        let distance = min(abs(y / viewportHeight - 0.42) / 0.5, 1)
        return -(76 - 26 * distance)
    }

    var body: some View {
        GeometryReader { proxy in
            // Never negative: the first layout pass can propose a zero width.
            let coverWidth = max(min(proxy.size.width - DS.Size.stackInset * 2, 340), 0)
            let height = proxy.size.height
            // The last few books ask for more as they appear, so the next
            // page is usually there before you reach the end.
            let tail = Set(items.suffix(6).map(\.id))
            ScrollView {
                // Lazy, so an endless stack only builds the books near the screen.
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        StackRow(
                            item: item,
                            coverWidth: coverWidth,
                            viewportHeight: height,
                            isPicked: pickedID == item.id,
                            isFaded: pickedID != nil && pickedID != item.id
                        ) { coverFrame in
                            let tilt = Self.tilt(coverTop: coverFrame.minY - viewport.minY, viewportHeight: viewport.height)
                            onPick(item, coverFrame, tilt)
                        } onHold: {
                            onHold(item)
                        }
                        .onAppear {
                            if tail.contains(item.id) { onNearEnd?() }
                        }
                    }
                    if let onNearEnd {
                        StackFooter(isLoading: isLoadingMore, failed: loadFailed, onRetry: onNearEnd)
                            // Clear the last cover, which lies back below its strip.
                            .padding(.top, coverWidth * 0.8)
                            .onAppear { onNearEnd() }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Space.m)
                // Room below, so the last books can reach the middle of the screen.
                .padding(.bottom, height * 0.6)
            }
            .scrollIndicators(.hidden)
            // Books run cleanly to the bottom edge, with no fade behind the search field.
            .scrollEdgeEffectHidden(true, for: .bottom)
            .scrollDisabled(pickedID != nil)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { viewport = $0 }
        }
    }
}

// MARK: - The end of the stack

/// Below the last book while more are on their way, or a quiet retry if they couldn't load.
private struct StackFooter: View {
    let isLoading: Bool
    let failed: Bool
    let onRetry: () -> Void

    var body: some View {
        Group {
            if failed {
                Button(action: onRetry) {
                    Label("Couldn’t load more books. Try again", systemImage: "arrow.clockwise")
                        .font(DS.Typography.captionEmphasis)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .frame(minHeight: DS.Size.touch)
                }
                .buttonStyle(.plain)
            } else if isLoading {
                ProgressView()
                    .frame(minHeight: DS.Size.touch)
                    .accessibilityLabel("Loading more books")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - A book in the stack

private struct StackRow: View {
    let item: StackItem
    let coverWidth: CGFloat
    let viewportHeight: CGFloat
    let isPicked: Bool
    let isFaded: Bool
    let onPick: (CGRect) -> Void
    let onHold: () -> Void

    @State private var coverFrame: CGRect = .zero
    @State private var isPressed = false
    @State private var holds = 0

    var body: some View {
        // A tap takes the book out; holding it opens its manage sheet.
        // While a finger is down, the book tips up toward you.
        StackRowLabel(item: item, coverWidth: coverWidth, viewportHeight: viewportHeight, coverFrame: $coverFrame)
            .environment(\.stackPressed, isPressed)
            .onTapGesture { onPick(coverFrame) }
            .onLongPressGesture(minimumDuration: 0.45) {
                holds += 1
                onHold()
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
            .sensoryFeedback(.impact(weight: .medium), trigger: holds)
        // Each book takes one stride of space; its cover spills down under the next.
        .frame(height: DS.Size.stackStride, alignment: .top)
        // The picked book is drawn by the pull-out, so it vanishes here at once;
        // the others fade away together.
        .opacity(isPicked || isFaded ? 0 : 1)
        // The others wait a moment, so you see the book slide out from among them.
        .animation(isPicked ? nil : (isFaded ? DS.Motion.standard.delay(0.18) : DS.Motion.standard), value: isFaded)
        .animation(nil, value: isPicked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.book.title))
        .accessibilityValue(Text(item.book.author ?? ""))
        .accessibilityHint("Takes the book out")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPick(coverFrame) }
        .accessibilityAction(named: "Manage book") { onHold() }
    }
}

private struct StackRowLabel: View {
    let item: StackItem
    let coverWidth: CGFloat
    let viewportHeight: CGFloat
    @Binding var coverFrame: CGRect

    @Environment(\.stackPressed) private var isPressed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var edition: Edition { Edition.of(item.book) }

    var body: some View {
        let lift: Double = isPressed && !reduceMotion ? 20 : 0
        VStack(spacing: 0) {
            strip
            ScaledBookCover(book: item.book)
                .frame(width: coverWidth, height: coverWidth * 1.5)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { coverFrame = $0 }
                .visualEffect { content, proxy in
                    let top = proxy.frame(in: .scrollView(axis: .vertical)).minY
                    let tilt = BookStack.tilt(coverTop: top, viewportHeight: viewportHeight) + lift
                    return content.rotation3DEffect(
                        .degrees(tilt),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: DS.Depth.stack
                    )
                }
        }
        .scaleEffect(isPressed ? 1.03 : 1, anchor: .top)
        .animation(DS.Motion.tilt, value: isPressed)
    }

    /// The book's top edge, facing you: title, author, and your progress.
    private var strip: some View {
        HStack(spacing: DS.Space.xs) {
            Text(item.book.title.uppercased())
                .font(DS.Typography.stamp(11))
                .tracking(DS.Tracking.stamp * 0.7)
                .lineLimit(1)
                .layoutPriority(1)
            if let author = item.book.author {
                Text(author)
                    .font(DS.Typography.stampItalic(12))
                    .opacity(0.8)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if let progress = item.progress {
                Image(systemName: progress >= 0.999 ? "checkmark.seal.fill" : "bookmark.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(edition.foilColor)
        .padding(.horizontal, DS.Space.s)
        .frame(width: coverWidth, height: DS.Size.stackStrip)
        .background(edition.clothColor)
        .overlay(alignment: .bottom) {
            Rectangle().fill(edition.foilColor.opacity(0.6)).frame(height: DS.Size.hairline)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: DS.Radius.cover, topTrailingRadius: DS.Radius.cover, style: .continuous))
    }
}

// MARK: - Press

extension EnvironmentValues {
    /// True while a finger is down on a book in the stack.
    @Entry var stackPressed: Bool = false
}
