import Foundation

protocol WebViewScript {
    var command: String { get }
    var params: [String: String]? { get }
}

extension WebViewScript {

    var params: [String: String]? {
        return nil
    }

    func build() -> String {
        let data = try! JSONEncoder().encode(params)
        let json = String(data: data, encoding: .utf8)!
        return "window.actions.\(command)(\(json))"
    }
}
