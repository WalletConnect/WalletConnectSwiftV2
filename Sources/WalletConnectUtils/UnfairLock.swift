import Foundation

public final class UnfairLock {
    private var lock: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deallocate()
    }

    @discardableResult
    public func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try f()
    }
}
