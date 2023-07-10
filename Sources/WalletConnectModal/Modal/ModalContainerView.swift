import SwiftUI

struct ModalContainerView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var showModal: Bool = false
        
    var body: some View {
        
        VStack(spacing: -10) {
            
            Color.thickOverlay
                .colorScheme(.light)
                .transform {
                    #if os(iOS)
                        $0.onTapGesture {
                            withAnimation {
                                showModal = false
                            }
                        }
                    #endif
                }
            
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
        .edgesIgnoringSafeArea(.all)
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
