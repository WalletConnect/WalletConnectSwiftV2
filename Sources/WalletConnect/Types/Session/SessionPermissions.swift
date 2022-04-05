struct JSONRPC: Codable, Equatable {
    fileprivate(set) var methods: Set<String>
}

struct Notifications: Codable, Equatable {
    let types: Set<String>
}
struct SessionPermissions: Codable, Equatable {


    private(set) var jsonrpc: JSONRPC
    let notifications: Notifications
    let controller: Participant?

    internal init(jsonrpc: JSONRPC, notifications: Notifications, controller: Participant? = nil) {
        self.jsonrpc = jsonrpc
        self.notifications = notifications
        self.controller = controller
    }

    public init(jsonrpc: JSONRPC, notifications: Notifications) {
        self.jsonrpc = jsonrpc
        self.notifications = notifications
        self.controller = nil
    }

    init(permissions: Session.Permissions) {
        self.jsonrpc = JSONRPC(methods: permissions.methods)
        self.notifications = Notifications(types: permissions.notifications)
        self.controller = nil
    }

    mutating func upgrade(with permissions: SessionPermissions) {
        jsonrpc.methods.formUnion(permissions.jsonrpc.methods)
    }
}
