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
            interactor: ModalSheetInteractorMock(wallets: [
                Wallet(
                    id: "1",
                    name: "Sample App",
                    homepage: "https://example.com/cool",
                    imageId: "0528ee7e-16d1-4089-21e3-bbfb41933100",
                    order: 1,
                    mobileLink: "https://example.com/universal/",
                    desktopLink: "sampleapp://deeplink",
                    webappLink: "https://sample.com/foo/webapp",
                    appStore: ""
                ),
                Wallet(
                    id: "2",
                    name: "Awesome App",
                    homepage: "https://example.com/cool",
                    imageId: "5195e9db-94d8-4579-6f11-ef553be95100",
                    order: 2,
                    mobileLink: "awesomeapp://deeplink",
                    desktopLink: "awesomeapp://deeplink",
                    webappLink: "https://awesome.com/awesome/universal/",
                    appStore: ""
                ),
            ]),
            uiApplicationWrapper: .init(
                openURL: { url, _ in
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
        
        XCTAssertEqual(sut.uri, "wc:foo@2?symKey=bar&relay-protocol=irn&expiryTimestamp=1706001526")
        XCTAssertEqual(sut.wallets.count, 2)
        XCTAssertEqual(sut.wallets.map(\.id), ["1", "2"])
        XCTAssertEqual(sut.wallets.map(\.name), ["Sample App", "Awesome App"])
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called using native link")
        
        sut.navigateToDeepLink(wallet: sut.wallets[1], preferBrowser: false)
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "awesomeapp://deeplinkwc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn%26expiryTimestamp%3D1706001526")!
        )
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called using universal link")
        
        sut.navigateToDeepLink(wallet: sut.wallets[1], preferBrowser: false)
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "awesomeapp://deeplinkwc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn%26expiryTimestamp%3D1706001526")!
        )
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called using webapp link")
        
        sut.navigateToDeepLink(wallet: sut.wallets[1], preferBrowser: true)
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "https://awesome.com/awesome/universal/wc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn%26expiryTimestamp%3D1706001526")!
        )
        
        expectation = XCTestExpectation(description: "Wait for openUrl to be called using native link")
        
        sut.navigateToDeepLink(wallet: sut.wallets[1], preferBrowser: true)
        XCTWaiter.wait(for: [expectation], timeout: 3)
        
        XCTAssertEqual(
            openURLFuncTest.currentValue,
            URL(string: "https://awesome.com/awesome/universal/wc?uri=wc%3Afoo%402%3FsymKey%3Dbar%26relay-protocol%3Dirn%26expiryTimestamp%3D1706001526")!
        )
    }
}
