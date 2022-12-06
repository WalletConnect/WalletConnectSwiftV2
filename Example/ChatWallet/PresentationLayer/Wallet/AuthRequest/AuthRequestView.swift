import SwiftUI

struct AuthRequestView: View {

    @EnvironmentObject var presenter: AuthRequestPresenter

    var body: some View {
        VStack(spacing: 16.0) {
            HStack {
                Text("Message to sign:")
                Spacer()
            }

            VStack {
                Text(presenter.message)
                    .font(Font.system(size: 13))
                    .padding(16.0)
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 16.0) {
                Button(action: { Task(priority: .userInitiated) { try await presenter.rejectPressed() }}, label: {
                    HStack(spacing: 8.0) {
                        Text("Reject")
                            .foregroundColor(.w_foreground)
                            .font(.system(size: 18, weight: .semibold))
                    }
                })
                .frame(width: 120, height: 44)
                .background(
                    Capsule()
                        .foregroundColor(.w_purpleForeground)
                )

                Button(action: { Task(priority: .userInitiated) { try await presenter.approvePressed() }}, label: {
                    HStack(spacing: 8.0) {
                        Text("Approve")
                            .foregroundColor(.w_foreground)
                            .font(.system(size: 18, weight: .semibold))
                    }
                })
                .frame(width: 120, height: 44)
                .background(
                    Capsule()
                        .foregroundColor(.w_greenForground)
                )
            }

            Spacer()
        }
        .padding(16.0)
    }
}
