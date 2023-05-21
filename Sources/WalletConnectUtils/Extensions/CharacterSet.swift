import Foundation

extension CharacterSet {

    public static var rfc3986: CharacterSet {
        return .alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    }
}
