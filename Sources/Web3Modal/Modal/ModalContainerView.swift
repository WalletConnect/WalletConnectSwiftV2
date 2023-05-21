import SwiftUI
import WalletConnectPairing

public struct ModalContainerView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var showModal: Bool = false
    
    let projectId: String
    let metadata: AppMetadata
    let webSocketFactory: WebSocketFactory
    
    public init(projectId: String, metadata: AppMetadata, webSocketFactory: WebSocketFactory) {
        self.projectId = projectId
        self.metadata = metadata
        self.webSocketFactory = webSocketFactory
    }
    
    public var body: some View {
        
        VStack(spacing: 0) {
            
            Color.thickOverlay
                .colorScheme(.light)
                .onTapGesture {
                    withAnimation {
                        showModal = false
                    }
                }
            
            if showModal {
                ModalSheet(
                    viewModel: .init(
                        isShown: $showModal,
                        projectId: projectId,
                        interactor: .init(projectId: projectId, metadata: metadata, webSocketFactory: webSocketFactory)
                    ))
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
