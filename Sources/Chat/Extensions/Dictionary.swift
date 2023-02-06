import Foundation

extension Dictionary where Value: RangeReplaceableCollection, Value.Element: Equatable {

    mutating func append(_ element: Value.Iterator.Element, for key: Key) {
        var value: Value = self[key] ?? Value()
        value.append(element)
        self[key] = value
    }

    mutating func delete(_ element: Value.Iterator.Element, for key: Key) {
        guard
            let value: Value = self[key],
            value.contains(where: { $0 == element })
        else { return }

        self[key] = value.filter { $0 != element }
    }
}
