import Foundation

public struct AppEnvironment {

    // MARK: - Keys
    static let ApiKeyPlistFileName = "ApiKeys"

    private enum ApiKeys : String {
        case MSAppCenterSecretKey
    }

    private enum WSInfoKey: String {
        case WSEnableDemo
    }

    // MARK: - Plist Guts

    private static let apiKeyPlist: [String: Any] = {
        var plistFormat =  PropertyListSerialization.PropertyListFormat.xml
        guard
            let path = Bundle.main.url(forResource: Self.ApiKeyPlistFileName, withExtension: "plist"),
            let data = try? Data(contentsOf: path),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: &plistFormat) as? [String:Any]
        else { return [:] }
        return plist
    }()

    // MARK: - Plist values

    static let MSAppCenterSecret: String = {
        guard let secret = Self.apiKeyPlist[ApiKeys.MSAppCenterSecretKey.rawValue] as? String else {
            fatalError("\(ApiKeys.MSAppCenterSecretKey) Not Found in PLIST \(Self.ApiKeyPlistFileName)")
        }
        return secret
    }()

}
