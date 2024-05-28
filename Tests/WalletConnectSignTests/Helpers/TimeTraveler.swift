import Foundation

final class TimeTraveler {

    private(set) var referenceDate = Date()

    func generateDate() -> Date {
        return referenceDate
    }

    func travel(by timeInterval: TimeInterval) {
        referenceDate = referenceDate.addingTimeInterval(timeInterval)
    }

    static func dateByAdding(days: Int, to date: Date = Date(), in timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .day, value: days, to: date)!
    }
}
