import Foundation
import WebKit

enum SearchRequestControllerRequestTarget {
    case webview, deny, safari, app, failed

}

struct DuckDuckGoSearchRequestController {

    static func action(request: URLRequest, type: WKNavigationType) -> SearchRequestControllerRequestTarget {

        guard request.url?.scheme != "tel" else { return .app}
        guard request.url?.scheme != "http" else { return .safari }
        guard request.url?.pathComponents.last != "post2.html" else { return .failed }
        guard request.url?.absoluteString != "about:blank" else { return .deny }
        
        switch type {
        case .other:
            return .webview
        case .linkActivated:
            return .safari
        default:
            return .deny
        }
    }

    static func isSearchRequestURL(_ url: URL?) -> Bool {
        return url?.host?.contains("duckduckgo.com") ?? false
    }

}
