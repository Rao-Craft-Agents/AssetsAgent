import Foundation

/// A symbol set a symbol line: its SF Symbols template and the `Contents.json` that names it.
enum SymbolSets {
    static func make(_ symbol: SymbolSpec) -> CatalogSet {
        let file = "\(symbol.name).svg"
        return CatalogSet(folder: "\(symbol.name).symbolset", name: symbol.name,
                          files: [.contents(CatalogContents.symbolSet(file: file)), CatalogFile(path: file, data: Data(SymbolTemplate.svg(symbol).utf8))])
    }
}
