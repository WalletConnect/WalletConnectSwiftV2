import SwiftUI
import Web3ModalUI
import AsyncButton

struct NotificationsView: View {

    @EnvironmentObject var presenter: NotificationsPresenter

    @State var selectedIndex: Int = 0

    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            PreventCollapseView()
            List {
                Section {
                    if selectedIndex == 0 {
                        notifications()
                    } else {
                        discover()
                    }
                } header: {
                    HStack {
                        SegmentedPicker(["Notifications", "Discover"],
                                        selectedIndex: Binding(
                                            get: { selectedIndex },
                                            set: { selectedIndex = $0 ?? 0 }),
                                        content: { item, isSelected in
                            Text(item)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isSelected ? Color.primary : Color.secondary )
                                .padding(.trailing, 32)
                                .padding(.vertical, 8)
                        }, selection: {
                            VStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .fill(.Blue100)
                                    .frame(height: 2)
                                    .padding(.trailing, 32)
                            }
                        })
                    }
                    .animation(.easeInOut(duration: 0.3))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
        }
        .task {
            try? await presenter.fetch()
        }
    }

    private func discover() -> some View {
        return ForEach(presenter.listingViewModels) { listing in
            discoverListRow(listing: listing)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private func emptySubscriptionsView() -> some View {
        VStack(spacing: 10) {
            Spacer()

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

            Spacer()
        }
        .padding(20)
    }

    private func notifications() -> some View {
        ForEach(presenter.subscriptionViewModels, id: \.id) { subscription in
            subscriptionRow(subscription: subscription)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
        }
        .onDelete { indexSet in
            Task(priority: .high) {
                await presenter.removeSubscribtion(at: indexSet)
            }
        }
    }

    private func subscriptionRow(subscription: SubscriptionsViewModel) -> some View {
        Button {
            presenter.didPress(subscription: subscription)
        } label: {
            VStack {
                HStack(spacing: 10) {
                    CacheAsyncImage(url: subscription.imageUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .frame(width: 60, height: 60)
                                .background(Color.grey8.opacity(0.1))
                                .cornerRadius(30, corners: .allCorners)
                        } else {
                            Color.grey8.opacity(0.1)
                                .frame(width: 60, height: 60)
                                .cornerRadius(30, corners: .allCorners)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.name)
                            .foregroundColor(.Foreground100)
                            .font(.system(size: 15, weight: .medium, design: .rounded))

                        Text(subscription.subtitle)
                            .foregroundColor(.Foreground150)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }

                    Spacer()

                    if subscription.hasMessage {
                        VStack{
                            Text(String(subscription.messagesCount))
                                .foregroundColor(.Inverse100)
                                .font(.system(size: 13, weight: .medium).monospacedDigit())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }.background {
                            Capsule().foregroundColor(.blue100)
                        }
                    }
                }
            }
        }
    }

    private func discoverListRow(listing: ListingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                CacheAsyncImage(url: listing.imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .frame(width: 48.0, height: 48.0)
                            .background(Color.grey8.opacity(0.1))
                            .cornerRadius(30, corners: .allCorners)
                    } else {
                        Color.grey8.opacity(0.1)
                            .frame(width: 48.0, height: 48.0)
                            .cornerRadius(30, corners: .allCorners)
                    }
                }

                Spacer()

                if let subscription = presenter.subscription(forListing: listing) {
                    AsyncButton("Subscribed") {
                        try await presenter.unsubscribe(subscription: subscription)
                    }
                    .buttonStyle(W3MButtonStyle(size: .m, variant: .accent, rightIcon: .Checkmark))
                    .disabled(true)
                } else {
                    AsyncButton("Subscribe") {
                        try await presenter.subscribe(listing: listing)
                    }
                    .buttonStyle(W3MButtonStyle(size: .m))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(.paragraph700)
                    .foregroundColor(.Foreground100)

                Text(listing.appDomain ?? .empty)
                    .foregroundColor(.Foreground200)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }

            Text(listing.subtitle)
                .foregroundColor(.Foreground150)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .lineLimit(2)
        }
        .padding(16.0)
        .background(
            RadialGradient(gradient: Gradient(colors: [.Blue100.opacity(0.1), .clear]), center: .topLeading, startRadius: 0, endRadius: 300)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.grey95, lineWidth: 1)
        )
    }
}

private struct PreventCollapseView: View {

    private var mostlyClear = Color(UIColor(white: 0.0, alpha: 0.0005))

    var body: some View {
        Rectangle()
            .fill(mostlyClear)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 1)
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
#endif
