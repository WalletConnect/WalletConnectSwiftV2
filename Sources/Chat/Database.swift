import Foundation

public class Database<Element> {

    private var array = [Element]()

    public init() { }

    public convenience init(_ array: [Element]) {
        self.init()
        self.array = array
    }

    public func filter(_ isIncluded: (Element) -> Bool) async -> Array<Element>? {
        return Array(self.array.filter(isIncluded))
    }

    public func getAll() async -> [Element] {
        array
    }

    func add(_ element: Element) async {
        self.array.append(element)
    }

    func first(where predicate: (Element) -> Bool) async -> Element? {
        self.array.first(where: predicate)
    }
}
