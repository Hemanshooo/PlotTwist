import SwiftUI

extension View {
    /// Lists sit directly on the paper: no grouped chrome, hairline separators.
    func dsList() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
    }

    /// Apply to every row inside a `dsList()`.
    func dsListRow() -> some View {
        self
            .listRowBackground(DS.Colors.canvas)
            .listRowSeparatorTint(DS.Colors.hairline)
            .listRowInsets(EdgeInsets(top: 0, leading: DS.Space.screen, bottom: 0, trailing: DS.Space.screen))
    }

    /// Section header inside a `dsList()`.
    func dsListHeader() -> some View {
        self
            .padding(.top, DS.Space.m)
            .padding(.bottom, DS.Space.xxs)
            .listRowInsets(EdgeInsets(top: 0, leading: DS.Space.screen, bottom: 0, trailing: DS.Space.screen))
    }
}
