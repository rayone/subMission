import AppKit
import TransmissionRPC

// MARK: - Formatters (shared static instances — never allocate per-cell)

enum Formatters {
    static let byteCount: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    static let byteCountSpeed: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.includesUnit = true
        return f
    }()

    static let ratio: NumberFormatter = {
        let f = NumberFormatter()
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func formatBytes(_ bytes: Int64) -> String {
        byteCount.string(fromByteCount: bytes)
    }

    static func formatSpeed(_ bytesPerSec: Int64) -> String {
        byteCountSpeed.string(fromByteCount: bytesPerSec) + "/s"
    }

    static func formatRatio(_ ratio: Double) -> String {
        if ratio < 0 { return "∞" }
        return self.ratio.string(from: NSNumber(value: ratio)) ?? "0.00"
    }

    static func formatETA(_ eta: Int) -> String {
        if eta < 0 { return "∞" }
        if eta == 0 { return S.Status.etaDone }
        let seconds = eta
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h \((seconds % 3600) / 60)m" }
        return "\(seconds / 86400)d \((seconds % 86400) / 3600)h"
    }

    static func formatDuration(_ seconds: Int64) -> String {
        if seconds <= 0 { return "0s" }
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        if s < 86400 { return "\(s / 3600)h \((s % 3600) / 60)m" }
        return "\(s / 86400)d"
    }

    static func formatDate(_ timestamp: Int) -> String {
        guard timestamp > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    static func formatStatusString(_ torrent: Torrent) -> String {
        switch torrent.status {
        case .stopped:
            if torrent.error != 0 { return S.Status.error(message: torrent.errorString) }
            return S.Status.stopped
        case .queuedVerify:   return S.Status.queuedVerify
        case .verifying:      return S.Status.verifying(percent: Int(torrent.recheckProgress * 100))
        case .queuedDownload: return S.Status.queuedDownload
        case .downloading:
            if torrent.metadataPercentComplete < 1 {
                return S.Status.metadata(percent: Int(torrent.metadataPercentComplete * 100))
            }
            return S.Status.downloading
        case .queuedSeed:     return S.Status.queuedSeed
        case .seeding:        return S.Status.seeding
        }
    }
}
