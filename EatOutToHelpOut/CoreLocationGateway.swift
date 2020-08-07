import Foundation
import CoreLocation

enum UserLocationGatewayStatus {
    case on, off, undefined
}

protocol UserLocationGateway {
    typealias FetchUserLocationStatusCompletion = (UserLocationGatewayStatus) -> Void
    func fetchUserLocationStatus(requestsAuthorisation: Bool, completion: @escaping FetchUserLocationStatusCompletion)
}

class CoreLocationGateway: NSObject, UserLocationGateway {

    var locationManager: CLLocationManager = CLLocationManager()
    var pendingLocationStatusCompletion: FetchUserLocationStatusCompletion?
    var authorisationStatus: CLAuthorizationStatus? = nil

    override init(){
        super.init()
        locationManager.delegate = self
    }

    func fetchUserLocationStatus(requestsAuthorisation: Bool, completion: @escaping FetchUserLocationStatusCompletion) {
        if let status = self.status {
            completion(status)
        }

        if (status == nil  || status == .undefined) && requestsAuthorisation {
            requestAuthorisation(completion: completion)
        }
    }

    func requestAuthorisation(completion: @escaping FetchUserLocationStatusCompletion) {
        pendingLocationStatusCompletion = completion
        locationManager.requestWhenInUseAuthorization()
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
        pendingLocationStatusCompletion?( status )
        pendingLocationStatusCompletion = nil
    }

}


extension CoreLocationGateway: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorisationStatus = status
        handlePendingPermissionRequest()
    }

}
