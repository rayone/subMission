import AppKit
import TransmissionRPC

// MARK: - File tree node

final class FileNode {
    let name: String
    var children: [FileNode] = []
    var fileIndex: Int?          // nil for folder nodes
    var file: TorrentFile?

    // Aggregated folder values
    var totalLength: Int64     = 0
    var bytesCompleted: Int64  = 0
    var wanted: Bool           = true
    var priority: BandwidthPriority = .normal

    init(name: String) { self.name = name }

    var isFolder: Bool { !children.isEmpty }
    var progress: Double { totalLength > 0 ? Double(bytesCompleted) / Double(totalLength) : 0 }
}

// MARK: - FileTreeBuilder

enum FileTreeBuilder {
    static func build(from files: [TorrentFile]) -> [FileNode] {
        let root = FileNode(name: "/")
        for (idx, file) in files.enumerated() {
            let parts = file.name.split(separator: "/").map(String.init)
            insert(parts: parts, into: root, index: idx, file: file)
        }
        aggregate(root)
        return root.children
    }

    private static func insert(parts: [String], into parent: FileNode, index: Int, file: TorrentFile) {
        guard let head = parts.first else { return }
        if parts.count == 1 {
            let leaf = FileNode(name: head)
            leaf.fileIndex = index
            leaf.file = file
            leaf.totalLength    = file.length
            leaf.bytesCompleted = file.bytesCompleted
            leaf.wanted         = file.wanted
            leaf.priority       = file.priority
            parent.children.append(leaf)
        } else {
            let folder = parent.children.first { $0.name == head && $0.isFolder }
                ?? { let n = FileNode(name: head); parent.children.append(n); return n }()
            insert(parts: Array(parts.dropFirst()), into: folder, index: index, file: file)
        }
    }

    private static func aggregate(_ node: FileNode) {
        guard node.isFolder else { return }
        node.children.forEach { aggregate($0) }
        node.totalLength    = node.children.reduce(0) { $0 + $1.totalLength }
        node.bytesCompleted = node.children.reduce(0) { $0 + $1.bytesCompleted }
        node.wanted         = node.children.allSatisfy { $0.wanted }
        let priorities      = Set(node.children.map { $0.priority })
        node.priority       = priorities.count == 1 ? priorities.first! : .normal
    }
    
    static func updateProgress(in nodes: [FileNode], with files: [TorrentFile]) {
        for node in nodes {
            if node.isFolder {
                updateProgress(in: node.children, with: files)
                node.bytesCompleted = node.children.reduce(0) { $0 + $1.bytesCompleted }
                node.wanted         = node.children.allSatisfy { $0.wanted }
                let priorities      = Set(node.children.map { $0.priority })
                node.priority       = priorities.count == 1 ? priorities.first! : .normal
            } else if let index = node.fileIndex, index < files.count {
                let file = files[index]
                node.bytesCompleted = file.bytesCompleted
                node.wanted         = file.wanted
                node.priority       = file.priority
                node.file           = file
            }
        }
    }
}
