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

    @IBOutlet var webView: WKWebView!
    @IBOutlet var label: UILabel!
    @IBOutlet var activityIndicicator: UIActivityIndicatorView!

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
        label.text = "Searching for \"\(dataSource?.searchTerm ?? "<<Error>>")\""
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

        let allow = isSearchRedirectOrResult(navigationAction)
        decisionHandler(allow ? .allow : .cancel)
        handleDialOut(navigationAction)

    }

    private func handleDialOut(_ navigationAction: WKNavigationAction) {
        let isDialRequest = navigationAction.request.url?.scheme == "tel"
        if isDialRequest {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil);
        }
    }

    private func isSearchRedirectOrResult(_ navigationAction: WKNavigationAction) -> Bool {
        let isSearchEngineRedirect = requestMatchesDataSourceURL(request: navigationAction.request)
        let isSearchResultPage = webSearchRedirectNavigationAction != nil && !isSearchEngineRedirect
        if isSearchEngineRedirect { webSearchRedirectNavigationAction = navigationAction } else { webSearchRedirectNavigationAction = nil }
        return ( isSearchEngineRedirect || isSearchResultPage )
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
