//  WHAT: The asset catalog compiler's verdict on a catalog for one platform: `xcrun actool` compiles it into a
//        folder of its own and its plist answer is read for errors, warnings and notices.
//  PIN:  NEVER PRINT. actool's answer is read off its own pipe; stdout is the wire's.
//  PIN:  A missing toolchain is not a failure of the catalog: with no `xcrun` there is no verdict, and nil says so.

import Foundation

enum ActoolCheck {
    /// Compiles `catalog` for `target` into `output`; nil when there is no toolchain to ask.
    static func compile(_ catalog: URL, for target: ActoolTarget, into output: URL) throws -> ActoolReport? {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/xcrun") else { return nil }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var arguments = ["actool", catalog.path, "--compile", output.path, "--platform", target.platform,
                         "--minimum-deployment-target", target.deployment,
                         "--output-partial-info-plist", output.appendingPathComponent("partial.plist").path,
                         "--output-format", "xml1", "--errors", "--warnings", "--notices"]
        for device in target.devices { arguments += ["--target-device", device] }
        if let icon = target.appIcon { arguments += ["--app-icon", icon] }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments
        let answer = Pipe()
        process.standardOutput = answer
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let data = answer.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return report(from: data, status: process.terminationStatus)
    }

    /// actool's plist answer, read. An answer that is not a plist is an error in itself.
    static func report(from data: Data, status: Int32) -> ActoolReport {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return ActoolReport(errors: status == 0 ? [] : ["actool answered \(status): \(text.prefix(400))"])
        }
        func lines(_ key: String) -> [String] {
            ((plist[key] as? [[String: Any]]) ?? []).compactMap { item in
                let text = (item["message"] as? String) ?? (item["description"] as? String)
                guard let text else { return nil }
                let item = (item["affected-items"] as? [String])?.first.map { " (\($0))" } ?? ""
                return text + item
            }
        }
        var report = ActoolReport()
        report.errors = lines("com.apple.actool.errors") + lines("com.apple.actool.document.errors")
        report.warnings = lines("com.apple.actool.document.warnings") + lines("com.apple.actool.warnings")
        report.notices = lines("com.apple.actool.document.notices") + lines("com.apple.actool.notices")
        report.outputs = ((plist["com.apple.actool.compilation-results"] as? [String: Any])?["output-files"] as? [String]) ?? []
        if status != 0, report.errors.isEmpty { report.errors = ["actool answered \(status)"] }
        return report
    }
}
