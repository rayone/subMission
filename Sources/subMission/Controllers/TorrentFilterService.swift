import Foundation
import TransmissionRPC

// MARK: - FilterState

struct FilterState {
    enum StatusFilter {
        case all, downloading, seeding, completed, active, inactive, error
    }
    var statusFilter: StatusFilter = .all
    var labelFilter: String? = nil     // nil = all labels
    var searchText: String = ""

    var isDefault: Bool {
        statusFilter == .all && labelFilter == nil && searchText.isEmpty
    }
}

// MARK: - TorrentFilterService

final class TorrentFilterService {
    var state = FilterState()

    func apply(to torrents: [Torrent]) -> [Torrent] {
        var result = torrents

        // Status filter
        switch state.statusFilter {
        case .all:
            break
        case .downloading:
            result = result.filter { $0.status == .downloading || $0.status == .queuedDownload }
        case .seeding:
            result = result.filter { $0.status == .seeding || $0.status == .queuedSeed }
        case .completed:
            result = result.filter { $0.isFinished }
        case .active:
            result = result.filter { $0.rateDownload > 0 || $0.rateUpload > 0 }
        case .inactive:
            result = result.filter { $0.rateDownload == 0 && $0.rateUpload == 0 && $0.status != .stopped }
        case .error:
            result = result.filter { $0.error != 0 }
        }

        // Label filter
        if let label = state.labelFilter {
            if label.isEmpty {
                result = result.filter { $0.labels.isEmpty }
            } else {
                result = result.filter { $0.labels.contains(label) }
            }
        }

        // Search text
        if !state.searchText.isEmpty {
            let lower = state.searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(lower) }
        }

        return result
    }
}
