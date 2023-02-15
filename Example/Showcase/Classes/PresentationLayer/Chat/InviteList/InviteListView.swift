import SwiftUI

struct InviteListView: View {

    @EnvironmentObject var presenter: InviteListPresenter

    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                    .frame(height: 16.0)

                ForEach(presenter.invites) { invite in
                    HStack(spacing: 16.0) {
                        Image("avatar")
                            .resizable()
                            .frame(width: 64.0, height: 64.0)

                        VStack(alignment: .leading) {
                            Text(invite.title)
                                .font(.title3)
                                .foregroundColor(.w_foreground)
                                .lineLimit(1)

                            Text(invite.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.w_secondaryForeground)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        if invite.showActions {
                            HStack(spacing: 8.0) {
                                PlainButton {
                                    try await presenter.didPressAccept(invite: invite)
                                } label: {
                                    Image("checkmark_icon")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }

                                PlainButton {
                                    try await presenter.didPressReject(invite: invite)
                                } label: {
                                    Image("cross_icon")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            }
                            .padding(4.0)
                            .background(
                                Capsule()
                                    .foregroundColor(.w_secondaryBackground)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.w_tertiaryBackground, lineWidth: 0.5)
                            )
                        } else {
                            Text(invite.statusTitle)
                                .font(.subheadline)
                                .foregroundColor(.w_secondaryForeground)
                        }
                    }
                    .frame(height: 64.0)
                }
                .padding(16.0)
            }
        }
    }
}

#if DEBUG
struct InviteListView_Previews: PreviewProvider {
    static var previews: some View {
        InviteListView()
    }
}
#endif
