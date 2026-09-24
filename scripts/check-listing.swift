// Counts every App Store Connect field in a listing document against Apple's
// limits, so a field is not discovered to be too long by pasting it in.
//
//   xcrun swift check-listing.swift app-store-listing.md
//
// Reads the convention used by templates/app-store-listing.md: a heading whose
// text contains a limit in parentheses, followed by a fenced code block holding
// the value. Anything else in the document is ignored.

import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: check-listing.swift <listing.md>\n".utf8))
    exit(2)
}

guard let document = try? String(contentsOf: URL(fileURLWithPath: arguments[1]), encoding: .utf8) else {
    FileHandle.standardError.write(Data("could not read \(arguments[1])\n".utf8))
    exit(1)
}

struct Field {
    let name: String
    let limit: Int
    let value: String
}

var fields: [Field] = []
var pendingName: String?
var pendingLimit: Int?
var isInsideBlock = false
var buffer: [String] = []

for line in document.components(separatedBy: .newlines) {
    if line.hasPrefix("#") {
        let heading = line.drop(while: { $0 == "#" || $0 == " " })
        if let open = heading.firstIndex(of: "("), let close = heading.firstIndex(of: ")"),
           open < close,
           let limit = Int(heading[heading.index(after: open) ..< close]
               .prefix(while: { $0.isNumber })) {
            pendingName = String(heading[heading.startIndex ..< open]).trimmingCharacters(in: .whitespaces)
            pendingLimit = limit
        } else {
            pendingName = nil
            pendingLimit = nil
        }
        continue
    }

    if line.hasPrefix("```") {
        if isInsideBlock {
            if let name = pendingName, let limit = pendingLimit {
                fields.append(Field(name: name, limit: limit, value: buffer.joined(separator: "\n")))
                pendingName = nil
                pendingLimit = nil
            }
            buffer = []
        }
        isInsideBlock.toggle()
        continue
    }

    if isInsideBlock { buffer.append(line) }
}

guard !fields.isEmpty else {
    FileHandle.standardError.write(Data("no fields found — expected headings like \"## Subtitle (30)\" followed by a fenced block\n".utf8))
    exit(1)
}

var hasFailure = false
for field in fields {
    // Apple counts a paragraph-wrapped field as one string, so a value that is
    // hard-wrapped in the document is measured as a single line.
    let measured = field.name.lowercased().contains("description")
        ? field.value
        : field.value.replacingOccurrences(of: "\n", with: " ")
    let count = measured.count
    let verdict = count <= field.limit ? "ok" : "OVER by \(count - field.limit)"
    if count > field.limit { hasFailure = true }
    let name = field.name.count >= 20 ? field.name : field.name.padding(toLength: 20, withPad: " ", startingAt: 0)
    let counts = "\(count) / \(field.limit)".padding(toLength: 14, withPad: " ", startingAt: 0)
    print("\(name)  \(counts)\(verdict)")
}

exit(hasFailure ? 1 : 0)
