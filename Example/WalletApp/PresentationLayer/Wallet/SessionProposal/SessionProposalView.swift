import SwiftUI

struct SessionProposalView: View {
    @EnvironmentObject var presenter: SessionProposalPresenter
    
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
                    
                    Text(presenter.proposal.proposerName)
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.top, 10)
                    
                    Text("would like to connect")
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                    
                    Text(presenter.proposal.proposerName)
                        .foregroundColor(.grey50)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 8)
                    
                    sessionProposalView()
                    
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
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func sessionProposalView() -> some View {
        VStack {
            VStack(alignment: .leading) {
                Text(presenter.proposal.permissions.first?.chains.first ?? "Chain")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.whiteBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.grey70)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(.leading, 15)
                    .padding(.top, 9)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Methods")
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    
                    TagsView(items: presenter.proposal.permissions.first?.methods ?? []) {
                        Text($0)
                            .foregroundColor(.cyanBackround)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyanBackround.opacity(0.2))
                            .cornerRadius(10, corners: .allCorners)
                    }
                    .padding(10)
                }
                .background(Color.whiteBackground)
                .cornerRadius(20, corners: .allCorners)
                .padding(.horizontal, 5)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Events")
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    
                    TagsView(items: presenter.proposal.permissions.first?.events ?? []) {
                        Text($0)
                            .foregroundColor(.cyanBackround)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyanBackround.opacity(0.2))
                            .cornerRadius(10, corners: .allCorners)
                    }
                    .padding(10)
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
struct SessionProposalView_Previews: PreviewProvider {
    static var previews: some View {
        SessionProposalView()
    }
}
#endif
