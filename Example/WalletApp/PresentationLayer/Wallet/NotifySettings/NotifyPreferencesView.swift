import SwiftUI
import AsyncButton
import WalletConnectNotify

struct NotifyPreferencesView: View {

    @EnvironmentObject var viewModel: NotifyPreferencesPresenter

    var body: some View {
        List {
            VStack(spacing: 0) {
                Text("Notification Preferences")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 16.0)

                Text("for \(viewModel.subscriptionViewModel.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4.0)
            }
            .frame(maxWidth: .infinity)
            .alignmentGuide(.listRowSeparatorLeading) { _ in -50 }
            .listRowBackground(Color.clear)

            ForEach(Array(viewModel.preferences.enumerated()), id: \.offset) { i, preference in
                if let value = viewModel.subscriptionViewModel.scope[preference] {
                    preferenceRow(title: preference, value: value)
                        .listRowSeparator(i == viewModel.preferences.count-1 ? .hidden : .visible)
                        .listRowBackground(Color.clear)
                }
            }

            AsyncButton {
                try await viewModel.updateDidPress()
            } label: {
                Text("Update")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44.0)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .background(Color.blue100)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUpdateDisabled)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    private func preferenceRow(title: String, value: ScopeValue) -> some View {
        Toggle(isOn: .init(get: {
            viewModel.update[title]?.enabled ?? value.enabled
        }, set: { newValue in
            viewModel.update[title] = ScopeValue(description: value.description, enabled: newValue)
        })) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.primary)
                    .font(.system(size: 14, weight: .semibold))

                Text(value.description)
                    .foregroundColor(.grey50)
                    .font(.system(size: 13))
            }
        }
        .padding(8.0)
    }
}

#if DEBUG
struct NotifyPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotifyPreferencesView()
    }
}
#endif
