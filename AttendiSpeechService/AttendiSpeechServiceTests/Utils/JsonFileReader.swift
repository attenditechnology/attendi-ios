import Foundation

/// Utility namespace for reading JSON files from the classpath.
///
/// This is primarily intended for use in unit tests where mock JSON responses
/// or configurations are stored as resource files.
///
/// Usage example:
/// ```
/// let json = JsonFileReader.read("mock_response")
/// ```
enum JsonFileReader {
    static func read<T: Decodable>(_ path: String) throws -> T {
        let bundle = BundleToken.bundle
        guard let fileURL = bundle.url(forResource: path, withExtension: "json") else {
            throw NSError(domain: String(describing: Self.self), code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found: \(path)"])
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
