import Foundation

/// The appearance a catalog entry is for, beside the one every set has (any appearance, normal contrast).
enum CatalogAppearance: Equatable, Sendable {
    case dark
    /// An iOS app icon's tinted appearance: a greyscale image the system tints.
    case tinted
    case highContrast
    case darkHighContrast

    /// The `appearances` array of the entry: luminosity first, then contrast, as Xcode orders them (its own system
    /// colour sets list any, dark, then high contrast, then dark in high contrast).
    var json: CatalogJSON {
        func pair(_ appearance: String, _ value: String) -> CatalogJSON {
            .object(["appearance": .string(appearance), "value": .string(value)])
        }
        switch self {
        case .dark: return .array([pair("luminosity", "dark")])
        case .tinted: return .array([pair("luminosity", "tinted")])
        case .highContrast: return .array([pair("contrast", "high")])
        case .darkHighContrast: return .array([pair("luminosity", "dark"), pair("contrast", "high")])
        }
    }
}
