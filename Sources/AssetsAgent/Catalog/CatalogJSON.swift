//  WHAT: A JSON value as an asset catalog's `Contents.json` holds it, and the text Xcode writes for it: two-space
//        indents, `"key" : value`, keys sorted, slashes left alone, a newline after the closing brace.
//  PIN:  BYTE FOR BYTE AS XCODE WRITES IT. A catalog Xcode opens and saves again must not change, or every call
//        leaves a diff the person did not make; the format is pinned by golden tests.

import Foundation

indirect enum CatalogJSON: Equatable, Sendable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([CatalogJSON])
    case object([String: CatalogJSON])

    /// The file's text, as Xcode writes it.
    var text: String { written(indent: 0) + "\n" }

    /// The file's bytes.
    var data: Data { Data(text.utf8) }

    private func written(indent: Int) -> String {
        let inner = String(repeating: " ", count: indent + 2), outer = String(repeating: " ", count: indent)
        switch self {
        case .string(let value): return Self.quoted(value)
        case .int(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        case .array(let items):
            guard !items.isEmpty else { return "[\n\n\(outer)]" }
            return "[\n" + items.map { inner + $0.written(indent: indent + 2) }.joined(separator: ",\n") + "\n\(outer)]"
        case .object(let fields):
            guard !fields.isEmpty else { return "{\n\n\(outer)}" }
            let lines = fields.keys.sorted().map { key in inner + Self.quoted(key) + " : " + fields[key]!.written(indent: indent + 2) }
            return "{\n" + lines.joined(separator: ",\n") + "\n\(outer)}"
        }
    }

    private static func quoted(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 { out += String(format: "\\u%04x", scalar.value) } else { out.unicodeScalars.append(scalar) }
            }
        }
        return out + "\""
    }
}
