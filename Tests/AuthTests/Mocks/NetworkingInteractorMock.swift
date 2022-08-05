import Foundation
import Combine
@testable import Auth

struct NetworkingInteractorMock: NetworkInteracting {
    let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    
    func subscribe(topic: String) async throws {
        
    }


}
