import SwiftUI
import Web3ModalUI

struct SubscriptionView: View {

    @EnvironmentObject var presenter: SubscriptionPresenter

    var body: some View {
        ZStack {
            VStack {
                RadialGradient(gradient: Gradient(colors: [.Blue100.opacity(0.1), .clear]), center: .topLeading, startRadius: 0, endRadius: 300)
                    .frame(height: 300)
                Spacer()
            }

            List {
                headerView()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                if !presenter.messages.isEmpty {
                    ForEach(presenter.messages, id: \.id) { pm in
                        notificationView(pushMessage: pm)
                            .listRowSeparator(.visible)
                            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        presenter.deletePushMessage(at: indexSet)
                    }
                } else {
                    emptyStateView()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                if presenter.isMoreDataAvailable {
                    lastRowView()
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
        }
        .ignoresSafeArea(.container)
        .safeAreaInset(edge: .bottom) { Spacer().frame(height: 50) }
    }

    private func notificationView(pushMessage: NotifyMessageViewModel) -> some View {
        VStack(alignment: .center) {
            HStack(spacing: 12) {
                CacheAsyncImage(url: presenter.messageIconUrl(message: pushMessage)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(10, corners: .allCorners)
                    } else {
                        Color.black
                            .opacity(0.05)
                            .frame(width: 48, height: 48)
                            .cornerRadius(10, corners: .allCorners)
                    }
                }
                .padding(.leading, 20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(pushMessage.title)
                            .foregroundColor(.Foreground100)
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Text(pushMessage.publishedAt)
                            .foregroundColor(.Foreground250)
                            .font(.system(size: 11))
                    }

                    Text(.init(pushMessage.subtitle))
                        .foregroundColor(.Foreground175)
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
            .padding(.top, 56.0)
            .padding(.bottom, 8.0)

            Group {
                Text(presenter.subscriptionViewModel.name)
                    .font(.large700)
                    .foregroundColor(.Foreground100)
                    .padding(.bottom, 8.0)

                Text(presenter.subscriptionViewModel.domain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.Foreground200)
                    .padding(.bottom, 16.0)

                Text(presenter.subscriptionViewModel.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.Foreground100)
                    .padding(.bottom, 16.0)
            }
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)

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
            .padding(.bottom, 20.0)
        }
        .frame(maxWidth: .infinity)
    }

    func emptyStateView() -> some View {
        VStack(spacing: 0) {
            Image("subscription_empty_icon")
                .padding(.bottom, 24)

            Text("You’re ready to go")
                .font(.large700)
                .foregroundColor(.Foreground100)
                .padding(.bottom, 8)

            Text("All new notifications will appear here.")
                .font(.paragraph500)
                .foregroundColor(.Foreground150)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 410)
    }

    func lastRowView() -> some View {
        VStack {
            switch presenter.loadingState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.bottom, 24)
            case .idle:
                EmptyView()
            }
        }
        .frame(height: 50)
        .onAppear {
            presenter.loadMoreMessages()
        }
    }
}

#if DEBUG
struct PushMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}
#endif
