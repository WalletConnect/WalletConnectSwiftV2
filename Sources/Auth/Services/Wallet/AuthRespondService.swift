import Foundation

actor AuthRespondService {
    private let networkingInteractor: NetworkInteracting

    init(networkingInteractor: NetworkInteracting) {
        self.networkingInteractor = networkingInteractor
    }

    func respond(respondParams: RespondParams) async throws {

    }
}
