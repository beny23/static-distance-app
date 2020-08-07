import Foundation
import GZIP

protocol JSONFileDownloadManagerDelegate: AnyObject {

    func downloadManager(_ manager: URLSessionJSONFileDownloadManager, didDownload data: Data?, error: Error?)

}


enum JSONFileDownloadManagerError: Error {

    case FileReadFailed

}

class URLSessionJSONFileDownloadManager: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {

    let delegate: JSONFileDownloadManagerDelegate

    init(delegate: JSONFileDownloadManagerDelegate) {
        self.delegate = delegate
    }

    //MARK: URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        AppLogger.log(object: self, function: #function)
        guard let error = error else { return }
        AppLogger.log(object: self, function: #function, error: error)
    }


    //MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        AppLogger.log(object: self, function: #function, message: "Status Code:\((downloadTask.response as! HTTPURLResponse).statusCode)")

        AppLogger.logCache()

        do {
            let tmpDownloadedFileHandle = try FileHandle(forReadingFrom: location)
            readFileAsync(file: tmpDownloadedFileHandle) { data, error in
                self.delegate.downloadManager(self, didDownload: data, error: error)
                try? tmpDownloadedFileHandle.close()
            }
        } catch {
            self.delegate.downloadManager(self, didDownload: nil, error: error)
        }


    }

    //MARK: - Internal Guts

    private func readFileAsync(file: FileHandle, completion: @escaping (Data?, Error?)->Void) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            do {
                let newFileURL = try self.copyToDocumentsDir(file: file)
                let data = try self.readData(file: newFileURL)
                completion(data, nil)
            } catch {
                AppLogger.log(object: self, function: #function, error: error)
                completion(nil, error)
            }
        }
    }

    private func copyToDocumentsDir(file: FileHandle) throws -> URL {
        let dataFileURL = Self.DocumentsDirectoryDataFileURL
        try file.availableData.write(to: dataFileURL)
        return dataFileURL
    }

    private func readData(file: URL) throws -> Data {
        let data = try Data(contentsOf: file) as NSData
        guard let gunzippedData = data.isGzippedData() ? data.gunzipped() : data as Data else { throw JSONFileDownloadManagerError.FileReadFailed }
        AppLogger.log(object: self, function: #function, message: "Read File Data (Size:\(gunzippedData.count))")
        return gunzippedData
    }

    private static var DocumentsDirectoryDataFileURL: URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var documentsFileURL = URL(fileURLWithPath: documentsPath)
        documentsFileURL.appendPathComponent("data.json", isDirectory: false)
        return documentsFileURL
    }
}
