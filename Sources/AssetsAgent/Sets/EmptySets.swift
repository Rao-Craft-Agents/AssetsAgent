//  WHAT: The empty-state sets, in an `Empty` folder that names them `Empty/Inbox`, `Empty/Search`, `Empty/Offline`
//        and `Empty/Error`: what a list shows when it has nothing, light and dark.

import Foundation

enum EmptySets {
    static func make(_ painter: EmptyPainter) -> [CatalogSet] {
        EmptyPainter.Scene.allCases.map { scene in
            ImageSets.vector("Empty/\(scene.rawValue)", light: painter.draw(scene, dark: false, side: 160), dark: painter.draw(scene, dark: true, side: 160), rendering: "original")
        }
    }
}
