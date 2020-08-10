import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    let appContext = EatOutAppContext()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerOperabilityMonitoringServices()
        appContext.start()
        return true
    }

    func registerOperabilityMonitoringServices() {
        #if RELEASE
        EatOutAppMonitoring.shared.register(for: [.CrashReporting, .Analytics])
        #endif
    }

}

