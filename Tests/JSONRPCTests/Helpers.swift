import Commons

extension Either where L == String, R == Int {
    
    var isString: Bool {
        left != nil
    }
    
    var isNumber: Bool {
        right != nil
    }
}
