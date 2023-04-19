import SwiftUI

private enum FocusField: Hashable {
    case uriField
}

struct PasteUriView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var presenter: PasteUriPresenter
    
    @State private var text = ""

    var body: some View {
        ZStack {
            Color(red: 20/255, green: 20/255, blue: 20/255, opacity: 0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                VStack(spacing: 6) {
                    Text("Enter a WalletConnect URI")
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("To get the URI press the copy to clipboard button in wallet connection interfaces.")
                        .foregroundColor(.grey50)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.whiteBackground)
                        
                        HStack {
                            TextField("wc://a13aef...", text: $text)
                                .padding(.horizontal, 17)
                                .foregroundColor(.grey50)
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                            
                            Button {
                                text = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.systemGrayLight)
                            }
                            .padding(.trailing, 12)
                        }
                    }
                    .frame(height: 44)
                    .padding(.top, 20)
                    .ignoresSafeArea(.keyboard)
                    
                    Button {
                        presenter.onValue(text)
                        dismiss()
                    } label: {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .blue100,
                                        .blue200
                                    ]),
                                    startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
                    .disabled(text.isEmpty)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue100)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .padding(.top, 20)
                }
                .padding(20)
                .background(Color.lightBackground)
                .cornerRadius(34)
                .padding(.horizontal, 10)
            }
            .padding(.bottom, 20)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

#if DEBUG
struct PasteUriView_Previews: PreviewProvider {
    static var previews: some View {
        PasteUriView()
    }
}
#endif
