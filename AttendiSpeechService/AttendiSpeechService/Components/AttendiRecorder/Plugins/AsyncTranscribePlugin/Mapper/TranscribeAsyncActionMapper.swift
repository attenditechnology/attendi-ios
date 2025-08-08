import Foundation

/// Utility object responsible for mapping a `TranscribeAsyncResponse`
/// to a list of `TranscribeAsyncAction`s.
///
/// This mapper was implemented manually rather than using a JSON schema-based code generator
/// to reduce cognitive overhead and improve maintainability. JSON schema generators often
/// produce different outputs for Kotlin and Swift, leading to inconsistencies between platforms
/// in a multiplatform codebase.
///
/// By mapping manually, we ensure a consistent and predictable model structure across platforms,
/// which simplifies testing, debugging, and long-term evolution of the data layer.
public struct TranscribeAsyncActionMapper {

    /// Maps a `TranscribeAsyncResponse` to a list of `TranscribeAsyncAction` objects.
    ///
    /// - Parameter response: The response from the transcription service.
    /// - Returns: A list of domain-level actions.
    public static func map(response: TranscribeAsyncResponse) throws -> [TranscribeAsyncAction] {
        try response.actions.map { action in
            switch action.type {
            case .addAnnotation:
                return try mapAddAnnotation(action)
            case .updateAnnotation:
                return try mapUpdateAnnotation(action)
            case .removeAnnotation:
                return try mapRemoveAnnotation(action)
            case .replaceText:
                return try mapReplaceTextAnnotation(action)
            }
        }
    }

