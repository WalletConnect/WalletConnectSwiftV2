import SwiftUI

struct NotificationsView: View {

    @EnvironmentObject var presenter: NotificationsPresenter






    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        if presenter.subscriptions.isEmpty {
                            Spacer()
                            emptyView(size: geometry.size)
                            Spacer()
                        } else {
                            subscriptionsList()
                        }
                    }
                }
            }
            .onAppear {
                presenter.setupInitialState()
            }
        }
    }





    private func subscriptionsList() -> some View {
        ForEach(presenter.subscriptions) { subscription in
            Button(action: {
                presenter.didPress(subscription)
            }) {
                HStack(spacing: 16.0) {
                    Image("avatar")
                        .resizable()
                        .frame(width: 64.0, height: 64.0)

                    VStack(alignment: .leading) {
                        Text(subscription.title)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .lineLimit(1)

                        Text(subscription.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(height: 64.0)
            }
        }
        .padding(16.0)
    }



    private func emptyView(size: CGSize) -> some View {
        VStack(spacing: 8.0) {
            Text("It’s empty in here")
                .font(.system(.title3))
                .foregroundColor(.blue)

        }
        .frame(width: size.width)
        .frame(minHeight: size.height)
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
#endif
