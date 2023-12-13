import Foundation

public class RecapFactory {
    static public func createRecap(resource: String, actions: [String]) -> [String: [String: [String: [String]]]] {
        var recap: [String: [String: [String: [String]]]] = ["att": [:]]

        var resourceRecap: [String: [String]] = [:]

        for action in actions {
            resourceRecap[action] = []
        }

        recap["att"]![resource] = resourceRecap

        return recap
    }
}
