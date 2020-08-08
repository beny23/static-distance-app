import Foundation
import MapKit


enum EatOutFinderDownloadStateUI {
    case loading, finished
}

enum UserLocationButtonUI {
    case disabled, normal, hilighted
}

protocol EatOutFinderOutlet: AnyObject {
    func show(_ : ErrorUI)
    func show(_ : [EatOutFinderItemUI])
    func show(_ : URL, title: String)
    func show(_ : EatOutFinderDownloadStateUI)
    func show(_ : UserLocationButtonUI)
    func showUserCurrentLocationOnMap()
}

enum EatOutFinderDataError: Error {

    case FetchUnexpectedError

    var localizedDescription: String {
        switch self {
        case .FetchUnexpectedError:
            return "An unexpected error occured loading data. Try again later."
        }
    }

    var localizedTitle: String {
        return "Data Error"
    }

    func errorUI(action: @escaping ErrorUI.ErrorUIAction) -> ErrorUI {
        return ErrorUI(message: self.localizedDescription, title: self.localizedTitle, defaultActionTitle: "OK", errorActionHandler: action)
    }

}

// MARK: - Interactor

protocol EatOutFinderGateway: AnyObject {

    typealias FetchLocationsCompletion = ([EatOutLocationEntity]?, Error?) -> Swift.Void

    func fetchLocations(completion: @escaping FetchLocationsCompletion)

}

class EatOutFinderItemUI: NSObject {

    let coordinate: CLLocationCoordinate2D
    let name: String
    let poscode: String

    fileprivate init(entity: EatOutLocationEntity) {
        self.coordinate = CLLocationCoordinate2D(latitude: entity.coordinate.lat, longitude: entity.coordinate.long)
        self.name = entity.name
        self.poscode = entity.postcode
    }

}

fileprivate extension EatOutFinderItemUI {
    var searchURL: URL {
        let host =  URL(string: "https://duckduckgo.com")!
        var components = URLComponents(url: host, resolvingAgainstBaseURL: true)!
        components.queryItems = [ URLQueryItem(name: "q", value: "\\\(self.name) \(self.poscode)") ]
        return components.url!
    }
}

class EatOutFinder {

    weak var outlet: EatOutFinderOutlet?

    let gateway: EatOutFinderGateway
    let locationGateway: UserLocationGateway
    
    init(gateway: EatOutFinderGateway, locationGateway: UserLocationGateway) {

        self.gateway = gateway
        self.locationGateway = locationGateway
    }

    // MARK: - Actions

    func load() {
        AppLogger.log(object: self, function: #function)
        outlet?.show(EatOutFinderDownloadStateUI.loading)
        gateway.fetchLocations(completion: handleFetchResponse)
    }

    func updateUI() {
        updateLocation(requestAuthorisation: false)
    }

    func didSelectItem(item: EatOutFinderItemUI) {

        outlet?.show(item.searchURL, title: item.name)

    }

    func updateLocation() {

        updateLocation(requestAuthorisation: true)
        
    }

    private func updateLocation(requestAuthorisation: Bool) {
        AppLogger.log(object: self, function: #function)
        locationGateway.fetchUserLocationStatus(requestsAuthorisation: requestAuthorisation) { [weak self] (status) in
            switch status {
            case .on:
                self?.outlet?.show(UserLocationButtonUI.hilighted)
                self?.outlet?.showUserCurrentLocationOnMap()
            case .off:
                self?.outlet?.show(UserLocationButtonUI.disabled)
            case .undefined:
                self?.outlet?.show(UserLocationButtonUI.normal)
            }
        }
    }

    // MARK: - Internals

    private func handleFetchResponse(entities: [EatOutLocationEntity]?, error: Error?) {

        var completion: ()->Void = {}

        defer {
            dispatchMain { completion() }
        }

        guard let entities = entities else {

            let error = (error ?? EatOutFinderDataError.FetchUnexpectedError)

            let errorUI = ErrorUI(error: error) { (actionTitle) in
                AppLogger.log(object: self, function: #file, message: "TODO: Error Action Handle \(actionTitle)")
                self.load()
            }

            dispatchMain {
                completion = { self.outlet?.show(errorUI) }
            }

            return

        }

        dispatchMain {
            let items = entities.map { EatOutFinderItemUI(entity: $0) }
            completion = { self.outlet?.show( items ) }
        }

    }

    private func dispatchMain(_ block: @escaping () -> Void) {

        DispatchQueue.main.async { block() }

    }


}

// MARK: - Entity

struct EatOutLocationEntity {

    let coordinate: (lat: Double, long: Double)
    let name: String
    let postcode: String

}

