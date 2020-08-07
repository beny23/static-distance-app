import UIKit
import WebKit

protocol WebViewControllerDataSource: AnyObject {

    var webViewURL: URL? { get }

}

class WebViewController : UIViewController {

    @IBOutlet weak var webView: WKWebView!

    weak var dataSource: WebViewControllerDataSource?

    override func viewDidLoad() {
        loadURL()
        webView.navigationDelegate = self
    }

    private func loadURL() {
        if let url = dataSource?.webViewURL {
            AppLogger.log(object: self, function: #function, message: "Load URL \(url)")
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
}
