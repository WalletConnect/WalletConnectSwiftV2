
import Foundation

//actor SetStore<T: Hashable> {
//    private var store: Set<T> = Set()
//
//    func insert(_ element: T) {
//        store.insert(element)
//    }
//
//    @discardableResult func remove(_ element: T) -> T? {
//        store.remove(element)
//    }
//
//    func contains(_ element: T) -> Bool {
//        return store.contains(element)
//    }
//}
class SetStore<T: Hashable> {
    private var store: Set<T> = Set()

    func insert(_ element: T) {
        store.insert(element)
    }

    @discardableResult func remove(_ element: T) -> T? {
        store.remove(element)
    }

    func contains(_ element: T) -> Bool {
        return store.contains(element)
    }
}
