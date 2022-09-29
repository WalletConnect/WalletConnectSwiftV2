
import Foundation

public actor SetStore<T: Hashable> {
    private var store: Set<T> = Set()

    public init(){}

    public func insert(_ element: T) {
        store.insert(element)
    }

    @discardableResult public func remove(_ element: T) -> T? {
        store.remove(element)
    }

    public func contains(_ element: T) -> Bool {
        return store.contains(element)
    }

}
