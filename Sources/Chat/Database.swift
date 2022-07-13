import Foundation
import WalletConnectUtils

class Database<Element> {

    private var array = [Element]()
    private let keyValueStorage: KeyValueStorage
    private let identifier: String

    init(keyValueStorage: KeyValueStorage,
         identifier: String) {
        self.keyValueStorage = keyValueStorage
        self.identifier = identifier
        array = keyValueStorage.object(forKey: identifier) as? [Element] ?? [Element]()
    }

    deinit {
        keyValueStorage.set(array, forKey: identifier)
    }

    func filter(_ isIncluded: (Element) -> Bool) async -> [Element]? {
        return Array(self.array.filter(isIncluded))
    }

    func getAll() async -> [Element] {
        array
    }

    func add(_ element: Element) async {
        self.array.append(element)
    }

    func first(where predicate: (Element) -> Bool) async -> Element? {
        self.array.first(where: predicate)
    }
}
