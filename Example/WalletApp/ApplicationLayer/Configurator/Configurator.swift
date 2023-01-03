protocol Configurator {
    func configure()
}

extension Array where Element == Configurator {
    func configure() {
        forEach { $0.configure() }
    }
}
