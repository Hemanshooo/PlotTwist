import SwiftUI
import SwiftData

/// Your "What if" stories, newest first. Tap one to read it; press and hold
/// for more. "Clear all" sits at the end.
struct WhatIfList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Version.createdAt, order: .reverse) private var versions: [Version]
    @State private var confirmClear = false

    var body: some View {
        Group {
            if versions.isEmpty {
                MessageView(
                    title: "No “What if” stories yet",
                    message: "Open a book, pick a moment on its map, and change what happens. Your stories are kept here."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ScreenTitle(title: "What if", detail: "^[\(versions.count) story](inflect: true) you changed the ending of.")
                            .padding(.bottom, DS.Space.m)
                        Hairline()
                        ForEach(versions) { version in
                            NavigationLink(value: version) {
                                VersionCard(version: version)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    remove([version])
                                } label: {
                                    Label("Remove this story", systemImage: "trash")
                                }
                            }
                            Hairline()
                        }
                        HStack {
                            Hint("tap to read · hold for more")
                            Spacer()
                            Button("Clear all", role: .destructive) { confirmClear = true }
                                .font(DS.Typography.label)
                                .foregroundStyle(DS.Colors.caution)
                                .frame(minHeight: DS.Size.touch)
                        }
                        .padding(.top, DS.Space.xs)
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xxl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear all “What if” stories?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear all", role: .destructive) { remove(versions) }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("All \(versions.count) stories will be deleted. Your books, diary and quotes stay. This can’t be undone.")
        }
        .dsScreen()
    }

    /// Deletes once any menu showing these stories has had time to close.
    private func remove(_ items: [Version]) {
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(DS.Motion.standard) {
                for item in items { modelContext.delete(item) }
            }
            Library.save(modelContext)
        }
    }
}
