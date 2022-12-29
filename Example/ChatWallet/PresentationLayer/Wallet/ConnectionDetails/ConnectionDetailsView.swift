import SwiftUI

struct ConnectionDetailsView: View {
    @EnvironmentObject var presenter: ConnectionDetailsPresenter

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Image("foundation")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .background(Color.black)
                        .cornerRadius(30, corners: .allCorners)
                        .padding(.bottom, 6)
                    
                    Text("Foundation")
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("foundation.app")
                        .foregroundColor(.grey50)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                
                VStack {
                    VStack(alignment: .leading) {
                        Text("IEP155:1")
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
                                Text("Accounts")
                                    .foregroundColor(.grey50)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                
                                Spacer()
                                
                                Button {
                                    // action
                                } label: {
                                    Text("Add Account")
                                        .foregroundColor(.blue100)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 10)
                            
                            VStack {
                                Text("eip:155:1:0xe5eFf13687819212d25665fdB6946613dA6195a501")
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
                                Text("Methods")
                                    .foregroundColor(.grey50)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 10)
                            
                            VStack {
                                Text("eip:155:1:0xe5eFf13687819212d25665fdB6946613dA6195a501")
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
                            
                            VStack {
                                Text("eip:155:1:0xe5eFf13687819212d25665fdB6946613dA6195a501")
                                    .foregroundColor(.cyanBackround)
                                    .font(.system(size: 13, weight: .regular))
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
                    .background(Color("grey95"))
                    .cornerRadius(25, corners: .allCorners)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Button {
                    // action
                } label: {
                    Text("Delete")
                        .foregroundColor(.lightForegroundNegative)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

#if DEBUG
struct ConnectionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionDetailsView()
    }
}
#endif
