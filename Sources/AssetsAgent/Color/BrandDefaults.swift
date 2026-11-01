//  WHAT: The brand colours a call that names none is drawn in: ten two-stop gradients, one picked by the app's name
//        so the same name always gets the same colours and two apps rarely share them.

import Foundation

enum BrandDefaults {
    /// Top and bottom of each gradient.
    static let gradients: [(String, String)] = [
        ("#6C72E8", "#4338B8"),   // indigo dusk
        ("#1FB5A6", "#0B6E6A"),   // lagoon
        ("#FF8A65", "#E2496B"),   // coral
        ("#4CAF7D", "#1E6448"),   // forest
        ("#A66CF0", "#6A2FC8"),   // plum
        ("#4A90F2", "#1D47B0"),   // ocean
        ("#F7B23B", "#E0661B"),   // amber
        ("#5D6472", "#22262E"),   // graphite
        ("#F25C78", "#B4204A"),   // rose
        ("#7FA88A", "#46685A"),   // sage
    ]

    /// The gradient for `name`, picked by a hash that does not change between runs.
    static func gradient(for name: String) -> [SRGBColor] {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in name.lowercased().utf8 { hash = (hash ^ UInt64(byte)) &* 0x100000001b3 }
        let pair = gradients[Int(hash % UInt64(gradients.count))]
        return [SRGBColor(hex: pair.0)!, SRGBColor(hex: pair.1)!]
    }
}
