import Foundation
import os

struct AppLogger {

    static func log(object: Any, function: String, message: String? = nil) {
        os_log(.info, "%@ %@ %@", "\(object)", function, message ?? "")
    }

    static func log(object: Any, function: String, error: Error) {
        os_log(.info, "%@ %@ %@", "\(object)", function, error.localizedDescription)
    }

    static func logCache() {
        os_log(.info, "DiskCache: %i of %i",URLCache.shared.currentDiskUsage, URLCache.shared.diskCapacity)
        os_log(.info, "MemoryCache: %i of %i",URLCache.shared.currentMemoryUsage, URLCache.shared.memoryCapacity)
    }
}
