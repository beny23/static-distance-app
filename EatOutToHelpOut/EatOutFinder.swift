import Foundation
import CoreLocation

struct ErrorUI {
    typealias ErrorUIAction = (_ actionTitle: String)->Void
    let message: String
    let title: String
    let defaultActionTitle: String
    let errorActionHandler: ErrorUIAction?
}

extension ErrorUI {

    init(error: Error, action: ErrorUIAction? = nil) {
        self.title = "Internal Error"
        self.defaultActionTitle = "OK"
        self.message = error.localizedDescription
        self.errorActionHandler = action
    }

}

protocol EatOutFinderOutlet: AnyObject {
    func show(_ : ErrorUI)
    func show(_ : [EatOutFinderItem])
}

enum EatOutLocationDataError: Error {

    case FetchDataUnexpectedError

    var localizedDescription: String {
        switch self {
        case .FetchDataUnexpectedError:
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

class EatOutFinderItem: NSObject {
    let coordinate: CLLocationCoordinate2D
    let name: String

    fileprivate init(entity: EatOutLocationEntity) {
        self.coordinate = CLLocationCoordinate2D(latitude: entity.coordinate.lat, longitude: entity.coordinate.long)
        self.name = entity.name
    }
}

class EatOutFinder {

    weak var outlet: EatOutFinderOutlet?

    let gateway: EatOutFinderGateway

    init(gateway: EatOutFinderGateway) {

        self.gateway = gateway

    }

    func load() {

        AppLogger.log(object: self, function: #function)
        gateway.fetchLocations(completion: handleFetchResponse)

    }

    private func handleFetchResponse(entities: [EatOutLocationEntity]?, error: Error?) {

        guard let entities = entities else {

            let error = (error ?? EatOutLocationDataError.FetchDataUnexpectedError)

            let errorUI = ErrorUI(error: error) { (actionTitle) in
                AppLogger.log(object: self, function: #file, message: "TODO: Error Action Handle \(actionTitle)")
            }

            dispatchMain {
                self.outlet?.show(errorUI)
            }

            return

        }

        dispatchMain {
            let items = entities.map { EatOutFinderItem(entity: $0) }
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
}

// MARK: - Web File JSON Gateway

class EatOutNetworkGateway: EatOutFinderGateway {

    let dataSession = EatOutNetworkDataSession()
    var completion: FetchLocationsCompletion? = nil

    func fetchLocations(completion: @escaping FetchLocationsCompletion) {
        self.completion = completion
        dataSession.fetchData(completion: fetchHandler)
    }

    private func fetchHandler(features: [WebServiceFeature]?, error: Error?) -> Void {

        guard let features = features else {
            completion?(nil, error ?? EatOutLocationDataError.FetchDataUnexpectedError )
            return
        }

        let entities = features.map { (f) -> EatOutLocationEntity in
            let coordinate = (f.geometry.lat, f.geometry.long)
            let name = f.properties.name
            return EatOutLocationEntity(coordinate: coordinate, name: name)
        }

        completion?(entities, nil)
        completion = nil
    }

}


class EatOutNetworkDataSession {

    // MARK: Properties

    fileprivate typealias FetchDataCompletion = (_ : [WebServiceFeature]?, _ : Error?) -> Swift.Void

    private let dataURL = URL(string: "https://beny23.github.io/static-distance-app/restaurants.geojson.gz")!

    lazy private var downloadManager: WebServiceFileDownloadManager = {
        WebServiceFileDownloadManager(delegate: self)
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
        let decoder = JSONDecoder()
        do {
            let collection = try decoder.decode(WebServiceFeatureCollection.self, from: data)
            complete(with: collection)
        } catch {
            AppLogger.log(object: self, function: #function, error: error )
        }
    }

    //MARK: Completion

    private func complete(with collection: WebServiceFeatureCollection) {
        AppLogger.log(object: self, function: #function, message: "Did Decode GeoJSON Type:\(collection.type)")
        complete(with: collection.features, error: nil)
    }

    private func complete(with error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
        complete(with: nil, error: error)
    }

    private func complete(with items: [WebServiceFeature]?, error: Error?) {
        fetchCompletion?(items, error)
        fetchCompletion = nil
    }

}

extension EatOutNetworkDataSession: WebServiceFileDownloadManagerDelegate {

    func downloadManager(_ manager: WebServiceFileDownloadManager, didDownload data: Data?, error: Error?) {

        AppLogger.log(object: self, function: #function)

        guard let data = data else {

            let error = error ?? EatOutLocationDataError.FetchDataUnexpectedError

            complete(with: error)

            return
        }

        decodeJSON(data: data)

    }

}

protocol WebServiceFileDownloadManagerDelegate: AnyObject {
    func downloadManager(_ manager: WebServiceFileDownloadManager, didDownload data: Data?, error: Error?)
}

import GZIP

enum WebServiceFileDownloadManagerError: Error {
    case FileReadFailed
}

class WebServiceFileDownloadManager: NSObject, URLSessionDownloadDelegate {

    let delegate: WebServiceFileDownloadManagerDelegate
    var tmpDownloadedFileHandle: FileHandle? = nil

    init(delegate: WebServiceFileDownloadManagerDelegate) {
        self.delegate = delegate
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        AppLogger.log(object: self, function: #function, error: error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        AppLogger.log(object: self, function: #function, message: "Status Code:\((downloadTask.response as! HTTPURLResponse).statusCode)")
        AppLogger.log(object: self, function: #function, message: "\(location)")

        // Open the temporary file to prevent it being destroyed by the system

        do {
            tmpDownloadedFileHandle = try FileHandle(forReadingFrom: location)
        } catch {
            self.delegate.downloadManager(self, didDownload: nil, error: error)
            return
        }

        // Read in background to prevent blocking of urlsession delegate queue

        DispatchQueue.global(qos: .background).async { [unowned self] in
            do {
                let tmpData = self.tmpDownloadedFileHandle!.availableData
                let savedDataFilePath = try self.write(data: tmpData)
                self.open(file: savedDataFilePath)
                try? self.tmpDownloadedFileHandle?.close()
            } catch {
                AppLogger.log(object: self, function: #function, error: error)
                self.delegate.downloadManager(self, didDownload: nil, error: error)
            }
        }
    }

    private func open(file: URL) {

        AppLogger.log(object: self, function: #function)
        do {
            let data = try self.read(file: file)
            self.delegate.downloadManager(self, didDownload: data, error: nil)
        } catch {
            self.delegate.downloadManager(self, didDownload: nil, error: error)
        }
    }

    private func read(file: URL) throws -> Data {
        let data = try Data(contentsOf: file) as NSData
        guard let gunzippedData = data.isGzippedData() ? data.gunzipped() : data as Data else { throw WebServiceFileDownloadManagerError.FileReadFailed }
        AppLogger.log(object: self, function: #function, message: "Read File Data (Size:\(gunzippedData.count))")
        return gunzippedData
    }

    private func write(data: Data) throws -> URL {
        let filename = "data.json"
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var documentsFileURL = URL(fileURLWithPath: documentsPath)
        documentsFileURL.appendPathComponent(filename, isDirectory: false)
        AppLogger.log(object: self, function: #function, message: "Write To \(documentsFileURL)")
        try data.write(to: documentsFileURL)
        return documentsFileURL
    }
}

//MARK: - Geo JSON Data Model

fileprivate struct WebServiceFeatureCollection: Decodable {
    let type: String
    let features: [ WebServiceFeature ]
}

fileprivate struct WebServiceFeature: Decodable {
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
