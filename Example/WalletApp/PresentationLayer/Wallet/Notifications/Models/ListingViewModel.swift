import Foundation

struct ListingViewModel: Identifiable {

    let listing: Listing

    var id: String {
        return listing.id
    }

    var imageUrl: URL? {
        return listing.image_url.md
    }

    var title: String {
        return listing.name
    }

    var subtitle: String {
        return listing.description
    }

    var url: String {
        return listing.homepage
    }
}
