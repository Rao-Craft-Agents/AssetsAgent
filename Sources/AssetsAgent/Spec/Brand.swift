import Foundation

/// The brand a call draws: the app's name, its wordmark, its mark, the faces it is set in, and its colours.
struct Brand: Sendable, Equatable {
    var name: String
    var wordmark: String
    var mark: BrandMark
    var fonts: FontChoice
    var tones: BrandTones
}
