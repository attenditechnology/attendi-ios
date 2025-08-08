import Testing
@testable import AttendiSpeechService

struct TranscribeAsyncActionMapperTests {

    @Test
    func map_whenResponseContainsAddAnnotationTranscriptionTentative_returnsListWithAddAnnotationTranscriptionTentativeAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaAddAnnotationTranscriptionTentative")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .addAnnotation(let addAnnotation) = model[0] else {
            assertionFailure("Expected AddAnnotation")
            return
        }

        #expect(addAnnotation.actionData.id == "0d42a586-9f65-4bc1-925c-4361ef4a33cc")
        #expect(addAnnotation.actionData.index == 0)
        guard case .transcriptionTentative = addAnnotation.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type")
            return
        }
        #expect(addAnnotation.parameters.id == "0e74a828-9f62-448f-842c-45bff04d99a3")
        #expect(addAnnotation.parameters.startCharacterIndex == 0)
        #expect(addAnnotation.parameters.endCharacterIndex == 5)
    }

    @Test
    func map_whenResponseContainsAddAnnotationIntent_returnsListWithAddAnnotationIntentAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaAddAnnotationIntent")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 2)

        guard case .addAnnotation(let addAnnotation) = model[0],
              case .intent(let pendingIntent) = addAnnotation.parameters.type else {
            assertionFailure("Expected AddAnnotation with Intent (Pending)")
            return
        }

        #expect(addAnnotation.actionData.id == "07ca2023-cc1a-4f33-a077-9401ba621c15")
        #expect(pendingIntent == .pending)
        #expect(addAnnotation.parameters.id == "af262d26-80bd-41d9-97c1-1f9876fa7730")
        #expect(addAnnotation.parameters.startCharacterIndex == 0)
        #expect(addAnnotation.parameters.endCharacterIndex == 8)

        guard case .addAnnotation(let recognizedAddAnnotation) = model[1],
              case .intent(let recognizedIntent) = recognizedAddAnnotation.parameters.type else {
            assertionFailure("Expected AddAnnotation with Intent (Recognized)")
            return
        }

        #expect(recognizedAddAnnotation.actionData.id == "07ca2023-cc1a-4f33-a077-9401ba621c16")
        #expect(recognizedIntent == .recognized)
        #expect(recognizedAddAnnotation.parameters.id == "af262d26-80bd-41d9-97c1-1f9876fa7731")
        #expect(recognizedAddAnnotation.parameters.startCharacterIndex == 0)
        #expect(recognizedAddAnnotation.parameters.endCharacterIndex == 8)
    }

    @Test
    func map_whenResponseContainsAddAnnotationEntity_returnsListWithAddAnnotationEntityAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaAddAnnotationEntity")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .addAnnotation(let addAnnotation) = model[0],
              case .entity(let entityType, let entityText) = addAnnotation.parameters.type else {
            assertionFailure("Expected AddAnnotation with Entity")
            return
        }

        #expect(addAnnotation.actionData.id == "17ca2023-cc1a-4f33-a077-9401ba621c15")
        #expect(addAnnotation.actionData.index == 0)
        #expect(entityType == .name)
        #expect(entityText == "Albert")
        #expect(addAnnotation.parameters.id == "rf262d26-80bd-41d9-97c1-1f9876fa7730")
        #expect(addAnnotation.parameters.startCharacterIndex == 0)
        #expect(addAnnotation.parameters.endCharacterIndex == 0)
    }

    @Test
    func map_whenResponseContainsUpdateAnnotationTranscriptionTentative_returnsListWithUpdateAnnotationTranscriptionTentativeAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaUpdateAnnotationTranscriptionTentative")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .updateAnnotation(let updateAnnotation) = model[0] else {
            assertionFailure("Expected UpdateAnnotation")
            return
        }

        #expect(updateAnnotation.actionData.id == "0d42a586-9f65-4bc1-925c-4361ef4a33cc")
        #expect(updateAnnotation.actionData.index == 0)
        guard case .transcriptionTentative = updateAnnotation.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type")
            return
        }
        #expect(updateAnnotation.parameters.id == "0e74a828-9f62-448f-842c-45bff04d99a3")
        #expect(updateAnnotation.parameters.startCharacterIndex == 0)
        #expect(updateAnnotation.parameters.endCharacterIndex == 5)
    }

    @Test
    func map_whenResponseContainsUpdateAnnotationEntity_returnsListWithUpdateAnnotationEntityAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaUpdateAnnotationEntity")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .updateAnnotation(let updateAnnotation) = model[0],
              case .entity(let entityType, let entityText) = updateAnnotation.parameters.type else {
            assertionFailure("Expected UpdateAnnotation with Entity")
            return
        }

        #expect(updateAnnotation.actionData.id == "17ca2023-cc1a-4f33-a077-9401ba621c15")
        #expect(updateAnnotation.actionData.index == 0)
        #expect(entityType == .name)
        #expect(entityText == "Albert")
        #expect(updateAnnotation.parameters.id == "rf262d26-80bd-41d9-97c1-1f9876fa7730")
        #expect(updateAnnotation.parameters.startCharacterIndex == 0)
        #expect(updateAnnotation.parameters.endCharacterIndex == 0)
    }

    @Test
    func map_whenResponseContainsReplaceText_returnsListWithReplaceTextAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaReplaceText")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .replaceText(let replaceText) = model[0] else {
            assertionFailure("Expected ReplaceText")
            return
        }

        #expect(replaceText.actionData.id == "b05bddd0-0577-47d6-b65b-13170c27596a")
        #expect(replaceText.actionData.index == 0)
        #expect(replaceText.parameters.text == "hallo")
        #expect(replaceText.parameters.startCharacterIndex == 0)
        #expect(replaceText.parameters.endCharacterIndex == 0)
    }

    @Test
    func map_whenResponseContainsRemoveAnnotation_returnsListWithRemoveAnnotationAction() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaRemoveAnnotation")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 1)

        guard case .removeAnnotation(let removeAnnotation) = model[0] else {
            assertionFailure("Expected RemoveAnnotation")
            return
        }

        #expect(removeAnnotation.actionData.id == "1488702d-86a5-4313-89a4-e0589d724933")
        #expect(removeAnnotation.actionData.index == 0)
        #expect(removeAnnotation.parameters.id == "0e74a828-9f62-448f-842c-45bff04d99a3")
    }

    @Test
    func map_whenResponseContainsMixedAnnotations_returnsListWithMixedAnnotationActions() throws {
        let response: TranscribeAsyncResponse = try JsonFileReader.read("TranscribeAsyncSchemaMixedAnnotations")
        let model = try TranscribeAsyncActionMapper.map(response: response)

        #expect(model.count == 3)

        guard case .removeAnnotation(let removeAnnotation) = model[0] else {
            assertionFailure("Expected RemoveAnnotation")
            return
        }

        #expect(removeAnnotation.actionData.id == "f59412fd-90db-402d-a96c-09ece06aba0f")
        #expect(removeAnnotation.actionData.index == 35)
        #expect(removeAnnotation.parameters.id == "22ab4ed5-1ed2-4e6a-bde4-7e5e4005f129")

        guard case .replaceText(let replaceText) = model[1] else {
            assertionFailure("Expected ReplaceText")
            return
        }

        #expect(replaceText.actionData.id == "08665124-0100-45ff-97b0-fff6dd118a88")
        #expect(replaceText.actionData.index == 36)
        #expect(replaceText.parameters.text == " een mg")
        #expect(replaceText.parameters.startCharacterIndex == 19)
        #expect(replaceText.parameters.endCharacterIndex == 22)

        guard case .addAnnotation(let addAnnotation) = model[2] else {
            assertionFailure("Expected AddAnnotation")
            return
        }

        #expect(addAnnotation.actionData.id == "3f34eb1a-4d10-4bc3-9c34-b40a7624d57b")
        #expect(addAnnotation.actionData.index == 37)
        guard case .transcriptionTentative = addAnnotation.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type")
            return
        }
        #expect(addAnnotation.parameters.id == "e870b00f-c9d0-435c-8997-686bc6c9cb86")
        #expect(addAnnotation.parameters.startCharacterIndex == 19)
        #expect(addAnnotation.parameters.endCharacterIndex == 26)
    }
}
