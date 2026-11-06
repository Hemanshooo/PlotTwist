import SwiftUI
import SwiftData

/// Your commonplace book: every line you've kept, newest first, each on its
/// own dog-eared slip. Tap one to share it as a card.
struct QuotesView: View {
    @Query(sort: \Quote.createdAt, order: .reverse) private var quotes: [Quote]
    @State private var keeping = false

    var body: some View {
        Group {
            if quotes.isEmpty {
                MessageView(
                    title: "Nothing kept yet",
                    message: "When a line stops you, keep it here, with its page. Share any of them as a card."
                ) {
                    SecondaryButton("Keep a line", systemImage: "plus") { keeping = true }
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DS.Space.m) {
                        ScreenTitle(
                            title: "Commonplace book",
                            detail: "^[\(quotes.count) line](inflect: true) you kept, from everything you read."
                        )
                        .padding(.bottom, DS.Space.s)
                        ForEach(quotes) { quote in
                            NavigationLink(value: quote) {
                                QuoteCard(quote: quote)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xxl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Quotes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            RootToolbar {
                AddButton(label: "Keep a line") { keeping = true }
            }
        }
        .sheet(isPresented: $keeping) { QuoteEditor(book: nil) }
        .dsScreen()
    }
}

/// A round outlined "+" for the top bar.
struct AddButton: View {
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .frame(width: DS.Size.navItem, height: DS.Size.navItem)
                .background(DS.Colors.canvas, in: Circle())
                .overlay { Circle().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }
}

#Preview {
    NavigationStack {
        QuotesView()
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
