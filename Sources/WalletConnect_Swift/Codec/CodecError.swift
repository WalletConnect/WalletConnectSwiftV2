//

import Foundation
extension AES_256_CBC_HMAC_SHA256_Codec {
    enum CodecError: Error {
        case stringToDataFailed(String)
        case dataToStringFailed(Data)
        case macAuthenticationFailed
    }
}
