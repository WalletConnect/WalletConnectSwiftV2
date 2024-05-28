import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var presenter: ConfigPresenter

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 25/255, green: 26/255, blue: 26/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack {
                        Button {
                            presenter.cleanLinkModeSupportedWalletsCache()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clean Link Mode Supported Wallets Cache")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 25)
                                Spacer()
                            }
                            .background(Color(red: 95/255, green: 159/255, blue: 248/255))
                            .cornerRadius(16)
                        }
                        .padding(.top, 10)
                    }
                    .padding(12)
                }
                .padding(.bottom, 76)
                .onAppear {
                    presenter.onAppear()
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 25/255, green: 26/255, blue: 26/255),
                for: .navigationBar
            )
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
    }
}
