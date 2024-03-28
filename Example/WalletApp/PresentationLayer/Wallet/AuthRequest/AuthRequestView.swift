import SwiftUI

struct AuthRequestView: View {
    @EnvironmentObject var presenter: AuthRequestPresenter
    
    @State var text = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            
            VStack {
                Spacer()

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            presenter.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding()
                }

                VStack(spacing: 0) {
                    Image("header")
                        .resizable()
                        .scaledToFit()
                    
                    Text(presenter.request.payload.domain)
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.top, 10)
                    
                    Text("would like to connect")
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                    
                    if case .valid = presenter.validationStatus {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Text(presenter.request.payload.domain)
                                .foregroundColor(.grey8)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineSpacing(4)
                        }
                        .padding(.top, 8)
                    } else {
                        Text(presenter.request.payload.domain)
                            .foregroundColor(.grey8)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 8)
                    }
                    
                    switch presenter.validationStatus {
                    case .unknown:
                        verifyBadgeView(imageName: "exclamationmark.circle.fill", title: "Cannot verify", color: .orange)
                        
                    case .invalid:
                        verifyBadgeView(imageName: "exclamationmark.triangle.fill", title: "Invalid domain", color: .red)
                        
                    case .scam:
                        verifyBadgeView(imageName: "exclamationmark.shield.fill", title: "Security risk", color: .red)
                        
                    default:
                        EmptyView()
                    }
                    
                    authRequestView()
                    
                    Group {
                        switch presenter.validationStatus {
                        case .invalid:
                            verifyDescriptionView(imageName: "exclamationmark.triangle.fill", title: "Invalid domain", description: "This domain cannot be verified. Check the request carefully before approving.", color: .red)
                            
                        case .unknown:
                            verifyDescriptionView(imageName: "exclamationmark.circle.fill", title: "Unknown domain", description: "This domain cannot be verified. Check the request carefully before approving.", color: .orange)
                            
                        case .scam:
                            verifyDescriptionView(imageName: "exclamationmark.shield.fill", title: "Security risk", description: "This website is flagged as unsafe by multiple security providers. Leave immediately to protect your assets.", color: .red)
                            
                        default:
                            EmptyView()
                        }
                    }
                    
                    buttonGroup()

                    
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(34)
                .padding(.horizontal, 10)
                
                Spacer()
            }
        }
        .sheet(
            isPresented: $presenter.showSignedSheet,
            onDismiss: presenter.onSignedSheetDismiss
        ) {
            ConnectedSheetView(title: "Request is signed")
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func authRequestView() -> some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Messages")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(.leading, 15)
                    .padding(.top, 9)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(presenter.messages.enumerated()), id: \.offset) { _, messageTuple in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(messageTuple.0)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding([.top, .horizontal])

                                Text(messageTuple.1)
                                    .foregroundColor(.grey50)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .padding(.horizontal)
                                    .padding(.bottom)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 5)
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color(.systemBackground)) // Adjusted for theme compatibility
            .cornerRadius(25, corners: .allCorners)
        }
        .padding(.vertical, 30)
    }


    
    private func verifyBadgeView(imageName: String, title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: imageName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            
        }
        .padding(5)
        .background(color.opacity(0.15))
        .cornerRadius(10)
        .padding(.top, 8)
    }
    
    private func verifyDescriptionView(imageName: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: imageName)
                .font(.system(size: 20, design: .rounded))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                Text(description)
                    .foregroundColor(.grey8)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(20)
    }
    
    private func declineButton() -> some View {
        Button {
            Task(priority: .userInitiated) { await
                presenter.reject()
            }
        } label: {
            Text("Decline")
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .foregroundNegative,
                            .lightForegroundNegative
                        ]),
                        startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(20)
        }
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }
    
    private func allowButton() -> some View {
        Button {
            Task(priority: .userInitiated) { await
                presenter.approve()
            }
        } label: {
            Text(presenter.validationStatus == .scam ? "Proceed anyway" : "Sign Multi")
                .frame(maxWidth: .infinity)
                .foregroundColor(presenter.validationStatus == .scam ? .grey50 : .white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 11)
                .background(
                    Group {
                        if presenter.validationStatus == .scam {
                            Color.clear
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .foregroundPositive,
                                    .lightForegroundPositive
                                ]),
                                startPoint: .top, endPoint: .bottom
                            )
                        }
                    }
                )
                .cornerRadius(20)
        }
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }

    private func signOneButton() -> some View {
        Button {
            Task(priority: .userInitiated) {
                await presenter.signOne()
            }
        } label: {
            Text("Sign One")
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]), // Example gradient, adjust as needed
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .cornerRadius(20)
        }
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }

    // Adjusted layout to include the signOneButton
    private func buttonGroup() -> some View {
        Group {
            if case .scam = presenter.validationStatus {
                VStack(spacing: 20) {
                    declineButton()
                    signOneButton() // Place the "Sign One" button between "Decline" and "Allow"
                    allowButton()
                }
                .padding(.top, 25)
            } else {
                HStack {
                    declineButton()
                    signOneButton() // Include the "Sign One" button in the horizontal stack
                    allowButton()
                }
                .padding(.top, 25)
            }
        }
    }

}

#if DEBUG
struct AuthRequestView_Previews: PreviewProvider {
    static var previews: some View {
        AuthRequestView()
    }
}
#endif
