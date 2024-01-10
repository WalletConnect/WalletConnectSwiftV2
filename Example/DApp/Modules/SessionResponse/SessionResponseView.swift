import SwiftUI
import WalletConnectSign

struct SessionResponseView: View {

    @EnvironmentObject var presenter: SessionResponsePresenter

    var body: some View {
        ZStack {
            Color(red: 25/255, green: 26/255, blue: 26/255)
                .ignoresSafeArea()

            responseView(response: presenter.response)
        }
    }


    private func responseView(response: Response) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.02))

            VStack(spacing: 5) {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.gray.opacity(0.5))
                        .frame(width: 30, height: 4)

                }
                .padding(20)

                HStack {
                    Group {
                        if case RPCResult.error(_) = response.result {
                            Text("❌ Response")
                        } else {
                            Text("✅ Response")
                        }
                    }
                    .font(
                        Font.system(size: 14, weight: .medium)
                    )
                    .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                    .padding(12)

                    Spacer()

                    let record = Sign.instance.getSessionRequestRecord(id: response.id)!
                    Text(record.request.method)
                        .font(
                            Font.system(size: 14, weight: .medium)
                        )
                        .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                        .padding(12)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.02))

                    switch response.result {
                    case  .response(let response):
                        Text(try! response.get(String.self).description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)

                    case .error(let error):
                        Text(error.message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
        }
    }
}
