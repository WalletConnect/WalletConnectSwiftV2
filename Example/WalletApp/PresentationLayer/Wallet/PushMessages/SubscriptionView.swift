import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject var presenter: SubscriptionPresenter

    var body: some View {
        VStack(spacing: 0) {
            List {
                headerView()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if !presenter.messages.isEmpty {
                    ForEach(presenter.messages, id: \.id) { pm in
                        notificationView(pushMessage: pm)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 32, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        presenter.deletePushMessage(at: indexSet)
                    }
                    Spacer().frame(height: 50.0)
                } else {
                    emptyStateView()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
        }
        .ignoresSafeArea(.container)
    }

    private func notificationView(pushMessage: NotifyMessageViewModel) -> some View {
        VStack(alignment: .center) {
            HStack(spacing: 10) {
                CacheAsyncImage(url: URL(string: pushMessage.imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .frame(width: 48, height: 48)
                            .background(Color.black)
                            .cornerRadius(10, corners: .allCorners)
                    } else {
                        Color.black
                            .frame(width: 48, height: 48)
                            .cornerRadius(10, corners: .allCorners)
                    }
                }
                .padding(.leading, 20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(pushMessage.title)
                            .foregroundColor(.primary)
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Text(pushMessage.publishedAt)
                            .foregroundColor(.grey50)
                            .font(.system(size: 11))
                    }

                    Text(pushMessage.subtitle)
                        .foregroundColor(.grey50)
                        .font(.system(size: 13))

                }
                .padding(.trailing, 20)
            }
        }
    }

    func headerView() -> some View {
        VStack(spacing: 0) {
            CacheAsyncImage(url: presenter.subscriptionViewModel.imageUrl) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .frame(width: 64, height: 64)
                } else {
                    Color.black
                        .frame(width: 64, height: 64)
                }
            }
            .clipShape(Circle())
            .padding(.top, 50.0)
            .padding(.bottom, 8.0)

            Text(presenter.subscriptionViewModel.name)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 8.0)

            Text(presenter.subscriptionViewModel.domain)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 16.0)

            Text(presenter.subscriptionViewModel.description)
                .font(.footnote)
                .foregroundColor(.primary)
                .padding(.bottom, 16.0)

            Menu {
                Button(role: .destructive, action: {
                    presenter.unsubscribe()
                }) {
                    Label("Unsubscribe", systemImage: "x.circle")
                }
            } label: {
                HStack(spacing: 16.0) {
                    Text("Subscribed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16.0)
                .padding(.vertical, 8.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.grey95, lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    func emptyStateView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.grey50)

            Text("Notifications from connected apps will appear here. To enable notifications, visit the app in your browser and look for a \(Image(systemName: "bell.fill")) notifications toggle \(Image(systemName: "switch.2"))")
                .foregroundColor(.grey50)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(20)
    }
}

#if DEBUG
struct PushMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}
#endif
