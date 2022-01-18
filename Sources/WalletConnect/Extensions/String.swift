// 

import Foundation

extension String {
    
    static func conformsToCAIP2(_ string: String) -> Bool {
        let namespaceRegex = "^[-a-z0-9]{3,8}$"
        let referenceRegex = "^[-a-zA-Z0-9]{1,32}$"
        let splits = string.split(separator: ":", omittingEmptySubsequences: false)
        guard splits.count == 2 else { return false }
        let namespace = splits[0]
        let reference = splits[1]
        let isNamespaceValid = (namespace.range(of: namespaceRegex, options: .regularExpression) != nil)
        let isReferenceValid = (reference.range(of: referenceRegex, options: .regularExpression) != nil)
        return isNamespaceValid && isReferenceValid
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

extension String {
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }
}

extension String: GenericPasswordConvertible {
    
    init<D>(rawRepresentation data: D) throws where D : ContiguousBytes {
        let bytes = data.withUnsafeBytes { Data(Array($0)) }
        guard let string = String(data: bytes, encoding: .utf8) else {
            fatalError() // FIXME: Throw error
        }
        self = string
    }
    
    var rawRepresentation: Data {
        self.data(using: .utf8) ?? Data()
    }
}
