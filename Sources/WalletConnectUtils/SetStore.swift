import Foundation

public class SetStore<T: Hashable>: CustomStringConvertible {

    private let concurrentQueue: DispatchQueue

    private var store: Set<T> = Set()

    public init(label: String) {
        self.concurrentQueue = DispatchQueue(label: label, attributes: .concurrent)
    }

    public func insert(_ element: T) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.store.insert(element)
        }
    }

    public func remove(_ element: T) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.store.remove(element)
        }
    }

    public func contains(_ element: T) -> Bool {
        var contains = false
        concurrentQueue.sync { [unowned self] in
            contains = store.contains(element)
        }
        return contains
    }

    public var description: String {
        return store.description
    }
}
