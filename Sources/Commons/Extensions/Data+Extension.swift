import Foundation

// MARK: - Random data generation

public extension Data {
    
    static func randomBytes(count: Int) -> Data {
        var buffer = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &buffer)
        guard status == errSecSuccess else {
            fatalError("Failed to generate secure random data of size \(count).")
        }
        return Data(buffer)
    }
}
