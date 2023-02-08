import SwiftUI

struct NotificationsView: View {

    @EnvironmentObject var presenter: NotificationsPresenter


    var body: some View {
        ZStack {
            Color.grey100
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    if presenter.subscriptions.isEmpty {
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

                    VStack {
                        if !presenter.subscriptions.isEmpty {
                            List {
                                ForEach(presenter.subscriptions, id: \.id) { subscription in
                                    subscriptionsView(subscription: subscription)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
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
    }





    private func subscriptionsView(subscription: SubscriptionsViewModel) -> some View {
        Button {
            presenter.didPress(subscription)
        } label: {
            VStack {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: subscription.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .frame(width: 60, height: 60)
                                .background(Color.black)
                                .cornerRadius(30, corners: .allCorners)
                        } else {
                            Color.black
                                .frame(width: 60, height: 60)
                                .cornerRadius(30, corners: .allCorners)
                        }
                    }
                    .padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.title)
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
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
#endif
