import Testing
@testable import AttendiSpeechService

struct AttendiTranscribeStreamTests {

    @Test
    func receiveActions_whenActionsAreEmpty_returnsSameStream() throws {
        let attendiStreamState = AttendiStreamState(
            text: "Attendi",
            annotations: []
        )

        let actions: [TranscribeAsyncAction] = []

        var sut = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        sut = try sut.receiveActions(actions)

        #expect(sut.state.text == "Attendi")
        #expect(sut.state.annotations.isEmpty)
        #expect(sut.operationHistory.isEmpty)
        #expect(sut.undoneOperations.isEmpty)
    }

    @Test
    func receiveActions_whenActionsAreNotEmpty_returnsTransformedStream() throws {
        let attendiStreamState = AttendiStreamState(
            text: "",
            annotations: []
        )

        let initialStream = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        let sampleAttendiStreamState = AttendiStreamStateFactory.createSample()
        let sut = try initialStream.receiveActions(TranscribeAsyncActionFactory.createSample())

        #expect(sut.state.text == "Attendi")
        #expect(sut.state.annotations.count == 4)
        /// First State AddAnnotation.
        let annotation0 = sampleAttendiStreamState.annotations[0]
        #expect(annotation0.actionData.id == "1")
        #expect(annotation0.actionData.index == 1)
        #expect(annotation0.parameters.id == "1A")
        #expect(annotation0.parameters.startCharacterIndex == 0)
        #expect(annotation0.parameters.endCharacterIndex == 0)
        guard case .transcriptionTentative = annotation0.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type")
            return
        }
        /// Second State AddAnnotation.
        let annotation1 = sampleAttendiStreamState.annotations[1]
        #expect(annotation1.actionData.id == "2")
        #expect(annotation1.actionData.index == 2)
        #expect(annotation1.parameters.id == "2A")
        #expect(annotation1.parameters.startCharacterIndex == 0)
        #expect(annotation1.parameters.endCharacterIndex == 0)
        guard case let .entity(annotation1Type, annotation1Text) = annotation1.parameters.type else {
            assertionFailure("Expected Entity type")
            return
        }
        #expect(annotation1Type == .name)
        #expect(annotation1Text == "Entity")
        /// Third State AddAnnotation.
        let annotation2 = sampleAttendiStreamState.annotations[2]
        #expect(annotation2.actionData.id == "5")
        #expect(annotation2.actionData.index == 5)
        #expect(annotation2.parameters.id == "5A")
        #expect(annotation2.parameters.startCharacterIndex == 1)
        #expect(annotation2.parameters.endCharacterIndex == 5)
        guard case let .intent(annotation2Status) = annotation2.parameters.type else {
            assertionFailure("Expected Intent type")
            return
        }
        #expect(annotation2Status == .pending)
        /// Fourth State AddAnnotation.
        let annotation3 = sampleAttendiStreamState.annotations[3]
        #expect(annotation3.actionData.id == "7")
        #expect(annotation3.actionData.index == 7)
        #expect(annotation3.parameters.id == "7A")
        #expect(annotation3.parameters.startCharacterIndex == 1)
        #expect(annotation3.parameters.endCharacterIndex == 3)
        guard case .transcriptionTentative = annotation3.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type")
            return
        }
        /// Operation history.
        #expect(sut.operationHistory.count == 8)
        /// ReplaceText Operation with inverse ReplaceText.
        guard
            case .replaceText(let original0Action) = sut.operationHistory[0].original,
            case .replaceText(let inverse0Action) = sut.operationHistory[0].inverse[0]
        else {
            assertionFailure("Expected ReplaceText")
            return
        }
        #expect(original0Action.actionData.id == "0")
        #expect(original0Action.actionData.index == 0)
        #expect(original0Action.parameters.startCharacterIndex == 0)
        #expect(original0Action.parameters.endCharacterIndex == 0)
        #expect(original0Action.parameters.text == "Attendi")
        #expect(inverse0Action.actionData.id == "0")
        #expect(inverse0Action.actionData.index == 0)
        #expect(inverse0Action.parameters.startCharacterIndex == 0)
        #expect(inverse0Action.parameters.endCharacterIndex == 7)
        #expect(inverse0Action.parameters.text == "")
        /// AddAnnotation Operation with inverse RemoveAnnotation.
        guard
            case .addAnnotation(let original2Action) = sut.operationHistory[2].original,
            case .removeAnnotation(let inverse2Action) = sut.operationHistory[2].inverse[0],
            case .entity(let original2EntityType, let original2EntityText) = original2Action.parameters.type
        else {
            assertionFailure("Expected AddAnnotation and inverse RemoveAnnotation with entity")
            return
        }
        #expect(original2Action.actionData.id == "2")
        #expect(original2Action.actionData.index == 2)
        #expect(original2Action.parameters.id == "2A")
        #expect(original2Action.parameters.startCharacterIndex == 0)
        #expect(original2Action.parameters.endCharacterIndex == 0)
        #expect(original2EntityType == .name)
        #expect(original2EntityText == "Entity")
        #expect(inverse2Action.actionData.id == "2")
        #expect(inverse2Action.actionData.index == 2)
        #expect(inverse2Action.parameters.id == "2A")
        /// RemoveAnnotation Operation with inverse AddAnnotation.
        guard
            case .removeAnnotation(let original4Action) = sut.operationHistory[4].original,
            case .addAnnotation(let inverse4Action) = sut.operationHistory[4].inverse[0],
            case .transcriptionTentative = inverse4Action.parameters.type
        else {
            assertionFailure("Expected RemoveAnnotation and inverse AddAnnotation")
            return
        }
        #expect(original4Action.actionData.id == "4")
        #expect(original4Action.actionData.index == 4)
        #expect(original4Action.parameters.id == "3A")
        #expect(inverse4Action.actionData.id == "3")
        #expect(inverse4Action.actionData.index == 3)
        #expect(inverse4Action.parameters.id == "3A")
        #expect(inverse4Action.parameters.startCharacterIndex == 0)
        #expect(inverse4Action.parameters.endCharacterIndex == 0)
        /// UpdateAnnotation Operation with inverse AddAnnotation.
        guard
            case .updateAnnotation(let original7Action) = sut.operationHistory[7].original,
            case .removeAnnotation(let inverse7RemoveAction) = sut.operationHistory[7].inverse[0],
            case .addAnnotation(let inverse7AddAction) = sut.operationHistory[7].inverse[1],
            case .transcriptionTentative = original7Action.parameters.type,
            case .intent(let inverse7AddActionStatus) = inverse7AddAction.parameters.type
        else {
            assertionFailure("Expected UpdateAnnotation and inverses Remove + Add")
            return
        }
        #expect(original7Action.actionData.id == "7")
        #expect(original7Action.actionData.index == 7)
        #expect(original7Action.parameters.id == "6A")
        #expect(original7Action.parameters.startCharacterIndex == 1)
        #expect(original7Action.parameters.endCharacterIndex == 3)
        #expect(inverse7RemoveAction.actionData.id == "7")
        #expect(inverse7RemoveAction.actionData.index == 7)
        #expect(inverse7RemoveAction.parameters.id == "7")
        #expect(inverse7AddAction.actionData.id == "6")
        #expect(inverse7AddAction.actionData.index == 6)
        #expect(inverse7AddAction.parameters.id == "6A")
        #expect(inverse7AddAction.parameters.startCharacterIndex == 1)
        #expect(inverse7AddAction.parameters.endCharacterIndex == 5)
        #expect(inverse7AddActionStatus == .pending)
        /// Empty UndoneOperations history.
        #expect(sut.undoneOperations.isEmpty)
    }

    @Test
    func undoOperations_whenIndexIsWithinOperationHistoryBounds_returnsPreviousTranscribeState() throws {
        let attendiStreamState = AttendiStreamState(
            text: "",
            annotations: []
        )

        var initialStream = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        initialStream = try initialStream.receiveActions(TranscribeAsyncActionFactory.createSample())

        var sut = try initialStream.undoOperations(count: 4)

        let state = sut.state
        #expect(state.text == "Attendi")
        #expect(state.annotations.count == 3)

        /// First state Add Annotation.
        let annotation1 = state.annotations[0]
        #expect(annotation1.actionData.id == "1")
        #expect(annotation1.actionData.index == 1)
        #expect(annotation1.parameters.id == "1A")
        #expect(annotation1.parameters.startCharacterIndex == 0)
        #expect(annotation1.parameters.endCharacterIndex == 0)
        guard case .transcriptionTentative = annotation1.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type for annotation1")
            return
        }
        /// Second state Add Annotation.
        let annotation2 = state.annotations[1]
        #expect(annotation2.actionData.id == "2")
        #expect(annotation2.actionData.index == 2)
        #expect(annotation2.parameters.id == "2A")
        #expect(annotation2.parameters.startCharacterIndex == 0)
        #expect(annotation2.parameters.endCharacterIndex == 0)
        guard case let .entity(type, text) = annotation2.parameters.type else {
            assertionFailure("Expected Entity type for annotation2")
            return
        }
        #expect(type == .name)
        #expect(text == "Entity")
        /// Third state Add Annotation.
        let annotation3 = state.annotations[2]
        #expect(annotation3.actionData.id == "3")
        #expect(annotation3.actionData.index == 3)
        #expect(annotation3.parameters.id == "3A")
        #expect(annotation3.parameters.startCharacterIndex == 0)
        #expect(annotation3.parameters.endCharacterIndex == 0)
        guard case .transcriptionTentative = annotation3.parameters.type else {
            assertionFailure("Expected TranscriptionTentative type for annotation3")
            return
        }
        #expect(sut.operationHistory.count == 4)
        #expect(sut.undoneOperations.count == 4)

        /// Roll back 2 times more.
        sut = try sut.undoOperations(count: 2)

        #expect(sut.state.text == "Attendi")
        #expect(sut.state.annotations.count == 1)
        #expect(sut.operationHistory.count == 2)
        #expect(sut.undoneOperations.count == 6)

        /// Roll back 1 more time to remove all add annotations.
        sut = try sut.undoOperations(count: 1)

        #expect(sut.state.text == "Attendi")
        #expect(sut.state.annotations.count == 0)
        #expect(sut.operationHistory.count == 1)
        #expect(sut.undoneOperations.count == 7)

        /// Roll back 1 more time to remove the replace text annotation.
        sut = try sut.undoOperations(count: 1)

        #expect(sut.state.text == "")
        #expect(sut.state.annotations.count == 0)
        #expect(sut.operationHistory.count == 0)
        #expect(sut.undoneOperations.count == 8)
    }

    @Test
    func undoOperations_whenIndexIsBeyondOperationHistoryBounds_returnsEmptyTranscribeState() throws {
        let attendiStreamState = AttendiStreamState(
            text: "",
            annotations: []
        )

        var initialStream = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        initialStream = try initialStream.receiveActions(TranscribeAsyncActionFactory.createSample())

        let sut = try initialStream.undoOperations(count: 20)

        #expect(sut.state.text == "")
        #expect(sut.state.annotations.isEmpty)
        #expect(sut.operationHistory.isEmpty)
        #expect(sut.undoneOperations.count == 8)
    }

    @Test
    func redoOperations_whenIndexIsWithinUndoneOperationsBounds_returnsNextTranscribeState() throws {
        let attendiStreamState = AttendiStreamState(
            text: "",
            annotations: []
        )

        var initialStream = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        initialStream = try initialStream.receiveActions(TranscribeAsyncActionFactory.createSample())

        var sut = try initialStream
            .undoOperations(count: 4)
            .redoOperations(count: 1)

        let state = sut.state
        #expect(state.text == "Attendi")
        #expect(state.annotations.count == 2)

        /// First state Add Annotation.
        let annotation1 = state.annotations[0]
        #expect(annotation1.actionData.id == "1")
        #expect(annotation1.actionData.index == 1)
        #expect(annotation1.parameters.id == "1A")
        #expect(annotation1.parameters.startCharacterIndex == 0)
        #expect(annotation1.parameters.endCharacterIndex == 0)
        guard case .transcriptionTentative = annotation1.parameters.type else {
            assertionFailure("Expected TranscriptionTentative for annotation1")
            return
        }
        /// Second state Add Annotation.
        let annotation2 = state.annotations[1]
        #expect(annotation2.actionData.id == "2")
        #expect(annotation2.actionData.index == 2)
        #expect(annotation2.parameters.id == "2A")
        #expect(annotation2.parameters.startCharacterIndex == 0)
        #expect(annotation2.parameters.endCharacterIndex == 0)
        guard case .entity(let annotation2Type, let annotation2Text) = annotation2.parameters.type else {
            assertionFailure("Expected Entity type for annotation2")
            return
        }
        #expect(annotation2Type == .name)
        #expect(annotation2Text == "Entity")
        #expect(sut.operationHistory.count == 5)
        #expect(sut.undoneOperations.count == 3)

        /// Redo 2 times more.
        sut = try sut.redoOperations(count: 2)

        #expect(sut.state.text == "Attendi")
        #expect(sut.state.annotations.count == 4)
        #expect(sut.operationHistory.count == 7)
        #expect(sut.undoneOperations.count == 1)

        /// Redo 1 time more, back to original.
        sut = try sut.redoOperations(count: 1)

        #expect(sut.state.annotations.count == 4)
        #expect(sut.operationHistory.count == 8)
        #expect(sut.undoneOperations.isEmpty)
        #expect(sut.state.text == initialStream.state.text)
        #expect(sut.state.annotations.count == initialStream.state.annotations.count)
        #expect(sut.operationHistory.count == initialStream.operationHistory.count)
        #expect(sut.undoneOperations.count == initialStream.undoneOperations.count)
    }

    @Test
    func redoOperations_whenIndexIsBeyondUndoneOperationsBounds_returnsOriginalTranscribeState() throws {
        let attendiStreamState = AttendiStreamState(
            text: "",
            annotations: []
        )

        var initialStream = AttendiTranscribeStream(
            state: attendiStreamState,
            operationHistory: [],
            undoneOperations: []
        )

        initialStream = try initialStream.receiveActions(TranscribeAsyncActionFactory.createSample())

        let sut = try initialStream.undoOperations(count: 4).redoOperations(count: 20)

        #expect(sut.state.annotations.count == 4)
        #expect(sut.operationHistory.count == 8)
        #expect(sut.undoneOperations.isEmpty)
        #expect(sut.state.text == initialStream.state.text)
        #expect(sut.state.annotations == initialStream.state.annotations)
        #expect(sut.operationHistory == initialStream.operationHistory)
        #expect(sut.undoneOperations == initialStream.undoneOperations)
    }
}
