import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    let appContext = EatOutAppContext()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appContext.start()
        return true
    }

}

