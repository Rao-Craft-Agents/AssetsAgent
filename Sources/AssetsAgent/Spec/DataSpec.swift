import Foundation

/// One data set a data line names: its name and the file it holds, as the line wrote the path.
struct DataSpec: Equatable, Sendable {
    var name: String
    var path: String
}
