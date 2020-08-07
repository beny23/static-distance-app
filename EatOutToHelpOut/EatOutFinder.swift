import Foundation
import MapKit

protocol EatOutFinderOutlet: AnyObject {
    func show(_ : ErrorUI)
    func show(_ : [EatOutFinderItemUI])
    func show(_ : URL, title: String)
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

    init(gateway: EatOutFinderGateway) {

        self.gateway = gateway

    }

    // MARK: - Actions

    func load() {

        AppLogger.log(object: self, function: #function)
        gateway.fetchLocations(completion: handleFetchResponse)

    }
    
    func didSelectItem(item: EatOutFinderItemUI) {

        outlet?.show(item.searchURL, title: item.name)

    }

    // MARK: - Internals

    private func handleFetchResponse(entities: [EatOutLocationEntity]?, error: Error?) {

        guard let entities = entities else {

            let error = (error ?? EatOutFinderDataError.FetchUnexpectedError)

            let errorUI = ErrorUI(error: error) { (actionTitle) in
                AppLogger.log(object: self, function: #file, message: "TODO: Error Action Handle \(actionTitle)")
                self.load()
            }

            dispatchMain {
                self.outlet?.show(errorUI)
            }

            return

        }

        dispatchMain {
            let items = entities.map { EatOutFinderItemUI(entity: $0) }
            self.outlet?.show( items )
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

// MARK: - Network GeoJSON Gateway

class EatOutNetworkGeoJSONGateway: EatOutFinderGateway {

    let dataSession = EatOutNetworkGeoJSONDataSession()
    var completion: FetchLocationsCompletion? = nil

    func fetchLocations(completion: @escaping FetchLocationsCompletion) {
        self.completion = completion
        dataSession.fetchData(completion: fetchHandler)
    }

    private func fetchHandler(features: [GeoJSONFeature]?, error: Error?) -> Void {

        guard let features = features else {
            completion?(nil, error ?? EatOutFinderDataError.FetchUnexpectedError )
            return
        }

        let entities = features.map { (f) -> EatOutLocationEntity in
            let coordinate = (f.geometry.lat, f.geometry.long)
            let name = f.properties.name
            let postcode = f.properties.postcode
            return EatOutLocationEntity(coordinate: coordinate, name: name, postcode: postcode)
        }

        completion?(entities, nil)
        completion = nil
    }

}


class EatOutNetworkGeoJSONDataSession {

    // MARK: Properties

    fileprivate typealias FetchDataCompletion = (_ : [GeoJSONFeature]?, _ : Error?) -> Swift.Void

    private let dataURL = URL(string: "https://beny23.github.io/static-distance-app/restaurants.geojson.gz")!

    lazy private var downloadManager: URLSessionJSONFileDownloadManager = {
        URLSessionJSONFileDownloadManager(delegate: self)
    }()

    lazy private var session: URLSession = {
        URLSession(configuration: URLSessionConfiguration.default, delegate: downloadManager, delegateQueue: nil )
    }()

    private var fetchCompletion: FetchDataCompletion?
    private var downloadTask: URLSessionDownloadTask?

    // MARK: API

    fileprivate func fetchData(completion: @escaping FetchDataCompletion )  {
        self.fetchCompletion = completion
        fetchJSON()
    }

    // MARK: Internals

    private func fetchJSON() {
        downloadTask = session.downloadTask(with: dataURL)
        downloadTask?.resume()
    }

    private func decodeJSON(data: Data) {

        //TODO: Swap in MKGeoJSONDecoder as a less code alternative

        let decoder = JSONDecoder()
        do {
            let collection = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
            complete(with: collection)
        } catch {
            AppLogger.log(object: self, function: #function, error: error )
        }
    }

    //MARK: Completion

    private func complete(with collection: GeoJSONFeatureCollection) {
        AppLogger.log(object: self, function: #function, message: "Did Decode GeoJSON Type:\(collection.type)")
        complete(with: collection.features, error: nil)
    }

    private func complete(with error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
        complete(with: nil, error: error)
    }

    private func complete(with items: [GeoJSONFeature]?, error: Error?) {
        fetchCompletion?(items, error)
        fetchCompletion = nil
    }

}

extension EatOutNetworkGeoJSONDataSession: JSONFileDownloadManagerDelegate {

    func downloadManager(_ manager: URLSessionJSONFileDownloadManager, didDownload data: Data?, error: Error?) {

        AppLogger.log(object: self, function: #function)

        guard let data = data else {

            let error = error ?? EatOutFinderDataError.FetchUnexpectedError

            complete(with: error)

            return
        }

        decodeJSON(data: data)

    }

}

//MARK: - Geo JSON Data Model

fileprivate struct GeoJSONFeatureCollection: Decodable {
    let type: String
    let features: [ GeoJSONFeature ]
}

fileprivate struct GeoJSONFeature: Decodable {
    let properties: WebServiceFeatureProperty
    let geometry: WebServiceFeatureGeometry
}

fileprivate struct WebServiceFeatureProperty: Decodable {
    let name: String
    let postcode: String
}

fileprivate struct WebServiceFeatureGeometry: Decodable {
    let coordinates: [Double]
    var lat: Double { return coordinates.last! }
    var long: Double { return coordinates.first! }
}
