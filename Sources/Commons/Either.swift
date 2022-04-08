enum Either<L, R> {
    case left(L)
    case right(R)
}

extension Either {

    init(_ left: L) {
        self = .left(left)
    }

    init(_ right: R) {
        self = .right(right)
    }

    var left: L? {
        guard case let .left(left) = self else { return nil }
        return left
    }

    var right: R? {
        guard case let .right(right) = self else { return nil }
        return right
    }
}

extension Either: Equatable where L: Equatable, R: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.left(lhs), .left(rhs)):
            return lhs == rhs
        case let (.right(lhs), .right(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Either: Codable where L: Codable, R: Codable {

    init(from decoder: Decoder) throws {
        if let left = try? L(from: decoder) {
            self.init(left)
        } else if let right = try? R(from: decoder) {
            self.init(right)
        } else {
            let errorDescription = "Data couldn't be decoded into either of the underlying types."
            let errorContext = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: errorDescription)
            throw DecodingError.typeMismatch(Self.self, errorContext)
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .left(left):
            try left.encode(to: encoder)
        case let .right(right):
            try right.encode(to: encoder)
        }
    }
}
