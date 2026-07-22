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

/// Errors thrown by `TranscribeAsyncReplaceTextMapper`.
public enum TranscribeAsyncReplaceTextError: Error, Equatable {
    /// The start or end index exceeds the length of the string or falls on an invalid character boundary.
    case indexOutOfBounds(startCharacterIndex: Int, endCharacterIndex: Int, textLength: Int)
}

public enum TranscribeAsyncReplaceTextMapper {

    /// Replaces a portion of the text between the given indices with new content.
    ///
    /// - Parameters:
    ///   - original: The original string.
    ///   - params: The replace text parameters containing indices and replacement text.
    /// - Returns: A new string with the specified range replaced.
    /// - Throws: `TranscribeAsyncReplaceTextError.indexOutOfBounds` if either index exceeds the string length or falls on an invalid character boundary.
    public static func map(original: String, params: TranscribeAsyncReplaceTextParameters) throws -> String {
        // The backend sends indices counted in UTF-16 code units, so we index
        // via the utf16 view to stay in sync with the server's character offsets.
        let utf16 = original.utf16
        guard
            let startUTF16Index = utf16.index(utf16.startIndex, offsetBy: params.startCharacterIndex, limitedBy: utf16.endIndex),
            let endUTF16Index = utf16.index(utf16.startIndex, offsetBy: params.endCharacterIndex, limitedBy: utf16.endIndex),
            let startIndex = startUTF16Index.samePosition(in: original),
            let endIndex = endUTF16Index.samePosition(in: original)
        else {
            throw TranscribeAsyncReplaceTextError.indexOutOfBounds(
                startCharacterIndex: params.startCharacterIndex,
                endCharacterIndex: params.endCharacterIndex,
                textLength: utf16.count
            )
        }

        return String(original[..<startIndex]) + params.text + String(original[endIndex...])
    }
}
