protocol RPCMethod {
    associatedtype Parameters
    var method: String { get }
    var params: Parameters { get }
}
