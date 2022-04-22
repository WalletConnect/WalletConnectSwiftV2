import Foundation

extension String {
    
    static let chainNamespaceRegex = "^[-a-z0-9]{3,8}$"
    static let chainReferenceRegex = "^[-a-zA-Z0-9]{1,32}$"
    static let accountAddressRegex = "^[a-zA-Z0-9]{1,64}$"
    
    // MARK: CAIP2
    static func conformsToCAIP2(_ string: String) -> Bool {
        guard let value: AccountCAIP2 = split(string) else {
            return false
        }
        let isNamespaceValid = (value.namespace.range(of: chainNamespaceRegex, options: .regularExpression) != nil)
        let isReferenceValid = (value.reference.range(of: chainReferenceRegex, options: .regularExpression) != nil)
        return isNamespaceValid && isReferenceValid
    }
    
    static func split(_ string: String) -> AccountCAIP2? {
        let splitted = string.split(separator: ":", omittingEmptySubsequences: false)
        let strings = splitted.map { String.init($0) }
        return strings.count == 2 ? (strings[0], strings[1]) : nil
    }
    
    // MARK: CAIP10
    static func conformsToCAIP10(_ string: String) -> Bool {
        guard let value: AccountCAIP10 = split(string) else {
            return false
        }
        let isNamespaceValid = (value.namespace.range(of: chainNamespaceRegex, options: .regularExpression) != nil)
        let isReferenceValid = (value.reference.range(of: chainReferenceRegex, options: .regularExpression) != nil)
        let isAddressValid = (value.address.range(of: accountAddressRegex, options: .regularExpression) != nil)
        return isNamespaceValid && isReferenceValid && isAddressValid
    }
    
    static func split(_ string: String) -> AccountCAIP10? {
        let splitted = string.split(separator: ":", omittingEmptySubsequences: false)
        let strings = splitted.map { String.init($0) }
        return strings.count == 3 ? (strings[0], strings[1], strings[2]): nil
    }
    
    static func generateTopic() -> String? {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData.toHexString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
}
