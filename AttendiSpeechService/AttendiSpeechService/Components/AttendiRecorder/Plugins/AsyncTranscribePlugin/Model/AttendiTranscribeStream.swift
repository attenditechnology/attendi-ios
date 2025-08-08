import Foundation

/// Represents the current state and history of a real-time transcription stream,
/// with support for undo and redo operations.
///
/// This model is updated incrementally as transcription events (i.e., `TranscribeAsyncAction`s)
/// are received over time via WebSocket. It maintains an operation history and supports undoing or
/// redoing previously applied actions using their inverse representations.
///
/// The main entry point for updating this model is the `receiveActions` method,
/// which applies new transcription actions, updates the internal state accordingly,
/// and maintains undo/redo history.
///
/// - Parameters:
///   - state: The current transcribed text and annotation state.
///   - operationHistory: The chronological list of applied transcription actions, each paired with its inverse.
///   - undoneOperations: A stack of recently undone actions, enabling redo functionality.
public struct AttendiTranscribeStream {
    public let state: AttendiStreamState
    public let operationHistory: [UndoableTranscribeAction]
    public let undoneOperations: [UndoableTranscribeAction]
    
    public init(
        state: AttendiStreamState = AttendiStreamState(text: "", annotations: []),
        operationHistory: [UndoableTranscribeAction] = [],
        undoneOperations: [UndoableTranscribeAction] = []
    ) {
        self.state = state
        self.operationHistory = operationHistory
        self.undoneOperations = undoneOperations
    }
    
    /// Updates the stream with a new list of `TranscribeAsyncAction`s.
    ///
    /// Applies the actions to the current `state` and appends them to the `operationHistory`.
    ///
    /// - Parameter actions: The list of actions to apply to this stream.
    /// - Returns: A new updated `AttendiTranscribeStream` with modified state and extended history.
    public func receiveActions(_ actions: [TranscribeAsyncAction]) throws -> AttendiTranscribeStream {
        let newState = try state.apply(actions: actions)
        let newHistory = try operationHistory + UndoableTranscribeAsyncActionMapper.map(currentState: state, actions: actions)
        return AttendiTranscribeStream(
            state: newState,
            operationHistory: newHistory,
            undoneOperations: []
        )
    }
    
    /// Undo the last `count` operations, returning a new `AttendiTranscribeStream`.
    ///
    /// - Parameter count: The number of operations to undo.
    /// - Returns: A new `AttendiTranscribeStream` with the undone operations.
    public func undoOperations(count: Int) throws -> AttendiTranscribeStream {
        guard count >= 0 else {
            fatalError("Undo count must be non-negative")
        }
        
        let toUndo = Array(operationHistory.suffix(count))
        let remainingHistory = Array(operationHistory.dropLast(count))
        let inverseActions = toUndo.flatMap { $0.inverse.reversed() }
        let reversedActions = Array(inverseActions.reversed())
        let newState = try state.apply(actions: reversedActions)

        return AttendiTranscribeStream(
            state: newState,
            operationHistory: remainingHistory,
            undoneOperations: toUndo + undoneOperations
        )
    }
    
    /// Redo the last `count` operations, returning a new `AttendiTranscribeStream`.
    ///
    /// - Parameter count: The number of operations to redo.
    /// - Returns: A new `AttendiTranscribeStream` with the redone operations.
    public func redoOperations(count: Int) throws -> AttendiTranscribeStream {
        guard count >= 0 else {
            fatalError("Redo count must be non-negative")
        }
        
        guard !undoneOperations.isEmpty else {
            return self
        }
        
        let toRedo = Array(undoneOperations.prefix(count))
        let remainingUndone = Array(undoneOperations.dropFirst(count))
        let redoActions = toRedo.compactMap { $0.original }
        
        let newState = try state.apply(actions: redoActions)
        let newHistory = operationHistory + toRedo
        
        return AttendiTranscribeStream(
            state: newState,
            operationHistory: newHistory,
            undoneOperations: remainingUndone
        )
    }
}

/// Represents the current state of the transcript, including its text content and annotations.
///
/// This state evolves over time as actions such as text replacements, additions, or annotation updates occur.
///
/// - Parameters:
///   - text: The current transcript text.
///   - annotations: A list of current annotations applied to the text.
public struct AttendiStreamState {
    public let text: String
    public let annotations: [TranscribeAsyncAction.AddAnnotation]

    public init(text: String, annotations: [TranscribeAsyncAction.AddAnnotation]) {
        self.text = text
        self.annotations = annotations
    }
    
    /// Applies a series of `TranscribeAsyncAction`s to this state and returns a new updated state.
    ///
    /// The following actions are supported:
    /// - `TranscribeAsyncAction.AddAnnotation`: Appends a new annotation.
    /// - `TranscribeAsyncAction.RemoveAnnotation`: Removes annotation(s) by ID.
    /// - `TranscribeAsyncAction.ReplaceText`: Replaces a portion of the text using character indices.
    /// - `TranscribeAsyncAction.UpdateAnnotation`: Updates properties of an existing annotation.
    ///
    /// - Parameter actions: The actions to apply in sequence.
    /// - Returns: A new `AttendiStreamState` after all actions have been applied.
    public func apply(actions: [TranscribeAsyncAction]) throws -> AttendiStreamState {
        var currentText = text
        var currentAnnotations = annotations
        
        for action in actions {
            switch action {
            case .addAnnotation(let addAnnotation):
                currentAnnotations.append(addAnnotation)

            case .removeAnnotation(let removeAnnotation):
                currentAnnotations.removeAll {
                    removeAnnotation.parameters.id == $0.parameters.id
                }
                
            case .replaceText(let replaceText):
                currentText = try TranscribeAsyncReplaceTextMapper.map(original: currentText, params: replaceText.parameters)

            case .updateAnnotation(let updateAnnotationAction):
                currentAnnotations = updateAnnotation(currentAnnotations: currentAnnotations, action: updateAnnotationAction)
            }
        }
        
        return AttendiStreamState(text: currentText, annotations: currentAnnotations)
    }
    
    private func updateAnnotation(
        currentAnnotations: [TranscribeAsyncAction.AddAnnotation],
        action: TranscribeAsyncAction.UpdateAnnotation
    ) -> [TranscribeAsyncAction.AddAnnotation] {
        var updatedAnnotations = currentAnnotations
        if let index = updatedAnnotations.firstIndex(where: {
            $0.parameters.id == action.parameters.id
        }) {
            updatedAnnotations[index] = TranscribeAsyncAction.AddAnnotation(
                actionData: action.actionData,
                parameters: action.parameters
            )
        }
        return updatedAnnotations
    }
}
