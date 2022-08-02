import Commons

public typealias RPCID = Either<String, Int64>

public protocol IdentifierGenerator {
    func next() -> RPCID
}

struct IntIdentifierGenerator: IdentifierGenerator {

    func next() -> RPCID {
        return RPCID(Int64.random(in: Int64.min...Int64.max))
    }
}
