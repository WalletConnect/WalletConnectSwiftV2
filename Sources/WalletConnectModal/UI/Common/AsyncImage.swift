import Combine
import SwiftUI

struct AsyncImage<Content>: View where Content: View {
    final class Loader: ObservableObject {
        @Published var data: Data? = nil

        private var cancellables = Set<AnyCancellable>()

        init(_ url: URL?) {
            guard let url = url else { return }
            
            var request = URLRequest(url: url)
            request.setValue(ExplorerAPI.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue(WalletConnectModal.config?.metadata.name, forHTTPHeaderField: "Referer")
            
            URLSession.shared.dataTaskPublisher(for: request)
                .map(\.data)
                .map { $0 as Data? }
                .replaceError(with: nil)
                .receive(on: RunLoop.main)
                .sink(receiveValue: { data in
                    withAnimation {
                        self.data = data
                    }
                })
                .store(in: &cancellables)
        }
    }

    @ObservedObject private var imageLoader: Loader
    private let conditionalContent: ((Image?) -> Content)?

    init(url: URL?) where Content == Image {
        self.imageLoader = Loader(url)
        self.conditionalContent = nil
    }

    init<I, P>(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.imageLoader = Loader(url)
        self.conditionalContent = { image in
            if let image = image {
                return ViewBuilder.buildEither(first: content(image))
            } else {
                return ViewBuilder.buildEither(second: placeholder())
            }
        }
    }
    
    private var image: Image? {
        imageLoader.data
            .flatMap {
                #if canImport(UIKit)
                UIImage(data: $0)
                #elseif canImport(AppKit)
                NSImage(data: $0)
                #endif
            }
            .flatMap(Image.init)
    }

    var body: some View {
        if let conditionalContent = conditionalContent {
            conditionalContent(image)
        } else if let image = image {
            image
        }
    }
}
