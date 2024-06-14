import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var presenter: ConfigPresenter
    @State private var copyAlert: Bool = false
    @State private var cacheCleanAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 25/255, green: 26/255, blue: 26/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Clean Cache Button
                        Button(action: {
                            presenter.cleanLinkModeSupportedWalletsCache()
                            cacheCleanAlert = true
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Clean Cache")
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Image(systemName: "trash")
                                        .foregroundColor(.white)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 16)

                                Text("Clean link mode supported wallets cache")
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 16)
                            }
                            .background(Color(red: 95/255, green: 159/255, blue: 248/255).opacity(0.2).cornerRadius(12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)

                        // Client ID Row
                        Button(action: {
                            UIPasteboard.general.string = presenter.clientId
                            copyAlert = true
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Client ID")
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.white)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 16)

                                Text(presenter.clientId)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 16)
                            }
                            .background(Color(red: 95/255, green: 159/255, blue: 248/255).opacity(0.2).cornerRadius(12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
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
        .alert("Cache cleaned successfully", isPresented: $cacheCleanAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Client ID copied to clipboard", isPresented: $copyAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
    }
}
