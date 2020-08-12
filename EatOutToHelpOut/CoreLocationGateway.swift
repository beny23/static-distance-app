import Foundation
import CoreLocation

enum UserLocationGatewayStatus {
    case on, off, undefined, initialising
}

protocol UserLocationGateway {
    typealias FetchUserLocationStatusCompletion = (UserLocationGatewayStatus) -> Void
    func fetchUserLocationStatus(requestsAuthorisation: Bool, completion: @escaping FetchUserLocationStatusCompletion)
}

class CoreLocationGateway: NSObject, UserLocationGateway {

    var locationManager: CLLocationManager?
    var pendingLocationStatusCompletion: FetchUserLocationStatusCompletion?
    var authorisationStatus: CLAuthorizationStatus? = nil

    override init() {
        super.init()
        createLocationManager()
    }

    func reset() {
        authorisationStatus = nil
        createLocationManager()
    }

    private func createLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }

    func fetchUserLocationStatus(requestsAuthorisation: Bool, completion: @escaping FetchUserLocationStatusCompletion) {

//        if let status = self.status {
//            AppLogger.log(object: self, function: #function, message: "Location Status \(status)")
//            completion(status)
//        }

        if (self.status == nil  || status == .undefined) && requestsAuthorisation {
            requestAuthorisation(completion: completion)
        } else if let status = self.status {
            AppLogger.log(object: self, function: #function, message: "Skipped Authorisation Check")
            completion(status )
        } else {
            AppLogger.log(object: self, function: #function, message: "Deferring update. Wainting for location manager status...")
            pendingLocationStatusCompletion = completion
        }
    }

    func requestAuthorisation(completion: @escaping FetchUserLocationStatusCompletion) {
        AppLogger.log(object: self, function: #function)
        pendingLocationStatusCompletion = completion
        locationManager?.requestWhenInUseAuthorization()
    }

    var status: UserLocationGatewayStatus? {

        guard let authorisationStatus = self.authorisationStatus else {
            return nil
        }

        switch authorisationStatus {
        case .authorizedWhenInUse:
            return .on
        case .authorizedAlways:
            return .on
        case .notDetermined:
            return .undefined
        default:
            return .off
        }

    }

    private func handlePendingPermissionRequest() {
        guard let status = self.status else { return }
        if let completion = pendingLocationStatusCompletion {
            completion( status )
            pendingLocationStatusCompletion = nil
        }
    }

}


extension CoreLocationGateway: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorisationStatus = status
        handlePendingPermissionRequest()
    }

}
