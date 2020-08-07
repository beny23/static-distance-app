import UIKit

class StoryboardSegueViewController: UIViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        prepare(segue: segue)
    }


    private func prepare(segue: UIStoryboardSegue) {

          guard let identifier = segue.identifier, let segueIdentifer = SegueIdentifier(rawValue: identifier) else { return }

          switch segueIdentifer {

          case .WebViewSegueIdentifier:
              let controller = segue.destination as! WebViewController
              let source = segue.source as! WebViewControllerDataSource
              EatOutAppContext.shared.configureWebViewController(controller, source: source)
          }

      }


}


enum SegueIdentifier : String {
    case WebViewSegueIdentifier
}
