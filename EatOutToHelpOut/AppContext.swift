import UIKit

class EatOutAppContext {

    static let shared = EatOutAppContext()
    let locationGateway = CoreLocationGateway()

    func start() {
        observeAppStateChanges()
        configureMainViewController()

    }

    private var mainViewController: EatOutMapViewController {

        let app = UIApplication.shared.delegate as! AppDelegate
        return app.mainViewController

    }

    private func configureMainViewController() {
        let interactor = EatOutFinder(gateway: EatOutGeoJSONGateway(), locationGateway: locationGateway )
        let mainViewController = self.mainViewController
        mainViewController.interactor = interactor
        interactor.outlet = mainViewController

    }

    func configureWebViewController(_ controller: WebViewController, source: WebViewControllerDataSource) {
        controller.dataSource = source
    }

    private func observeAppStateChanges() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (n) in
            AppLogger.log(object: self, function: #function, message: n.description)
            self.locationGateway.reset()
            self.mainViewController.interactor.load()
            self.mainViewController.interactor.updateUI()
        }
    }

}

extension AppDelegate {

    var mainViewController: EatOutMapViewController {

        return window!.rootViewController! as! EatOutMapViewController

    }

}

