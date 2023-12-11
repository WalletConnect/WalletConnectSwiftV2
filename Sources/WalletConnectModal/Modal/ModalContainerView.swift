import SwiftUI

struct ModalContainerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var showModal: Bool = false
        
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
            
            if showModal {
                ModalSheet(
                    viewModel: .init(
                        isShown: $showModal,
                        interactor: DefaultModalSheetInteractor()
                    )
                )
                .environment(\.projectId, WalletConnectModal.config.projectId)
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showModal)
            }
        }
        .background(
            Color.thickOverlay
                .colorScheme(.light)
                .opacity(showModal ? 1 : 0)
                .onTapGestureBackported {
                    withAnimation {
                        showModal = false
                    }
                }
        )
        .edgesIgnoringSafeArea(.all)
        .transform {
            #if os(iOS)
                if #available(iOS 14.0, *) {
                    $0.ignoresSafeArea(.keyboard, edges: .bottom)
                } else {
                    $0
                }
            #else
                $0
            #endif
        }
        .onChangeBackported(of: showModal, perform: { newValue in
            if newValue == false {
                withAnimation {
                    dismiss()
                }
            }
        })
        .onAppear {
            withAnimation {
                showModal = true
            }
        }
    }
    
    private func dismiss() {
        // Small delay so the sliding transition can happen before cross disolve starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
