import SwiftUI

/// One action in a sheet: an icon, a title and a line of detail on a glass card.
/// Destructive actions are set in the caution colour, so they read as final.
struct ActionRow: View {
    let title: Text
    let systemImage: String
    var detail: Text?
    var isDestructive = false
    let action: () -> Void

    init(_ title: Text, systemImage: String, detail: Text? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.detail = detail
        self.isDestructive = isDestructive
        self.action = action
    }

    private var tint: Color { isDestructive ? DS.Colors.caution : DS.Colors.ink }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: DS.Space.s) {
                Image(systemName: systemImage)
                    .font(DS.Typography.label)
                    .foregroundStyle(tint)
                    .frame(width: DS.Size.touch - DS.Space.xs, height: DS.Size.touch - DS.Space.xs)
                    .background(tint.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    title
                        .font(DS.Typography.label)
                        .foregroundStyle(tint)
                        .lineLimit(2)
                    if let detail {
                        detail
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.inkSecondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DS.Space.s)
            .padding(.vertical, DS.Space.s)
            .frame(minHeight: DS.Size.touch)
            .dsGlass(cornerRadius: DS.Radius.m)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    VStack(spacing: DS.Space.xs) {
        ActionRow(Text("Remove from Read"), systemImage: "bookmark.slash", detail: Text("About 40% through. Later moments seal again.")) {}
        ActionRow(Text("Daisy never comes to tea"), systemImage: "trash", detail: Text("“Daisy stays in Louisville”"), isDestructive: true) {}
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
