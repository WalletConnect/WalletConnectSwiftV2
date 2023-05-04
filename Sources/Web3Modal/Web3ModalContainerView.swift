import SwiftUI

public struct Web3ModalContainerView: View {
        
    @Environment(\.presentationMode) var presentationMode
    
    @State var showModal: Bool = false
    
    public var body: some View {
        
        VStack(spacing: 0) {
            
            Color.black.opacity(0.3)
                .onTapGesture {
                    showModal = false
                }
            
            if showModal {
                Web3ModalSheet(destination: .welcome, isShown: $showModal)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showModal)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChangeBackported(of: showModal, perform: { newValue in
            if newValue == false {
                dismiss()
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


