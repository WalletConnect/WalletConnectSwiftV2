struct FuncTest<T> {
    private(set) var values: [T] = []
    var wasCalled: Bool { !values.isEmpty }
    var wasNotCalled: Bool { !wasCalled }
    var callsCount: Int { values.count }
    var wasCalledOnce: Bool { values.count == 1 }
    var currentValue: T? { values.last }
    mutating func call(_ value: T) { values.append(value) }
    init() {}
}
