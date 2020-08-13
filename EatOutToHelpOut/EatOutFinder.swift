import Foundation
import MapKit

enum EatOutFinderStatusUI {
    case loading // Loading data
    case userLocationOff // Undetermined location permission
    case userLocationOn // Location permission enabled
    case userLocationDisabled // Location permission denied
}

protocol EatOutFinderOutlet: AnyObject {
    func show(_ : ErrorUI)
    func show(_ : [EatOutFinderItemUI])
    func show(_ : URL, title: String)
    func show(_ : EatOutFinderStatusUI)
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

enum EatOutFetchType {
    case Default, OnlyIfModified
}

protocol EatOutGateway: AnyObject {

    typealias FetchLocationsCompletion = ([EatOutLocationEntity]?, Error?) -> Swift.Void
    func fetchLocations(type: EatOutFetchType, completion: @escaping FetchLocationsCompletion)

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

    private let gateway: EatOutGateway
    private let locationGateway: UserLocationGateway
    private var didLoad: Bool = false

    init(gateway: EatOutGateway, locationGateway: UserLocationGateway) {
        self.gateway = gateway
        self.locationGateway = locationGateway
    }

    // MARK: - Actions

    func load() {
        AppLogger.log(object: self, function: #function)
        loadData()
    }

    func loadData() {
        let fetchType: EatOutFetchType = didLoad ? .OnlyIfModified : .Default
        if fetchType == .Default /* load quitely if we already have loaded */ { outlet?.show( EatOutFinderStatusUI.loading ) }
        gateway.fetchLocations(type: fetchType, completion: handleFetchResponse)
    }

    func updateUI() {
        if didLoad {
            updateLocation(requestAuthorisation: false)
        }
    }

    func didSelectItem(item: EatOutFinderItemUI) {
        outlet?.show(item.searchURL, title: item.name)
    }

    func updateLocation() {
        updateLocation(requestAuthorisation: true)
    }

    private func updateLocation(requestAuthorisation: Bool) {
        AppLogger.log(object: self, function: #function, message: "Update Location Status  (isRequestingPermission:\(requestAuthorisation))")
        locationGateway.fetchUserLocationStatus(requestsAuthorisation: requestAuthorisation) { [unowned self] (status) in
            switch status {
            case .on:
                AppLogger.log(object: self, function: #function, message: "Location Status: On")
                self.outlet?.show(EatOutFinderStatusUI.userLocationOn)
            case .off:
                AppLogger.log(object: self, function: #function, message: "Location Status: Off")
                self.outlet?.show(EatOutFinderStatusUI.userLocationDisabled)
            case .undefined:
                AppLogger.log(object: self, function: #function, message: "Location Status: Undefined")
                self.outlet?.show(EatOutFinderStatusUI.userLocationOff)
            case .initialising:
                break
            }
        }
    }

    // MARK: - Internals

    private func handleFetchResponse(entities: [EatOutLocationEntity]?, error: Error?) {

        var completion: ()->Void = {}

        defer {
            dispatchMain {
                completion()
            }
        }

        if (!didLoad) {
            dispatchMain {
                self.updateLocation(requestAuthorisation: false)
            }
        }

        guard let entities = entities else {

            // Response is nil when not-modified. Only error if we previousl did not load

            if !didLoad  {
                let error = (error ?? EatOutFinderDataError.FetchUnexpectedError)
                let errorUI = ErrorUI(error: error) { _ in self.load() }
                completion = {
                    self.outlet?.show(errorUI)
                }
            } else {
                AppLogger.log(object: self, function: #function, message: "Response unmodified")
            }

            return

        }

        didLoad = true
        let items = entities.map { EatOutFinderItemUI(entity: $0) }
        completion = { self.outlet?.show( items ) }

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

