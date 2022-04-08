public extension Int {
    static func random() -> Int {
        random(in: Int.min...Int.max)
    }
}

public extension Double {
    static func random() -> Double {
        random(in: 0...1)
    }
}
