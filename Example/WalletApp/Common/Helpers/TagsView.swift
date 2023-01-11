import SwiftUI

private struct HeightPreferenceKey: PreferenceKey {
    static func reduce(value _: inout CGFloat, nextValue _: () -> CGFloat) {}
    static var defaultValue: CGFloat = 0
}

private struct HeightReaderView: View {
    @Binding var binding: CGFloat

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geo.frame(in: .local).size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { h in
            binding = h
        }
    }
}

public let tagsViewDefaultItemSpacing: CGFloat = 4

public struct TagsView<RefreshBinding, Data, ItemView: View>: View {
    @Binding var binding: RefreshBinding
    let items: [Data]
    let itemSpacing: CGFloat
    @ViewBuilder let viewMapping: (Data) -> ItemView
    
    @State private var totalHeight: CGFloat
    
    public init(
        binding: Binding<RefreshBinding>,
        items: [Data],
        itemSpacing: CGFloat = tagsViewDefaultItemSpacing,
        @ViewBuilder viewMapping: @escaping (Data) -> ItemView
    ) {
        _binding = binding
        self.items = items
        self.itemSpacing = itemSpacing
        self.viewMapping = viewMapping
        _totalHeight = State(initialValue: .zero)
    }
    
    public var body: some View {
        let stack = VStack {
            GeometryReader { geometry in
                self.content(in: geometry)
            }
        }
        return Group {
            stack.frame(height: totalHeight)
        }
    }
    
    private func content(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero
        let itemCount = items.count
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                viewMapping(item)
                    .padding([.horizontal, .vertical], itemSpacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= lastHeight
                        }
                        lastHeight = d.height
                        let result = width
                        if index == itemCount - 1 {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if index == itemCount - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(HeightReaderView(binding: $totalHeight))
    }
}

public extension TagsView where RefreshBinding == Never? {
    init(
        items: [Data],
        itemSpacing: CGFloat = tagsViewDefaultItemSpacing,
        @ViewBuilder viewMapping: @escaping (Data) -> ItemView
    ) {
        self.init(
            binding: .constant(nil),
            items: items,
            itemSpacing: itemSpacing,
            viewMapping: viewMapping
        )
    }
}
