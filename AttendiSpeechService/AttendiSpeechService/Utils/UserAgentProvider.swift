import Foundation
import UIKit

/// `UserAgentProvider` provides metadata about the project and device.
enum UserAgentProvider {

    /// The name of the project.
    static let projectName = "AttendiSpeechService"

    /// The project's version name, typically set in `CFBundleShortVersionString` (e.g. "1.2.3").
    static var projectVersionName: String = {
        guard let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return ""
        }
        return bundleVersion
    }()

    /// The name of the operating system. Always "iOS" for iOS apps.
    static let os = "iOS"

    /// The phone's manufacturer. Always "Apple" for iOS devices.
    static let phoneManufacturer = "Apple"

    /// The iOS version currently running on the device (e.g. "17.5").
    static let iOSVersion = UIDevice.current.systemVersion

    /// The model identifier of the device (e.g. "iPhone14,5" for iPhone 13).
    static var phoneModel: String = {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }()

    /// Returns a formatted `User-Agent` string using app and device information.
    ///
    /// Format: `"AppName/AppVersion (DeviceModel; OS OSVersion; Manufacturer)"`
    /// Example: `"AttendiSpeechService/1.0.0 (iPhone14,5; iOS 17.5; Apple)"`
    static func getUserAgent() -> String {
        "\(projectName)/\(projectVersionName) (\(phoneModel); \(os) \(iOSVersion); \(phoneManufacturer))"
    }
}

