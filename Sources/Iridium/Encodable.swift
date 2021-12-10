// 

import Foundation

enum DataConversionError: Error {
    case dataToStringFailed
}

extension Encodable  {
    func json() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw DataConversionError.dataToStringFailed
        }
        return string
    }
}
