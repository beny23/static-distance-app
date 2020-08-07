import UIKit
import WebKit

protocol WebViewControllerDataSource: AnyObject {

    var webViewURL: URL? { get }
    var searchTerm: String? { get }
}

private enum WebViewControllerError : Error {
    case DataSourceURLNotFound
}

class WebViewController : UIViewController {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityIndicicator: UIActivityIndicatorView!

    private var webSearchRedirectNavigationAction: WKNavigationAction?
    weak var dataSource: WebViewControllerDataSource?

    override func viewDidLoad() {
        configureWebView()
        configureLabel()
        loadURL()
    }

    override func viewDidAppear(_ animated: Bool) {
        guard let _ = dataSource?.webViewURL else {  dismiss(animated: true, completion: nil); return }
    }

    private func configureWebView() {
        webView.isHidden = true
        webView.navigationDelegate = self
    }

    private func configureLabel() {
        label.text = "Searching for \"\(dataSource?.searchTerm ?? "<<Error>>")\"..."
    }

    private func loadURL() {
        guard let url = dataSource?.webViewURL else { return }
        AppLogger.log(object: self, function: #function, message: "Load URL \(url)")
        let request = URLRequest(url: url)
        webView.load(request)
    }

    private func showWebView() {
        self.webView.isHidden = false
        self.activityIndicicator.stopAnimating()
        self.label.removeFromSuperview()
    }

    private func requestMatchesDataSourceURL(request: URLRequest) -> Bool {
        return request.url?.host == dataSource?.webViewURL?.host
    }

}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard navigationAction.navigationType == .other else { decisionHandler(.cancel); return }
        let isSearchEngineRedirect = requestMatchesDataSourceURL(request: navigationAction.request)
        let isSearchResultDestination = webSearchRedirectNavigationAction != nil && !isSearchEngineRedirect
        let policy: WKNavigationActionPolicy = ( isSearchEngineRedirect || isSearchResultDestination ) ? .allow : .cancel
        if isSearchEngineRedirect { webSearchRedirectNavigationAction = navigationAction } else { webSearchRedirectNavigationAction = nil }

        if policy == .cancel { AppLogger.log(object: self, function: #function, message: "FILTERED: \(String(describing: navigationAction.request.url?.host))")}

        decisionHandler(policy)

    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        AppLogger.log(object: self, function: #function, message: "WEBVIEW NAVIGATION: \(String(describing: navigationResponse.response.url?.host))")
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
        if !isProcessingSearchEngineRedirect { showWebView() }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
    }

    var isProcessingSearchEngineRedirect: Bool {
        return webSearchRedirectNavigationAction != nil
    }

    var didFinishNavigation: Bool {
        return !webView.isHidden
    }
    
}
