import Foundation

extension String {

    static let chainNamespaceRegex = "^[-a-z0-9]{3,8}$"
    static let chainReferenceRegex = "^[-a-zA-Z0-9_]{1,32}$"
    static let accountAddressRegex = "^[a-zA-Z0-9]{1,64}$"

    static func conformsToCAIP2(_ string: String) -> Bool {
        let splits = string.split(separator: ":", omittingEmptySubsequences: false)
        guard splits.count == 2 else { return false }
        let namespace = splits[0]
        let reference = splits[1]
        let isNamespaceValid = (namespace.range(of: chainNamespaceRegex, options: .regularExpression) != nil)
        let isReferenceValid = (reference.range(of: chainReferenceRegex, options: .regularExpression) != nil)
        return isNamespaceValid && isReferenceValid
    }

    static func conformsToCAIP10(_ string: String) -> Bool {
        let splits = string.split(separator: ":", omittingEmptySubsequences: false)
        guard splits.count == 3 else { return false }
        let namespace = splits[0]
        let reference = splits[1]
        let address = splits[2]
        let isNamespaceValid = (namespace.range(of: chainNamespaceRegex, options: .regularExpression) != nil)
        let isReferenceValid = (reference.range(of: chainReferenceRegex, options: .regularExpression) != nil)
        let isAddressValid = (address.range(of: accountAddressRegex, options: .regularExpression) != nil)
        return isNamespaceValid && isReferenceValid && isAddressValid
    }
}