    private static func mapAddAnnotation(_ action: TranscribeAsyncAnnotationResponse) throws -> TranscribeAsyncAction {
        guard let parameters = action.parameters else {
            throw TranscriptionMappingError.missingField("parameters in AddAnnotation")
        }

        switch parameters.type {
        case .transcriptionTentative:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in AddAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in AddAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in AddAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }

            return .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .transcriptionTentative
                    )
                )
            )

        case .intent:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in AddAnnotation INTENT Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in AddAnnotation INTENT Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in AddAnnotation INTENT Parameters")
            }
            guard let statusResponse = parameters.parameters?.status else {
                throw TranscriptionMappingError.missingField("status in AddAnnotation INTENT Parameters")
            }

            let status: TranscribeAsyncAnnotationIntentStatus = {
                switch statusResponse {
                case .pending: return .pending
                case .recognized: return .recognized
                }
            }()

            return .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .intent(status: status)
                    )
                )
            )

        case .entity:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in AddAnnotation ENTITY Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in AddAnnotation ENTITY Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in AddAnnotation ENTITY Parameters")
            }
            guard let typeResponse = parameters.parameters?.type else {
                throw TranscriptionMappingError.missingField("type in AddAnnotation ENTITY Parameters")
            }
            guard let text = parameters.parameters?.text else {
                throw TranscriptionMappingError.missingField("text in AddAnnotation ENTITY Parameters")
            }

            let type: TranscribeAsyncAnnotationEntityType = {
                switch typeResponse {
                case .name: return .name
                }
            }()

            return .addAnnotation(
                TranscribeAsyncAction.AddAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .entity(type: type, text: text)
                    )
                )
            )

        case .none:
            throw TranscriptionMappingError.missingField("type in AddAnnotation Parameters")
        }
    }

    private static func mapUpdateAnnotation(_ action: TranscribeAsyncAnnotationResponse) throws -> TranscribeAsyncAction {
        guard let parameters = action.parameters else {
            throw TranscriptionMappingError.missingField("parameters in UpdateAnnotation")
        }

        switch parameters.type {
        case .transcriptionTentative:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in UpdateAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in UpdateAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in UpdateAnnotation TRANSCRIPTION_TENTATIVE Parameters")
            }

            return .updateAnnotation(
                TranscribeAsyncAction.UpdateAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .transcriptionTentative
                    )
                )
            )

        case .intent:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in UpdateAnnotation INTENT Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in UpdateAnnotation INTENT Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in UpdateAnnotation INTENT Parameters")
            }
            guard let statusResponse = parameters.parameters?.status else {
                throw TranscriptionMappingError.missingField("status in UpdateAnnotation INTENT Parameters")
            }

            let status: TranscribeAsyncAnnotationIntentStatus = {
                switch statusResponse {
                case .pending: return .pending
                case .recognized: return .recognized
                }
            }()

            return .updateAnnotation(
                TranscribeAsyncAction.UpdateAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .intent(status: status)
                    )
                )
            )

        case .entity:
            guard let id = parameters.id else {
                throw TranscriptionMappingError.missingField("id in UpdateAnnotation ENTITY Parameters")
            }
            guard let start = parameters.startCharacterIndex else {
                throw TranscriptionMappingError.missingField("startCharacterIndex in UpdateAnnotation ENTITY Parameters")
            }
            guard let end = parameters.endCharacterIndex else {
                throw TranscriptionMappingError.missingField("endCharacterIndex in UpdateAnnotation ENTITY Parameters")
            }
            guard let typeResponse = parameters.parameters?.type else {
                throw TranscriptionMappingError.missingField("type in UpdateAnnotation ENTITY Parameters")
            }
            guard let text = parameters.parameters?.text else {
                throw TranscriptionMappingError.missingField("text in UpdateAnnotation ENTITY Parameters")
            }

            let type: TranscribeAsyncAnnotationEntityType = {
                switch typeResponse {
                case .name: return .name
                }
            }()

            return .updateAnnotation(
                TranscribeAsyncAction.UpdateAnnotation(
                    actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                    parameters: TranscribeAsyncAnnotationParameters(
                        id: id,
                        startCharacterIndex: start,
                        endCharacterIndex: end,
                        type: .entity(type: type, text: text)
                    )
                )
            )

        case .none:
            throw TranscriptionMappingError.missingField("type in UpdateAnnotation Parameters")
        }
    }

    private static func mapRemoveAnnotation(_ action: TranscribeAsyncAnnotationResponse) throws -> TranscribeAsyncAction {
        guard let parameters = action.parameters else {
            throw TranscriptionMappingError.missingField("parameters in RemoveAnnotation")
        }
        guard let id = parameters.id else {
            throw TranscriptionMappingError.missingField("id in REMOVE_ANNOTATION")
        }

        return .removeAnnotation(
            TranscribeAsyncAction.RemoveAnnotation(
                actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                parameters: TranscribeAsyncRemoveAnnotationParameters(id: id)
            )
        )
    }

    private static func mapReplaceTextAnnotation(_ action: TranscribeAsyncAnnotationResponse) throws -> TranscribeAsyncAction {
        guard let parameters = action.parameters else {
            throw TranscriptionMappingError.missingField("parameters in ReplaceTextAnnotation")
        }
        guard let start = parameters.startCharacterIndex else {
            throw TranscriptionMappingError.missingField("startCharacterIndex in REPLACE_TEXT Parameters")
        }
        guard let end = parameters.endCharacterIndex else {
            throw TranscriptionMappingError.missingField("endCharacterIndex in REPLACE_TEXT Parameters")
        }
        guard let text = parameters.text else {
            throw TranscriptionMappingError.missingField("text in REPLACE_TEXT Parameters")
        }

        return .replaceText(
            TranscribeAsyncAction.ReplaceText(
                actionData: TranscribeAsyncActionData(id: action.id, index: action.index),
                parameters: TranscribeAsyncReplaceTextParameters(
                    text: text,
                    startCharacterIndex: start,
                    endCharacterIndex: end
                )
            )
        )
    }
}

enum TranscriptionMappingError: Error, LocalizedError {
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .missingField(let field):
            return "Missing required field: \(field)"
        }
    }
}
