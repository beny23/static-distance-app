import Foundation

// MARK: - GeoJSON Gateway

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

// MARK: - GeoJSON Data Session

class EatOutNetworkGeoJSONDataSession {

    fileprivate typealias FetchDataCompletion = (_ : [GeoJSONFeature]?, _ : Error?) -> Swift.Void

    private let dataURL = URL(string: "https://beny23.github.io/static-distance-app/restaurants.geojson.gz")!

    lazy private var downloadManager: JSONFileDownloadManager = {
        JSONFileDownloadManager(delegate: self)
    }()

    private var session: URLSession?
    private var fetchCompletion: FetchDataCompletion?
    private var dataTask: URLSessionDownloadTask?

    // MARK: API

    fileprivate func fetchData(completion: @escaping FetchDataCompletion )  {
        self.fetchCompletion = completion
        fetchJSON()
    }

    // MARK: Internals

    private func fetchJSON() {
        createSession()
        dataTask = session?.downloadTask(with: dataURL)
        dataTask?.resume()
    }

    private func clearSession() {
        session?.invalidateAndCancel()
        session = nil
    }

    private func createSession() {
        let configuration = URLSessionConfiguration.DownloadTaskCacheConfiguration
        session = URLSession(configuration: configuration, delegate: downloadManager, delegateQueue: nil )
    }

    private func decodeJSON(data: Data) -> Bool {

        //TODO: Swap in MKGeoJSONDecoder as a less code alternative

        let decoder = JSONDecoder()

        do {
            let collection = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
            complete(with: collection)
            return true
        } catch {
            AppLogger.log(object: self, function: #function, error: error )
            return false
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

    func downloadManager(_ manager: JSONFileDownloadManager, didDownload data: Data?, task: URLSessionTask, error: Error?) {

        AppLogger.log(object: self, function: #function)

        guard let data = data else {

            let error = error ?? EatOutFinderDataError.FetchUnexpectedError

            complete(with: error)

            return
        }

        let success = decodeJSON(data: data)

        if success {
            URLSessionConfiguration.modifyDownloadTaskCacheHeaders(for: task.response)
        } else {
            URLSessionConfiguration.resetDownloadTaskCacheHeaders()
        }

        clearSession()
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
