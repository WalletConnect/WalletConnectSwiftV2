import Foundation

class RecapFactory {
    static func createRecap(resource: String, actions: Set<String>) -> [String: [String: [String: [String]]]] {
        var recap: [String: [String: [String: [String]]]] = ["att": [:]]

        var resourceRecap: [String: [String]] = [:]

        for action in actions {
            resourceRecap[action] = []
        }

        recap["att"]![resource] = resourceRecap

        return recap
    }
}
