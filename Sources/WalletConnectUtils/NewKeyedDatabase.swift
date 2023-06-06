import Foundation

public class NewKeyedDatabase<Element> where Element: Codable & Equatable {

    public var index: [String: Element] = [:] {
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
        return Array(index.values)
    }

    public func getElement(for key: String) -> Element? {
        return index[key]
    }

    public func set(element: Element, for key: String) {
        index[key] = element
    }
}

private extension NewKeyedDatabase {

    func initializeIndex() {
        guard
            let data =  storage.object(forKey: identifier) as? Data,
            let decoded = try? JSONDecoder().decode([String: Element].self, from: data)
        else { return }

        index = decoded
    }

    func set(_ value: [String: Element], for key: String) {
        let data = try! JSONEncoder().encode(value)
        storage.set(data, forKey: key)
    }
}
