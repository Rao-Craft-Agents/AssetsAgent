import Foundation

/// The name a line starts with and what follows it: `name: rest`, `name = rest`, or `name rest`.
enum LineHead {
    static func split(_ line: String) -> (name: String, rest: String)? {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let mark = text.firstIndex(where: { $0 == ":" || $0 == "=" }) {
            return (String(text[..<mark]).trimmingCharacters(in: .whitespaces), String(text[text.index(after: mark)...]).trimmingCharacters(in: .whitespaces))
        }
        guard let space = text.firstIndex(of: " ") else { return (text, "") }
        return (String(text[..<space]), String(text[space...]).trimmingCharacters(in: .whitespaces))
    }

    /// Whether `name` can name an asset: a letter, then letters, digits, `_`, `-` or `.`.
    static func isAssetName(_ name: String) -> Bool {
        name.range(of: #"^[A-Za-z][A-Za-z0-9_.-]*$"#, options: .regularExpression) != nil
    }
}
