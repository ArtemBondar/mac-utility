import Foundation

enum ContextSummary {
    static func lines(target: URL?, selection: [URL]) -> [String] {
        let targetLine = "Target: \(target?.path ?? "(none)")"
        let selectionLines = selection.isEmpty ? ["Selection: (none)"] : selection.map { "Selection: \($0.path)" }
        return [targetLine] + selectionLines
    }
}
