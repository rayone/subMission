import Foundation
import TransmissionRPC

// MARK: - TableChangeset

public struct TableChangeset {
    public let deletions: IndexSet      // pre-mutation row indices
    public let insertions: IndexSet     // post-deletion row indices
    public let moves: [(from: Int, to: Int)]
    public let reloads: IndexSet        // post-mutation row indices (same id, changed content)

    public static let empty = TableChangeset(deletions: [], insertions: [], moves: [], reloads: [])
}

// MARK: - computeChangeset

public func computeChangeset<T: Identifiable & ContentEquatable>(
    old: [T], new: [T]
) -> TableChangeset where T.ID: Hashable {
    // Build identity maps
    let oldMap = Dictionary(uniqueKeysWithValues: old.enumerated().map { ($1.id, $0) })
    let newMap = Dictionary(uniqueKeysWithValues: new.enumerated().map { ($1.id, $0) })

    var deletions = IndexSet()
    var insertions = IndexSet()
    var moves: [(from: Int, to: Int)] = []
    var reloads = IndexSet()

    // Find deleted rows (in old but not in new)
    for (id, oldIndex) in oldMap {
        if newMap[id] == nil {
            deletions.insert(oldIndex)
        }
    }

    // Find inserted rows (in new but not in old)
    for (id, newIndex) in newMap {
        if oldMap[id] == nil {
            insertions.insert(newIndex)
        }
    }

    // Find moves and reloads (in both old and new)
    for (id, newIndex) in newMap {
        guard let oldIndex = oldMap[id] else { continue }
        let newItem = new[newIndex]
        let oldItem = old[oldIndex]

        if oldIndex != newIndex {
            moves.append((from: oldIndex, to: newIndex))
        }

        if !newItem.isContentEqual(to: oldItem) {
            reloads.insert(newIndex)
        }
    }

    return TableChangeset(
        deletions: deletions,
        insertions: insertions,
        moves: moves,
        reloads: reloads
    )
}
