import Foundation

struct ListingViewModel: Identifiable {

    var id: String {
        return UUID().uuidString
    }

    var imageUrl: String {
        return ""
    }

    var title: String {
        return "Title"
    }

    var subtitle: String {
        return "Subtitle"
    }
}
