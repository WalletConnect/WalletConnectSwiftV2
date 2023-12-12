import Combine
import Foundation

public extension Sequence {
    func asyncForEach(_ operation: @escaping (Element) async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
            try await group.waitForAll()
        }
    }
}
