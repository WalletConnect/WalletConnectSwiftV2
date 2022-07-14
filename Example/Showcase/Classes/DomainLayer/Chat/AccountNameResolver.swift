import Foundation

struct AccountNameResolver {

    private static var staticMap: [String: String] = [
        "swift.eth": "eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb",
        "kotlin.eth": "eip155:2:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb",
        "js.eth": "eip155:3:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb",
    ]

    static func resolveName(_ account: Account) -> String {
        return staticMap
            .first(where: { $0.value == account.absoluteString })?.key ?? account.absoluteString
    }

    static func resolveAccount(_ input: String) -> Account? {
        guard let value = staticMap[input.lowercased()] else {
            return Account(input)
        }

        return Account(value)!
    }
}
