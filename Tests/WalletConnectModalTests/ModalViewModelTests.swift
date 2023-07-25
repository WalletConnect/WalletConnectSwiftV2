import TestingUtils
@testable import WalletConnectModal
import XCTest

final class ModalViewModelTests: XCTestCase {
    private var sut: ModalViewModel!
    
    private var openURLFuncTest: FuncTest<URL>!
    private var canOpenURLFuncTest: FuncTest<URL>!
    private var expectation: XCTestExpectation!
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        openURLFuncTest = .init()
        canOpenURLFuncTest = .init()
        
        sut = .init(
            isShown: .constant(true),
            interactor: ModalSheetInteractorMock(listings: [
                Listing(id: "1", name: "Sample App", homepage: "https://example.com", order: 1, imageId: "1", app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: nil, universal: "https://example.com/universal")),
                Listing(id: "2", name: "Awesome App", homepage: "https://example.com/awesome", order: 2, imageId: "2", app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "awesomeapp://deeplink", universal: "https://awesome.com/awesome/universal")),
            ]),
            uiApplicationWrapper: .init(
                openURL: { url, _  in
                    self.openURLFuncTest.call(url)
                    self.expectation.fulfill()
                },
                canOpenURL: { url in
                    self.canOpenURLFuncTest.call(url)
                    self.expectation.fulfill()
                    return true
                }
            )
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        openURLFuncTest = nil
        canOpenURLFuncTest = nil
        try super.tearDownWithError()
    }

    func test_onWalletTapped() async throws {
        await sut.fetchWallets()
        await sut.createURI()
        
        XCTAssertEqual(sut.uri, "wc:foo@2?symKey=bar&relay-protocol=irn")
        
        XCTAssertEqual(sut.wallets.count, 2)
        XCTAssertEqual(sut.wallets.map(\.id), ["1", "2"])
        XCTAssertEqual(sut.wallets.map(\.name), ["Sample App", "Awesome App"])
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called")
        
        sut.onListingTap(sut.wallets[0])
        
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "https://example.com/universal/wc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn")!
        )
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called 2nd time")
        
        sut.onListingTap(sut.wallets[1])
        
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "awesomeapp://deeplinkwc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn")!
        )
    }
}
