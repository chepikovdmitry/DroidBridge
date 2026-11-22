import Foundation

public enum TransferName {
    public static func isComponent(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.utf8.contains(0)
    }

    public static func available(_ name: String, among names: [String], isFolder: Bool = false) -> String {
        Index(names).available(name, isFolder: isFolder)
    }

    public struct Index {
        private var existing: Set<String>

        public init(_ names: [String]) {
            existing = Set(names.map(Self.key))
        }

        public mutating func insert(_ name: String) {
            existing.insert(Self.key(name))
        }

        public func available(_ name: String, isFolder: Bool = false) -> String {
            guard existing.contains(Self.key(name)) else { return name }

            let ext = isFolder ? "" : (name as NSString).pathExtension
            let base = ext.isEmpty ? name : (name as NSString).deletingPathExtension
            let suffix = ext.isEmpty ? "" : "." + ext
            var number = 2
            while true {
                let candidate = "\(base) \(number)\(suffix)"
                if !existing.contains(Self.key(candidate)) { return candidate }
                number += 1
            }
        }

        private static func key(_ name: String) -> String {
            name.precomposedStringWithCanonicalMapping.folding(options: .caseInsensitive, locale: nil)
        }
    }
}
