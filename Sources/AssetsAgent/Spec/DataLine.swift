//  WHAT: A data line, one data set: `onboarding: Resources/onboarding.json`, a name and a file in the project.

import Foundation

enum DataLine {
    static func parse(_ line: String) throws -> DataSpec {
        guard let head = LineHead.split(line), !head.rest.isEmpty else {
            throw LineRefusal("data line `\(line)` is not `name: path/to/file`")
        }
        guard LineHead.isAssetName(head.name) else {
            throw LineRefusal("data line `\(line)`: `\(head.name)` is not a data set name (a letter, then letters, digits, `_`, `-` or `.`)")
        }
        return DataSpec(name: head.name, path: head.rest.trimmingCharacters(in: CharacterSet(charactersIn: "\"'` ")))
    }
}
