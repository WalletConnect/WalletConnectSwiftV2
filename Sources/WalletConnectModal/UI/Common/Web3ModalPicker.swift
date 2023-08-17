import SwiftUI

struct Web3ModalPicker<Data, Content>: View where Data: Hashable, Content: View {
    let sources: [Data]
    let selection: Data?
    let itemBuilder: (Data) -> Content
    
    @State private var backgroundColor: Color = Color.black.opacity(0.05)
    
    func pickerBackgroundColor(_ color: Color) -> Web3ModalPicker {
        var view = self
        view._backgroundColor = State(initialValue: color)
        return view
    }
    
    @State private var cornerRadius: CGFloat?
    
    func cornerRadius(_ cornerRadius: CGFloat) -> Web3ModalPicker {
        var view = self
        view._cornerRadius = State(initialValue: cornerRadius)
        return view
    }
    
    @State private var borderColor: Color?
    
    func borderColor(_ borderColor: Color) -> Web3ModalPicker {
        var view = self
        view._borderColor = State(initialValue: borderColor)
        return view
    }
    
    @State private var borderWidth: CGFloat?
    
    func borderWidth(_ borderWidth: CGFloat) -> Web3ModalPicker {
        var view = self
        view._borderWidth = State(initialValue: borderWidth)
        return view
    }
    
    private var customIndicator: AnyView?
    
    init(
        _ sources: [Data],
        selection: Data?,
        @ViewBuilder itemBuilder: @escaping (Data) -> Content
    ) {
        self.sources = sources
        self.selection = selection
        self.itemBuilder = itemBuilder
    }
    
    public var body: some View {
        ZStack(alignment: .center) {
            if let selection = selection, let selectedIdx = sources.firstIndex(of: selection) {
                
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius ?? 6.0)
                        .stroke(borderColor ?? .clear, lineWidth: borderWidth ?? 0)
                        .foregroundColor(.accentColor)
                        .padding(EdgeInsets(top: borderWidth ?? 2, leading: borderWidth ?? 2, bottom: borderWidth ?? 2, trailing: borderWidth ?? 2))
                        .frame(width: geo.size.width / CGFloat(sources.count))
                        .animation(.spring().speed(1.5), value: selection)
                        .offset(x: geo.size.width / CGFloat(sources.count) * CGFloat(selectedIdx), y: 0)
                }.frame(height: 32)
            }
            
            HStack(spacing: 0) {
                ForEach(sources, id: \.self) { item in
                    itemBuilder(item)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius ?? 6.0)
                .fill(backgroundColor)
                .padding(-5)
        )
    }
}

struct PreviewWeb3ModalPicker: View {
    
    enum Platform: String, CaseIterable {
        case native
        case browser
    }
    
    @State private var selectedItem: Platform? = .native
    
    var body: some View {
        Web3ModalPicker(
            Platform.allCases,
            selection: selectedItem
        ) { item in
                
            HStack {
                Image(systemName: "iphone")
                Text(item.rawValue.capitalized)
            }
            .font(.system(size: 14).weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundColor(selectedItem == item ? .foreground1 : .foreground2)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItem = item
                }
            }
        }
        .pickerBackgroundColor(.background2)
        .cornerRadius(20)
        .borderWidth(1)
        .borderColor(.thinOverlay)
        .accentColor(.thinOverlay)
        .frame(maxWidth: 250)
        .padding()
    }
}

struct Web3ModalPicker_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWeb3ModalPicker()
    }
}
