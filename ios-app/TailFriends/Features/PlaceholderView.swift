import SwiftUI

enum PlaceholderContent {
    static let title = "Tail Friends"
    static let message = "The iOS app shell is ready."
}

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(PlaceholderContent.title)
                .font(.title2)
                .accessibilityIdentifier("placeholder.title")

            Text(PlaceholderContent.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("placeholder.message")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
