import Foundation

/// Represents a transcription action paired with its inverse, enabling undo and redo functionality.
///
/// This structure allows the system to efficiently revert previous operations by storing both
/// the original action and its corresponding inverse. The inverse is precomputed to avoid
/// recalculating how to undo the operation at runtime.
///
/// - Parameters:
///   - original: The original `TranscribeAsyncAction` that was applied to the transcription stream.
///   - inverse: A list of actions that, when applied, revert the effects of the original action.
/// For example, undoing an `TranscribeAsyncAction.UpdateAnnotation` action may require both
/// a remove and an add action to restore the original state.
public struct UndoableTranscribeAction: Equatable {
    public let original: TranscribeAsyncAction
    public let inverse: [TranscribeAsyncAction]
    
    public init(original: TranscribeAsyncAction, inverse: [TranscribeAsyncAction]) {
        self.original = original
        self.inverse = inverse
    }
} 
