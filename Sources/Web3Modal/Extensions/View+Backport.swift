import SwiftUI
import Combine

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
