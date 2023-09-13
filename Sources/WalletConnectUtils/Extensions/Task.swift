import Foundation

public typealias CancellableTask = Task<Void, Never>

extension Task where Success == Void, Failure == Never {

    public final class DisposeBag {
        private var set: Set<Task> = []

        public init() { }

        func insert(task: Task) {
            set.insert(task)
        }

        deinit {
            set.forEach { $0.cancel() }
        }
    }

    public func store(in set: inout DisposeBag) {
        set.insert(task: self)
    }
}
