import Testing
@testable import AttendiSpeechService

struct TranscribeAsyncReplaceTextMapperTests {

    // MARK: - Replacing text

    @Test
    func map_withASCIIText_replacesCorrectRange() throws {
        let params = TranscribeAsyncReplaceTextParameters(
            text: "there",
            startCharacterIndex: 6,
            endCharacterIndex: 11
        )
        let result = try TranscribeAsyncReplaceTextMapper.map(original: "hello world", params: params)
        #expect(result == "hello there")
    }

    @Test
    func map_withPrecomposedAccentedCharacter_replacesCorrectRange() throws {
        // Precomposed "é" (U+00E9) is 1 UTF-16 unit and 1 Swift Character — counts agree.
        let original = "caf\u{00E9}"  // "café" — 4 UTF-16 units, 4 Swift characters
        let params = TranscribeAsyncReplaceTextParameters(
            text: "coffee",
            startCharacterIndex: 0,
            endCharacterIndex: 4
        )
        let result = try TranscribeAsyncReplaceTextMapper.map(original: original, params: params)
        #expect(result == "coffee")
    }

    @Test
    func map_withDecomposedAccentedCharacter_replacesCorrectRange() throws {
        // Decomposed "é" (e + U+0301) is 2 UTF-16 units but 1 Swift Character.
        // The backend sends UTF-16 indices, so endCharacterIndex: 5 correctly covers
        // the full string even though Swift's character count is 4.
        let original = "cafe\u{0301}"
        #expect(original.utf16.count == 5)
        #expect(original.count == 4)

        let params = TranscribeAsyncReplaceTextParameters(
            text: "coffee",
            startCharacterIndex: 0,
            endCharacterIndex: 5
        )
        let result = try TranscribeAsyncReplaceTextMapper.map(original: original, params: params)
        #expect(result == "coffee")
    }

    // MARK: - Out of bounds indices

    @Test
    func map_whenStartIndexExceedsStringLength_throws() throws {
        let params = TranscribeAsyncReplaceTextParameters(
            text: "replacement",
            startCharacterIndex: 10,
            endCharacterIndex: 10
        )
        #expect(throws: TranscribeAsyncReplaceTextError.self) {
            try TranscribeAsyncReplaceTextMapper.map(original: "hello", params: params)
        }
    }

    @Test
    func map_whenEndIndexExceedsStringLength_throws() throws {
        let params = TranscribeAsyncReplaceTextParameters(
            text: "replacement",
            startCharacterIndex: 0,
            endCharacterIndex: 10
        )
        #expect(throws: TranscribeAsyncReplaceTextError.self) {
            try TranscribeAsyncReplaceTextMapper.map(original: "hello", params: params)
        }
    }
}
