import Foundation

public protocol DatabaseObject: Codable & Equatable {
    var databaseId: String { get }
}

public class KeyedDatabase<Element> where Element: DatabaseObject {

    public typealias Index = [String: [String: Element]]

    public var index: Index = [:] {
        didSet {
            guard oldValue != index else { return }
            set(index, for: identifier)
            onUpdate?()
        }
    }

    private let storage: KeyValueStorage
    private let identifier: String

    public var onUpdate: (() -> Void)?

    public init(storage: KeyValueStorage, identifier: String) {
        self.storage = storage
        self.identifier = identifier

        initializeIndex()
    }

    public func getAll() -> [Element] {
        return index.values.reduce([]) { result, map in
            return result + map.values
        }
    }

    public func getAll(for key: String) -> [Element] {
        return index[key].map { Array($0.values) } ?? []
    }

    public func getElement(for key: String, id: String) -> Element? {
        return index[key]?[id]
    }

    public func find(id: String) -> (key: String, element: Element)? {
        guard
            let value = index.first(where: { $0.value[id] != nil }),
            let element = value.value[id]
        else { return nil }

        return (value.key, element)
    }

    @discardableResult
    public func set(elements: [Element], for key: String) -> Bool {
        var map = index[key] ?? [:]

        for element in elements {
            guard
                map[element.databaseId] == nil else { continue }
                map[element.databaseId] = element
        }

        index[key] = map

        return true
    }

    @discardableResult
    public func set(element: Element, for key: String) -> Bool {
        var map = index[key] ?? [:]

        guard
            map[element.databaseId] == nil else { return false }
            map[element.databaseId] = element

        index[key] = map

        return true
    }

    @discardableResult
    public func delete(id: String, for key: String) -> Bool {
        var map = index[key]

        guard
            map?[id] != nil else { return false }
            map?[id] = nil

        index[key] = map

        return true
    }

    @discardableResult
    public func deleteAll(for key: String) -> Bool {
        var map = index[key]

        guard index[key] != nil else { return false }

        index[key] = nil

        return true
    }
}

private extension KeyedDatabase {

    func initializeIndex() {
        guard
            let data =  storage.object(forKey: identifier) as? Data,
            let decoded = try? JSONDecoder().decode(Index.self, from: data)
        else { return }

        index = decoded
    }

    func set(_ value: Index, for key: String) {
        let data = try! JSONEncoder().encode(value)
        storage.set(data, forKey: key)
    }
}
