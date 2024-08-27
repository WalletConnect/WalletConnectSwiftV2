import Foundation

class VerifyContextFactory {

    private func ensureUrlHasScheme(_ urlString: String) -> String {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        } else {
            return "https://" + urlString
        }
    }

    public func createVerifyContext(origin: String?, domain: String, isScam: Bool?, isVerified: Bool?) -> VerifyContext {

        guard isScam != true else {
            return VerifyContext(
                origin: origin,
                validation: .scam
            )
        }

        // If isVerified is provided and is false, return unknown
        if let isVerified = isVerified, !isVerified {
            return VerifyContext(
                origin: origin,
                validation: .unknown
            )
        }

        // Ensure both origin and domain have a scheme
        let originWithScheme = origin.map { ensureUrlHasScheme($0) }
        let domainWithScheme = ensureUrlHasScheme(domain)

        if let originWithScheme, let originUrl = URL(string: originWithScheme), let domainUrl = URL(string: domainWithScheme) {
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

    public func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext {
        guard let redirectURL = URL(string: redirectUniversalLink), let domainURL = URL(string: domain) else {
            return VerifyContext(
                origin: domain,
                validation: .invalid
            )
        }

        let redirectHost = redirectURL.host?.lowercased() ?? ""
        let domainHost = domainURL.host?.lowercased() ?? ""

        if redirectHost.isEmpty || domainHost.isEmpty {
            return VerifyContext(
                origin: domain,
                validation: .invalid
            )
        }

        if redirectHost.hasSuffix(domainHost) && (redirectHost == domainHost || redirectHost.hasSuffix("." + domainHost)) {
            return VerifyContext(
                origin: domain,
                validation: .valid
            )
        } else {
            return VerifyContext(
                origin: domain,
                validation: .invalid
            )
        }
    }
}
