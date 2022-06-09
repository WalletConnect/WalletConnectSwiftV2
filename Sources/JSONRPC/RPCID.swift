import Commons

public typealias RPCID = Either<String, Int>

public protocol IdentifierGenerator {
    func next() -> RPCID
}

struct IntIdentifierGenerator: IdentifierGenerator {
    
    func next() -> RPCID {
        return RPCID(Int.random(in: Int.min...Int.max))
    }
}
