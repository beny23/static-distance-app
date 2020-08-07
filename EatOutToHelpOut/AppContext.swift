import UIKit

class EatOutAppContext {

    static let shared = EatOutAppContext()

    func start() {

        configureMainViewController()

    }

    private var mainViewController: EatOutMapViewController {

        let app = UIApplication.shared.delegate as! AppDelegate
        return app.mainViewController

    }

    private func configureMainViewController() {

        let gateway = EatOutNetworkGeoJSONGateway()
        let interactor = EatOutFinder(gateway: gateway)
        let mainViewController = self.mainViewController
        mainViewController.interactor = interactor
        interactor.outlet = mainViewController

    }

    func configureWebViewController(_ controller: WebViewController, source: WebViewControllerDataSource) {
        controller.dataSource = source
    }

}

extension AppDelegate {

    var mainViewController: EatOutMapViewController {

        return window!.rootViewController! as! EatOutMapViewController

    }

}

