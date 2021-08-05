import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WalletConnect_SwiftTests.allTests),
    ]
}
#endif
