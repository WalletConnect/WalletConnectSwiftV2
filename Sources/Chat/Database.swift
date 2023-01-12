import Foundation

class Database<Element> where Element: Codable {

    private var array = [Element]()
    private let keyValueStorage: KeyValueStorage
    private let identifier: String

    init(keyValueStorage: KeyValueStorage, identifier: String) {
        self.keyValueStorage = keyValueStorage
        self.identifier = identifier

        if let data =  keyValueStorage.object(forKey: identifier) as? Data,
            let decoded = try? JSONDecoder().decode([Element].self, from: data) {
                array = decoded
            }
        }

    func filter(_ isIncluded: (Element) -> Bool) -> [Element]? {
        return Array(array.filter(isIncluded))
    }

    func getAll() -> [Element] {
        array
    }

    func add(_ element: Element) {
        array.append(element)
        if let encoded = try? JSONEncoder().encode(array) {
            keyValueStorage.set(encoded, forKey: identifier)
        }
    }

    func first(where predicate: (Element) -> Bool) -> Element? {
        array.first(where: predicate)
    }
}
