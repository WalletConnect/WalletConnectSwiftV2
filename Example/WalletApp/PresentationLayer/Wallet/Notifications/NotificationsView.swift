import SwiftUI
import AsyncButton

struct NotificationsView: View {

    @EnvironmentObject var presenter: NotificationsPresenter

    @State var selectedIndex: Int = 0

    @ViewBuilder
    var body: some View {
        VStack {
            HStack {
                SegmentedPicker(["Notifications", "Discover"],
                                selectedIndex: Binding(
                                    get: { selectedIndex },
                                    set: { selectedIndex = $0 ?? 0 }),
                                content: { item, isSelected in
                    Text(item)
                        .font(.headline)
                        .foregroundColor(isSelected ? Color.primary : Color.secondary )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                },
                                selection: {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.primary)
                            .frame(height: 1)
                    }
                })
                .animation(.easeInOut(duration: 0.3))

                Spacer()
            }

            if selectedIndex == 0 {
                notifications()
            } else {
                discover()
            }
        }
        .task {
            try? await presenter.fetch()
        }
    }

    private func discover() -> some View {
        return List {
            ForEach(presenter.listings) { listing in
                discoverListRow(listing: listing)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .padding(.vertical, 20)
    }

    private func notifications() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                if presenter.subscriptions.isEmpty {
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

                VStack {
                    if !presenter.subscriptions.isEmpty {
                        List {
                            ForEach(presenter.subscriptions, id: \.id) { subscription in
                                subscriptionRow(subscription: subscription)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                Task(priority: .high) {
                                    await presenter.removeSubscribtion(at: indexSet)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
        }
        .padding(.vertical, 20)
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
                    .padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.name)
                            .foregroundColor(.grey8)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))

                        Text(subscription.subtitle)
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }

                    Spacer()

                    Image("forward-shevron")
                        .foregroundColor(.grey8)
                        .padding(.trailing, 20)
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
                    AsyncButton("Unsubscribe") {
                        try await presenter.unsubscribe(subscription: subscription)
                    }
                    .foregroundColor(.red)
                } else {
                    AsyncButton("Subscribe") {
                        try await presenter.subscribe(listing: listing)
                    }
                    .foregroundColor(.primary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .foregroundColor(.grey8)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                Text(listing.appDomain ?? .empty)
                    .foregroundColor(.grey50)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }

            Text(listing.subtitle)
                .foregroundColor(.grey50)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .lineLimit(2)
        }
        .padding(16.0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.grey95, lineWidth: 1)
        )
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
#endif
