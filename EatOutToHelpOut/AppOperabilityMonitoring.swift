import Foundation
import AppCenter
import AppCenterCrashes
import AppCenterAnalytics

enum  AppMonitoringService {
    case Analytics, CrashReporting
}

protocol AppMonitoring {
    static func register(for services: [AppMonitoringService])
}

extension AppMonitoring {
    static func register(for services: [AppMonitoringService]) {}
}

struct EatOutAppMonitoring: AppMonitoring {
    static var shared: AppMonitoring.Type { return MSAppCenterMonitoring.self }
}

class MSAppCenterMonitoring : AppMonitoring {

    static func register(for services: [AppMonitoringService]) {
        MSAppCenter.start(AppEnvironment.MSAppCenterSecret, withServices: Settings.Services(for: services))
    }

    private struct Settings  {
        static func Services(for services: [AppMonitoringService]) -> [AnyClass]  {
            return services.map { (s) -> AnyClass in
                switch s {
                case .Analytics:
                    return MSAnalytics.self
                case .CrashReporting:
                    return MSCrashes.self
                }
            }
        }
    }
}
