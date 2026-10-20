import SwiftUI

extension View {
    /// Lists float on the room: no grouped chrome, no separators; each row is its own glass card.
    func dsList() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
    }

    /// Apply to every row inside a `dsList()`.
    func dsListRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: DS.Space.xxs, leading: DS.Space.screen, bottom: DS.Space.xxs, trailing: DS.Space.screen))
    }

    /// Section header inside a `dsList()`.
    func dsListHeader() -> some View {
        self
            .padding(.top, DS.Space.m)
            .padding(.bottom, DS.Space.xxs)
            .listRowInsets(EdgeInsets(top: 0, leading: DS.Space.screen, bottom: 0, trailing: DS.Space.screen))
    }
}
