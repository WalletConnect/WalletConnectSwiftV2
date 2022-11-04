import Foundation

class Database<Element> where Element: Codable {

    private var array = [Element]()
    private let keyValueStorage: KeyValueStorage
    private let identifier: String

    init(keyValueStorage: KeyValueStorage,
         identifier: String) {
        self.keyValueStorage = keyValueStorage
        self.identifier = identifier
        if let data =  keyValueStorage.object(forKey: identifier) as? Data,
            let decoded = try? JSONDecoder().decode([Element].self, from: data) {
                array = decoded
            }
        }

    func filter(_ isIncluded: (Element) -> Bool) async -> [Element]? {
        return Array(self.array.filter(isIncluded))
    }

    func getAll() async -> [Element] {
        array
    }

    func add(_ element: Element) async {
        self.array.append(element)
        if let encoded = try? JSONEncoder().encode(array) {
            keyValueStorage.set(encoded, forKey: identifier)
        }
    }

    func first(where predicate: (Element) -> Bool) async -> Element? {
        self.array.first(where: predicate)
    }
}
