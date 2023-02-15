import SwiftUI

struct WelcomeView: View {

    @State private var offset: CGFloat = 0

    @EnvironmentObject var presenter: WelcomePresenter

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Image("LaunchScreen")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .scaledToFill()

                VStack {
                    Spacer()
                    Image("LaunchLogo")
                        .offset(y: offset)
                    Spacer()
                }

                VStack(spacing: 16) {
                    Text("Chat")
                        .foregroundColor(.w_greenForground)
                        .font(.system(size: 50.0, weight: .bold))

                    Text("Direct messaging between users, using their web3 wallets.")
                        .font(.title2)
                        .foregroundColor(.w_foreground)
                        .multilineTextAlignment(.center)

                    BrandButton(title: presenter.buttonTitle) {
                        try await presenter.didPressImport()
                    }

                    Text("By connecting your wallet you agree with our\nTerms of Service")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16.0)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                withAnimation(.spring()) {
                    offset = -(UIScreen.main.bounds.height / 4)
                }
            }
        }
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
#endif
