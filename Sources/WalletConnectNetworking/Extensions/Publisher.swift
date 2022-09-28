import Combine
import Foundation

extension Publisher {

    func asyncFilter(filter: @escaping (Output) async -> Bool) -> AnyPublisher<Output, Failure> {
        return flatMap { output in
            return Future<Output, Failure> { completion in
                Task(priority: .high) {
                    if await filter(output) {
                        completion(.success(output))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
