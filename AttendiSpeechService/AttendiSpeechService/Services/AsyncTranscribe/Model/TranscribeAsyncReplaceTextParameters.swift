import Foundation

public struct TranscribeAsyncReplaceTextParameters: Equatable {

    public let text: String
    public let startCharacterIndex: Int
    public let endCharacterIndex: Int

    public init(
        text: String,
        startCharacterIndex: Int,
        endCharacterIndex: Int
    ) {
        self.text = text
        self.startCharacterIndex = startCharacterIndex
        self.endCharacterIndex = endCharacterIndex
    }
}

public enum TranscribeAsyncReplaceTextMapper {

    /// Replaces a portion of the text between the given indices with new content.
    ///
    /// - Parameters:
    ///   - original: The original string.
    ///   - action: The replace text action containing indices and replacement text.
    /// - Returns: A new string with the specified range replaced.
    /// - Throws: An error if the indices are out of bounds.
    public static func map(original: String, params: TranscribeAsyncReplaceTextParameters) throws -> String {
        let startIndex = original.index(original.startIndex, offsetBy: params.startCharacterIndex)
        let endIndex = original.index(original.startIndex, offsetBy: params.endCharacterIndex)

        return String(original[..<startIndex]) + params.text + String(original[endIndex...])
    }
}
