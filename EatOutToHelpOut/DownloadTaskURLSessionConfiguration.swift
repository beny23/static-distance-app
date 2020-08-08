import Foundation

enum UserDefault: String {

    case LastModified = "last-modified"

    func setValue(_ value : String) {
        UserDefaults.standard.set(value, forKey: self.Key)
    }

    var value: String? {
        UserDefaults.standard.string(forKey: self.Key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: self.Key)
    }

    var Key: String {
        return self.rawValue
    }

}

private let HTTPHeaderIfModifiedSinceKey = "If-Modified-Since"

extension URLSessionConfiguration {

    static var DownloadTaskCacheConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configureCacheHeaders(configuration)
        return configuration
    }

    static func resetDownloadTaskCacheHeaders() {
        UserDefault.LastModified.clear()
    }

    static func modifyDownloadTaskCacheHeaders(for response: URLResponse?) {
        guard let lastModified = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "last-modified")
        else { return }
        UserDefault.LastModified.setValue(lastModified)
    }

    private static func configureCacheHeaders(_ configuration: URLSessionConfiguration) {
        configuration.httpAdditionalHeaders = cacheHeaders
        AppLogger.log(object: self, function: #function, message: "\(HTTPHeaderIfModifiedSinceKey): \(configuration.httpAdditionalHeaders?[HTTPHeaderIfModifiedSinceKey] ?? "<<????>>")")
    }

    private static var cacheHeaders: [String:String]? {
        if let lastModified = UserDefault.LastModified.value {
            return [ HTTPHeaderIfModifiedSinceKey : lastModified ]
        } else {
            return nil
        }
    }
}
