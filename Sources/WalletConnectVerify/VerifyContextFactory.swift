
import Foundation

class VerifyContextFactory {
    public func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext {
        guard isScam != true else {
            return VerifyContext(
                origin: origin,
                validation: .scam
            )
        }
        if let origin, let originUrl = URL(string: origin), let domainUrl = URL(string: domain) {
            return VerifyContext(
                origin: origin,
                validation: (originUrl.host == domainUrl.host) ? .valid : .invalid
            )
        } else {
            return VerifyContext(
                origin: origin,
                validation: .unknown
            )
        }
    }
}
