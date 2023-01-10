import SwiftUI

struct ScanView: View {
    @EnvironmentObject var presenter: ScanPresenter

    var body: some View {
        ZStack {
            ScanQR(onValue: { value in
                presenter.onValue(value)
                presenter.dismiss()
            }, onError: { error in
                presenter.onError(error)
                presenter.dismiss()
            })
            .ignoresSafeArea()

            VStack {
                ZStack {
                    Text("Scan the code")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    
                    HStack {
                        Spacer()

                        Button {
                            presenter.dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(.grey95)
                                .frame(width: 30, height: 30)
                        }
                    }
                    .padding(.trailing, 30)
                }
                
                Spacer()
            }
            .padding(.top, 24)
        }
        .navigationBarHidden(true)
    }
}

#if DEBUG
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}
#endif
