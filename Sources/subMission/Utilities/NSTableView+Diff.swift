import AppKit

extension NSTableView {
    /// Apply a TableChangeset with animated insertions/deletions/moves/reloads.
    func applyChangeset(_ changeset: TableChangeset, withAnimation animation: NSTableView.AnimationOptions = .effectFade) {
        // Safety: if changeset is empty, do nothing
        if changeset.deletions.isEmpty && changeset.insertions.isEmpty
            && changeset.moves.isEmpty && changeset.reloads.isEmpty {
            return
        }

        beginUpdates()

        // 1. Deletions (by pre-mutation index)
        if !changeset.deletions.isEmpty {
            removeRows(at: changeset.deletions, withAnimation: animation)
        }

        // 2. Insertions (by post-mutation index)
        if !changeset.insertions.isEmpty {
            insertRows(at: changeset.insertions, withAnimation: animation)
        }

        // 3. Moves
        for move in changeset.moves {
            moveRow(at: move.from, to: move.to)
        }

        endUpdates()

        // 4. Reloads (done outside updates block to avoid animation conflicts)
        if !changeset.reloads.isEmpty {
            reloadData(forRowIndexes: changeset.reloads, columnIndexes: IndexSet(integersIn: 0..<numberOfColumns))
        }
    }
}
