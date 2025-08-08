// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Microphone {
    internal enum Loading {
      /// Microfoon laden
      internal static let title = L10n.tr("Localizable", "microphone.loading.title", fallback: "Microfoon laden")
    }
    internal enum NotRecording {
      /// Microfoon inactief
      internal static let title = L10n.tr("Localizable", "microphone.notRecording.title", fallback: "Microfoon inactief")
    }
    internal enum Processing {
      /// Microfoon verwerken
      internal static let title = L10n.tr("Localizable", "microphone.processing.title", fallback: "Microfoon verwerken")
    }
    internal enum Recording {
      /// Microfoon opnemen
      internal static let title = L10n.tr("Localizable", "microphone.recording.title", fallback: "Microfoon opnemen")
    }
  }
  internal enum NoMicrophone {
    internal enum Permission {
      internal enum Dialog {
        /// Zonder toegang tot uw microfoon kan geen geluid opgenomen worden. Geef de app toegang tot uw microfoon in uw telefooninstellingen.
        internal static let body = L10n.tr("Localizable", "noMicrophone.permission.dialog.body", fallback: "Zonder toegang tot uw microfoon kan geen geluid opgenomen worden. Geef de app toegang tot uw microfoon in uw telefooninstellingen.")
        /// Geen toegang tot de microfoon
        internal static let title = L10n.tr("Localizable", "noMicrophone.permission.dialog.title", fallback: "Geen toegang tot de microfoon")
        internal enum Cancel {
          /// Annuleren
          internal static let button = L10n.tr("Localizable", "noMicrophone.permission.dialog.cancel.button", fallback: "Annuleren")
        }
        internal enum GoToSettings {
          /// Ga naar instellingen
          internal static let button = L10n.tr("Localizable", "noMicrophone.permission.dialog.goToSettings.button", fallback: "Ga naar instellingen")
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
