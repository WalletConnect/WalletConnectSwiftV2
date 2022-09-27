
import Foundation

actor SetStore<T: Hashable> {
    private var store: Set<T> = Set()

    func insert(_ element: T) {
        store.insert(element)
    }

    @discardableResult func remove(_ element: T) -> T? {
        store.remove(element)
    }
}
