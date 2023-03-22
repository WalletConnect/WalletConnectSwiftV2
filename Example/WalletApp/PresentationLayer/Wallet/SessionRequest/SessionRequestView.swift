import SwiftUI

struct SessionRequestView: View {
    @EnvironmentObject var presenter: SessionRequestPresenter
    
    @State var text = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Image("header")
                        .resizable()
                        .scaledToFit()
                    
                    Text(presenter.sessionRequest.method)
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.top, 10)
                    
                    if presenter.message != "[:]" {
                        authRequestView()
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            Task(priority: .userInitiated) { try await
                                presenter.onReject()
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
                        
                        Button {
                            Task(priority: .userInitiated) { try await
                                presenter.onApprove()
                            }
                        } label: {
                            Text("Allow")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .padding(.vertical, 11)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .foregroundPositive,
                                            .lightForegroundPositive
                                        ]),
                                        startPoint: .top, endPoint: .bottom)
                                )
                                .cornerRadius(20)
                        }
                        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
                    }
                    .padding(.top, 25)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(34)
                .padding(.horizontal, 10)
                
                Spacer()
            }
            .alert(presenter.errorMessage, isPresented: $presenter.showError) {
                Button("OK", role: .cancel) {}
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func authRequestView() -> some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Message")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.whiteBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.grey70)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(.leading, 15)
                    .padding(.top, 9)
                
                VStack(spacing: 0) {
                    ScrollView {
                        Text(presenter.message)
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .frame(height: 250)
                }
                .background(Color.whiteBackground)
                .cornerRadius(20, corners: .allCorners)
                .padding(.horizontal, 5)
                .padding(.bottom, 5)

            }
            .background(.thinMaterial)
            .cornerRadius(25, corners: .allCorners)
        }
        .padding(.top, 30)
    }
}

#if DEBUG
struct SessionRequestView_Previews: PreviewProvider {
    static var previews: some View {
        SessionRequestView()
    }
}
#endif
