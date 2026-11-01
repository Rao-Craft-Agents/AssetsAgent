//  WHAT: The placeholder sets, in a `Placeholder` folder that names them `Placeholder/Avatar`: the neutral avatar
//        (light and dark) a view shows for someone with no picture, and four sample avatars for previews and seed data.

import Foundation

enum PlaceholderSets {
    static func make(_ painter: AvatarPainter) throws -> [CatalogSet] {
        var sets = [ImageSets.vector("Placeholder/Avatar", light: painter.neutral(dark: false, side: 128), dark: painter.neutral(dark: true, side: 128), rendering: "original")]
        for index in AvatarPainter.samples.indices {
            sets.append(ImageSets.vector("Placeholder/Avatar\(index + 1)", light: try painter.sample(index, side: 128), dark: nil, rendering: "original"))
        }
        return sets
    }
}
