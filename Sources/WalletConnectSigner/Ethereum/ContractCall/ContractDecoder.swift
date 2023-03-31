import Foundation

struct ContractDecoder {

    static func address(_ result: String, offset: String.Index? = nil) throws -> (String, String.Index) {
        guard let (s, end) = extractHexFragment(result, start: offset ?? index0x(result)) else {
            throw Errors.invalidAddress
        }
        let hex = s.suffix(from: s.index(s.startIndex, offsetBy: 24))
        return ("0x" + hex, end)
    }

    static func int(_ result: String, offset: String.Index? = nil) throws -> (Int, String.Index) {
        guard let (s, end) = extractHexFragment(result, start: offset ?? index0x(result)) else {
            throw Errors.invalidInt
        }
        return (Int(s, radix: 16)!, end)
    }

    static func string(_ result: String, at: Int) throws -> String {
        let data = try dynamicBytes(result, at: at)
        guard let string = String(data: data, encoding: .utf8) else {
            throw Errors.invalidString
        }
        return string
    }

    static func dynamicBytes(_ result: String, at: Int) throws -> Data {
        guard
            let i = index0x(result),
            let lengthStart = result.index(i, offsetBy: at * 2, limitedBy: result.endIndex),
            let (length, start) = try? ContractDecoder.int(result, offset: lengthStart),
            let end = result.index(start, offsetBy: length * 2, limitedBy: result.endIndex)
        else { throw Errors.invalidDynamicBytes }

        let s = result[start..<end]
        return Data(hex: String(s))
    }
}

private extension ContractDecoder {

    static func index0x(_ s: String) -> String.Index? {
        if s.starts(with: "0x") {
            return s.index(s.startIndex, offsetBy: 2)
        }
        return nil
    }

    static func extractHexFragment(_ s: String, start _start: String.Index? = nil) -> (String, String.Index)? {
        let start: String.Index
        if let i = _start {
            start = i
        } else if let i = index0x(s) {
            start = i
        } else {
            return nil
        }
        if let end = s.index(start, offsetBy: 64, limitedBy: s.endIndex) {
            return (String(s[start..<end]), end)
        }
        return nil
    }

    enum Errors: Error {
        case invalidAddress
        case invalidInt
        case invalidString
        case invalidDynamicBytes
    }
}
