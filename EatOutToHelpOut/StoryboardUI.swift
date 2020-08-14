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

@IBDesignable class PaddedLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 7.0
    @IBInspectable var rightInset: CGFloat = 7.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }

    override var bounds: CGRect {
         didSet {
             // ensures this works within stack views if multi-line
             preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
         }
     }
}
