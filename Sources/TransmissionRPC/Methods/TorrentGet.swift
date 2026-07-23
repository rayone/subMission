import Foundation

// MARK: - torrent-get

private struct TorrentGetArguments: Encodable {
    let fields: [String]
    let ids: [Int]?
    let format: String = "objects"
}

private struct TorrentGetResponse: Decodable {
    let torrents: [Torrent]
}

/// All fields to request in torrent-get
public let kTorrentFields: [String] = [
    "id", "name", "hashString", "comment", "creator", "dateCreated", "magnetLink",
    "isPrivate", "totalSize", "pieceCount", "pieceSize", "file-count", "primary-mime-type",
    "status", "error", "errorString", "percentDone", "metadataPercentComplete", "recheckProgress",
    "isFinished", "isStalled", "eta", "etaIdle", "leftUntilDone", "sizeWhenDone",
    "haveValid", "haveUnchecked", "desiredAvailable", "corruptEver",
    "rateDownload", "rateUpload", "downloadedEver", "uploadedEver", "uploadRatio",
    "secondsDownloading", "secondsSeeding",
    "downloadLimit", "downloadLimited", "uploadLimit", "uploadLimited",
    "honorsSessionLimits", "bandwidthPriority",
    "seedRatioLimit", "seedRatioMode", "seedIdleLimit", "seedIdleMode",
    "queuePosition", "downloadDir",
    "addedDate", "doneDate", "startDate", "activityDate", "editDate",
    "peersConnected", "peersSendingToUs", "peersGettingFromUs", "webseedsSendingToUs",
    "maxConnectedPeers", "peer-limit", "peers", "peersFrom",
    "trackers", "trackerStats", "trackerList",
    "files", "fileStats", "wanted", "priorities",
    "pieces", "availability", "labels", "group", "sequentialDownload",
]

public extension RPCSession {
    func fetchTorrents(ids: [Int]? = nil, fields: [String]? = nil) async throws -> [Torrent] {
        let args = TorrentGetArguments(fields: fields ?? kTorrentFields, ids: ids)
        let resp = try await request(method: "torrent-get", arguments: args, responseType: TorrentGetResponse.self)
        return resp.torrents
    }
}
