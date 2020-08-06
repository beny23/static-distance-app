import Foundation
import os

struct AppLogger {

    static func log(object: Any, function: String, message: String? = nil) {
        os_log(.info, "%@ %@ %@", "\(object)", function, message ?? "")
    }

    static func log(object: Any, function: String, error: Error) {
        os_log(.info, "%@ %@ %@", "\(object)", function, error.localizedDescription)
    }
}
