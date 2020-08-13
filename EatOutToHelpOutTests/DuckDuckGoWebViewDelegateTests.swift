import XCTest
@testable import EatOutToHelpOut

class DuckDuckGoWebViewDelegateTests: XCTestCase {

    var requestController: DuckDuckGoSearchRequestController!

    override func setUpWithError() throws {
        requestController = DuckDuckGoSearchRequestController()
    }

    func testUseWebViewForDuckDuckGoRequestInitialRequest() {
        let request = URLRequest(url: URL(string: "https://duckduckgo.com/?q=dogandduck")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .other), .webview)
    }

    func testUseWebViewForResultPageRequestRedirect() {
        let request = URLRequest(url: URL(string: "https://doganduck.com/")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .other), .webview)
    }

    func testOpenWithSafariForResultPageLinkClick() {
        let request = URLRequest(url: URL(string: "https://facebook.com/dogandduck")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .linkActivated), .safari)
    }

    func testOpenWithSafariNonSecureWebPageRedirect() {
        let request = URLRequest(url: URL(string: "http://www.dogandduck.com")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .other), .safari)
    }

    func testOpenWithAppTelephoneLink() {
        let request = URLRequest(url: URL(string:"tel://0777234567")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .linkActivated), .app)
    }

    func testRetryDuckDuckGoErrorPage() {
        let request = URLRequest(url: URL(string:"https://duckduckgo.com/post2.html")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .other), .failed)
    }

    func testDenyAboutPage() {
        let request = URLRequest(url: URL(string:"about:blank")!)
        XCTAssertEqual(DuckDuckGoSearchRequestController.action(request: request, type: .other), .deny)
    }

}
