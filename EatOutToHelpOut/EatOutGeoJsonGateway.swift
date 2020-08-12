import Foundation

// MARK: - GeoJSON Gateway

class EatOutGeoJSONGateway: EatOutGateway {

    let dataSession = EatOutGeoJSONDataSession()
    var completion: FetchLocationsCompletion? = nil

    func fetchLocations(type: EatOutFetchType, completion: @escaping FetchLocationsCompletion) {
        self.completion = completion
        let ignoreNonModified = ( type == .Default ) ? false : true
        dataSession.fetchData(ignoreNonModified: ignoreNonModified, completion: fetchHandler)
    }

    private func fetchHandler(features: [GeoJSONFeature]?, error: Error?) -> Void {

        defer {
            completion = nil
        }

        guard let features = features else {
            completion?(nil, error ?? EatOutFinderDataError.FetchUnexpectedError)
            return
        }

        let entities = self.entities(for: features)
        completion?(entities, nil)
    }


    private func entities(for features: [GeoJSONFeature]) -> [EatOutLocationEntity] {
        features.map { (f) -> EatOutLocationEntity in
            let coordinate = (f.geometry.lat, f.geometry.long)
            let name = f.properties.name
            let postcode = f.properties.postcode
            return EatOutLocationEntity(coordinate: coordinate, name: name, postcode: postcode)
        }
    }

}

// MARK: - GeoJSON Data Session

class EatOutGeoJSONDataSession {

    fileprivate typealias FetchDataCompletion = (_ : [GeoJSONFeature]?, _ : Error?) -> Swift.Void

    private let dataURL = URL(string: "https://beny23.github.io/static-distance-app/restaurants.geojson.gz")!

    lazy private var downloadManager: JSONFileDownloadManager = {
        JSONFileDownloadManager(delegate: self)
    }()

    private var session: URLSession?
    private var fetchCompletion: FetchDataCompletion?
    private var dataTask: URLSessionDownloadTask?
    private var ignoresNonModified: Bool = false

    // MARK: API

    fileprivate func fetchData(ignoreNonModified: Bool = false, completion: @escaping FetchDataCompletion )  {
        AppLogger.log(object: self, function: #function)
        self.ignoresNonModified = ignoreNonModified
        self.fetchCompletion = completion
        fetchJSON()
    }

    // MARK: Internals

    private func fetchJSON() {
        AppLogger.log(object: self, function: #function)
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

    private func decodeJSON(data: Data) -> GeoJSONFeatureCollection? {

        //TODO: Swap in MKGeoJSONDecoder as a less code alternative

        let decoder = JSONDecoder()

        do {
            let collection = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
            return collection
        } catch {
            AppLogger.log(object: self, function: #function, error: error )
            return nil
        }
    }

    //MARK: Completion

    private func complete(with collection: GeoJSONFeatureCollection?) {
        AppLogger.log(object: self, function: #function, message: "Did Decode GeoJSON Type:\(String(describing: collection?.type))")
        complete(with: collection?.features, error: nil)
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

extension EatOutGeoJSONDataSession: JSONFileDownloadManagerDelegate {

    func downloadManager(_ manager: JSONFileDownloadManager, didDownload data: Data?, task: URLSessionTask, notModified: Bool?, error: Error?) {

        AppLogger.log(object: self, function: #function)

        defer { clearSession() }

        let disableDecoding = ( notModified == true && ignoresNonModified )

        guard let data = data,
            let collection = (disableDecoding) ? nil : decodeJSON(data: data)
        else {
            let error = error ?? EatOutFinderDataError.FetchUnexpectedError
            complete(with: error)
            return
        }

        complete(with: collection)

        URLSessionConfiguration.modifyDownloadTaskCacheHeaders(for: task.response)

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
