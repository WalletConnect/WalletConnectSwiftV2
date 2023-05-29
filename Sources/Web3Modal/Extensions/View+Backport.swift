import SwiftUI
import Combine

struct Backport<Content> {
    let content: Content
}

extension View {
    var backport: Backport<Self> { Backport(content: self) }
}

extension Backport where Content: View {
    
    enum Visibility {
        case automatic
        case visible
        case hidden
    }
    
    @ViewBuilder func scrollContentBackground(_ visibility: Backport.Visibility) -> some View {
        if #available(iOS 16, *) {
            switch visibility {
            case .automatic:
                content.scrollContentBackground(.automatic)
            case .hidden:
                content.scrollContentBackground(.hidden)
            case .visible:
                content.scrollContentBackground(.visible)
            }
        } else {
            content
        }
    }
}

extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func onChangeBackported<T: Equatable>(of value: T, perform: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: perform)
        } else {
            self.onReceive(Just(value)) { (value) in
                perform(value)
            }
        }
    }
}


