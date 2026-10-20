import SwiftUI

/// One book in the stack, and how far you've read it (nil if it isn't on your shelf).
struct StackItem: Identifiable, Hashable {
    let book: Book
    let progress: Double?
    var id: String { book.id }
}

/// Where a book was when you took it: the hinge between its cover and spine
/// (global coordinates), the slab's length, and how it lay.
struct SlabPose: Equatable {
    let hinge: CGPoint
    let length: CGFloat
    let coverAngle: Double
    let fog: Double
}

/// Books lying flat in a deep stack, spines toward you, as in a crate of
/// box sets. Each shows its spine and, depending on how far down the screen
/// it is, a little or more of its cover. Tapping a book takes it out;
/// holding it opens its manage sheet.
struct BookStack: View {
    let items: [StackItem]
    /// The book currently taken from the stack: it's hidden here while it's
    /// in your hands, and the others dim.
    let pickedID: String?
    let onPick: (StackItem, SlabPose) -> Void
    /// The book was held: open its manage sheet.
    var onHold: (StackItem) -> Void = { _ in }
    /// Endless stacks only: asked for more books as the end comes into view.
    var onNearEnd: (() -> Void)? = nil
    var isLoadingMore = false
    var loadFailed = false

    @State private var viewport: CGRect = .zero
    /// The books' response to scrolling: +1 while moving on through the stack
    /// (covers lift open, as if riffled), −1 while moving back (they lie
    /// flatter), 0 at rest. Changes only when scrolling starts, stops or
    /// turns around, and every book animates its own way to it.
    @State private var flutter: Double = 0
    @State private var direction: Double = 1
    @State private var isMoving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            // Never negative: the first layout pass can propose a zero width.
            let length = max(proxy.size.width - DS.Size.slabInset * 2, 0)
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
                            length: length,
                            viewportHeight: height,
                            flutter: flutter,
                            isPicked: pickedID == item.id,
                            isDimmed: pickedID != nil && pickedID != item.id
                        ) { hinge in
                            let fraction = (hinge.y - viewport.minY) / max(viewport.height, 1)
                            onPick(item, SlabPose(
                                hinge: hinge,
                                length: length,
                                coverAngle: Slab.coverAngle(atScreenFraction: fraction),
                                fog: Slab.fog(atScreenFraction: fraction)
                            ))
                        } onHold: {
                            onHold(item)
                        }
                        .onAppear {
                            if tail.contains(item.id) { onNearEnd?() }
                        }
                    }
                    if let onNearEnd {
                        StackFooter(isLoading: isLoadingMore, failed: loadFailed, onRetry: onNearEnd)
                            .padding(.top, DS.Space.l)
                            .onAppear { onNearEnd() }
                    }
                }
                .frame(maxWidth: .infinity)
                // The first spine sits just under the guidance line, with room for
                // the sliver of cover that lies back above it.
                .padding(.top, DS.Size.slabSpine + DS.Space.xl - DS.Size.slabStride)
                // Room below, so the last books can come up the screen.
                .padding(.bottom, height * 0.45)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .bottom)
            .scrollDisabled(pickedID != nil)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { old, new in
                guard abs(new - old) > 0.5 else { return }
                let next: Double = new > old ? 1 : -1
                guard next != direction else { return }
                direction = next
                if isMoving, !reduceMotion { flutter = next }
            }
            .onScrollPhaseChange { _, phase in
                isMoving = phase.isScrolling
                guard !reduceMotion else { return }
                flutter = phase.isScrolling ? direction : 0
            }
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
                SecondaryButton("Couldn’t load more books", systemImage: "arrow.clockwise", action: onRetry)
            } else if isLoading {
                ProgressView()
                    .tint(DS.Colors.accent)
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
    let length: CGFloat
    let viewportHeight: CGFloat
    let flutter: Double
    let isPicked: Bool
    let isDimmed: Bool
    let onPick: (CGPoint) -> Void
    let onHold: () -> Void

    @State private var hinge: CGPoint = .zero
    @State private var isPressed = false
    @State private var holds = 0

    private var edition: Edition { Edition.of(item.book) }

    var body: some View {
        let depth = Slab.depth(for: length)
        VStack(spacing: 0) {
            SlabCoverFace(book: item.book, length: length)
                .visualEffect { content, proxy in
                    let fraction = proxy.frame(in: .scrollView(axis: .vertical)).maxY / max(viewportHeight, 1)
                    let angle = Slab.coverAngle(atScreenFraction: fraction, flutter: flutter)
                    return content
                        .rotation3DEffect(
                            .degrees(Slab.coverRotation(angle)),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: DS.Depth.stack
                        )
                        .brightness(Slab.fog(atScreenFraction: fraction))
                }
            SlabSpineFace(book: item.book, length: length, progress: item.progress)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .global)
                    return CGPoint(x: frame.midX, y: frame.minY)
                } action: { hinge = $0 }
                .visualEffect { content, proxy in
                    let fraction = proxy.frame(in: .scrollView(axis: .vertical)).minY / max(viewportHeight, 1)
                    let angle = Slab.coverAngle(atScreenFraction: fraction, flutter: flutter)
                    return content
                        .rotation3DEffect(
                            .degrees(Slab.spineRotation(angle)),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .top,
                            perspective: DS.Depth.stack
                        )
                        .brightness(Slab.fog(atScreenFraction: fraction) * Slab.spineFog)
                }
                // The book's colour, glowing faintly on the black beneath it.
                .background {
                    Capsule()
                        .fill(edition.glow)
                        .frame(height: DS.Size.slabSpine * 0.6)
                        .blur(radius: 22)
                        .opacity(isPressed ? 0.55 : 0.28)
                        .offset(y: DS.Size.slabSpine * 0.55)
                        .padding(.horizontal, DS.Space.l)
                }
        }
        .frame(height: DS.Size.slabSpine + depth)
        // Each book answers the scroll on its own beat, top to bottom, so the
        // lift and the settle run down the stack like a ripple.
        .animation(flutterAnimation, value: flutter)
        // Each book takes one stride; its cover reaches up behind the book above.
        .frame(height: DS.Size.slabStride, alignment: .bottom)
        .contentShape(Rectangle())
        .brightness(isPressed ? 0.06 : 0)
        .animation(DS.Motion.quick, value: isPressed)
        .onTapGesture { onPick(hinge) }
        .onLongPressGesture(minimumDuration: 0.45) {
            holds += 1
            onHold()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
        .sensoryFeedback(.impact(weight: .medium), trigger: holds)
        // The picked book is drawn by the opening animation, so it leaves here at once;
        // the others dim behind it.
        .opacity(isPicked ? 0 : (isDimmed ? 0.25 : 1))
        .animation(isPicked ? nil : DS.Motion.standard, value: isDimmed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.book.title))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint("Opens the book")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPick(hinge) }
        .accessibilityAction(named: "Manage book") { onHold() }
    }

    /// Lifting is quick and smooth; settling back has a little bounce.
    private var flutterAnimation: Animation {
        let position = min(max(hinge.y / max(viewportHeight, 1), 0), 1.2)
        return (flutter == 0 ? DS.Motion.settle : DS.Motion.lift).delay(Double(position) * 0.12)
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if let author = item.book.author { parts.append(author) }
        if let progress = item.progress {
            parts.append(progress >= 0.999 ? String(localized: "Finished") : String(localized: "Reading"))
        }
        return parts.joined(separator: ", ")
    }
}
