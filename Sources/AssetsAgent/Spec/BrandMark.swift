import Foundation

/// What the brand's mark is: letters, a glyph, or a picture the project has.
enum BrandMark: Sendable, Equatable {
    case monogram(String)
    case shape(AssetsShape)
    case image(Picture)
}
