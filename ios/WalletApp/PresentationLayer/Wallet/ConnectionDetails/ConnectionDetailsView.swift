import SwiftUI

struct ConnectionDetailsView: View {
    @EnvironmentObject var presenter: ConnectionDetailsPresenter

    var body: some View {
        ZStack {
            Color.grey100
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        AsyncImage(url: URL(string: presenter.session.peer.icons.first ?? "")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .background(Color.black)
                                    .cornerRadius(30, corners: .allCorners)
                            } else {
                                Color.black
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(30, corners: .allCorners)
                            }
                        }
                        .padding(.bottom, 6)
                        
                        Text(presenter.session.peer.name)
                            .foregroundColor(.grey8)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        Text(presenter.session.peer.url)
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 15)
                    
                    ForEach(presenter.session.namespaces.keys.sorted(), id: \.self) { namespace in
                        VStack {
                            VStack(alignment: .leading) {
                                Text(namespace)
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
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.top, 10)
                                    
                                    TagsView(items: presenter.accountReferences(namespace: namespace)) {
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
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text("Methods")
                                            .foregroundColor(.grey50)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.top, 10)
                                    
                                    TagsView(items: Array(presenter.session.namespaces[namespace]?.methods ?? [])) {
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
                            .background(Color("grey95"))
                            .cornerRadius(25, corners: .allCorners)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    }
                    
                    Button {
                        presenter.onDelete()
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
}

#if DEBUG
struct ConnectionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionDetailsView()
    }
}
#endif
