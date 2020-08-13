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

    private var responseHttpStatusCode: Int?
    private var loadedURL: URL?

    weak var dataSource: WebViewControllerDataSource?

    override func viewDidLoad() {
        title = dataSource?.searchTerm?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "<<Unknown>>"
        configureWebView()
        configureLabel()
        loadURL()
    }

    @IBAction func openInSafari(_ sender: Any) {
        let url = loadedURL ?? dataSource?.webViewURL
        dismissAndOpenURL(url)
    }

    override func viewDidAppear(_ animated: Bool) {
        guard let _ = dataSource?.webViewURL else {dismissAndOpenURL(nil); return }
    }

    private func configureWebView() {
        webView.isHidden = true
        webView.navigationDelegate = self
    }

    private func configureLabel() {
        label.text = "Searching for \"\(self.title ?? "")\""
    }

    private func loadURL() {
        guard let url = dataSource?.webViewURL else { return }
        AppLogger.log(object: self, function: #function, message: "Load URL \(url)")
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5)
        webView.load(request)
    }

    private func showWebView() {
        AppLogger.log(object: self, function: #function)
        self.loadedURL = webView.url
        self.webView.isHidden = false
        self.label.isHidden = true
        self.activityIndicicator.stopAnimating()
    }

    private func showLabel(text: String, loading: Bool = true) {
        self.webView.isHidden = true
        self.label.isHidden = false
        if  (!loading) {  self.activityIndicicator.stopAnimating(); }
        self.label.text = text
    }

    private func fallbackToSafari(error: NSError) {
        let failingErrorURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        self.dismissAndOpenURL(failingErrorURL)
    }

    private func dismissAndOpenURL(_ url: URL?) {
        AppLogger.log(object: self, function: #function)
        dismiss(animated: true) {
            guard let url = url else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
        showLabel(text: error.localizedDescription, loading: false)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let target = DuckDuckGoSearchRequestController.action(request: request, type: navigationAction.navigationType)
        AppLogger.log(object: self, function: #function, message: "(1) Request:\(String(describing: request.url))")
        AppLogger.log(object: self, function: #function, message: "(2) Target:\(  String(reflecting:target) )")

        switch target {
        case .webview:
            decisionHandler(.allow)
            if ( DuckDuckGoSearchRequestController.isSearchRequestURL(request.url) == false  && !webViewHasContent ) { showLabel(text:"Loading...") }
        case .deny:
            decisionHandler(.cancel)
        case .safari:
            decisionHandler(.cancel)
            dismissAndOpenURL(request.url)
        case .app:
            decisionHandler(.cancel)
            dismissAndOpenURL(request.url)
        case .failed:
            decisionHandler(.cancel)
            showLabel(text:"Search is currently unavailable.\nTry opening with browser.", loading: false)
        }

    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response as? HTTPURLResponse
        responseHttpStatusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode ?? 0
        AppLogger.log(object: self, function: #function, message: "Navigation Response: \(String(describing: responseHttpStatusCode)) Host: \(  String(describing: response?.url?.host) ) ")
        if responseWasError {
            decisionHandler(.allow)
        } else {
            decisionHandler(.allow)
        }

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
        if responseWasSuccess && webViewHasContent {
            showWebView()
        } else if responseWasRedirect {
            waitForRedirect()
        } else {
              // uh-oh
        }
    }

    private func waitForRedirect() {
        () // no-op
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        AppLogger.log(object: self, function: #function, message: "\(String(describing: navigation))")
    }

    var responseWasSuccess: Bool {
        return checkResponseStatus(in: 200..<300)
    }

    var responseWasError: Bool {
        return checkResponseStatus(in: 400..<500)
    }

    var responseWasRedirect: Bool {
        return checkResponseStatus(in: 300..<400)
    }

    var webViewHasContent: Bool {
        return DuckDuckGoSearchRequestController.isSearchRequestURL(webView?.url) == false
    }

    private func checkResponseStatus(in range: Range<Int>) -> Bool {
        return range.contains(responseHttpStatusCode ?? -1)
    }

    
}
