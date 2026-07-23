import Foundation

public struct Tracker: Codable, Sendable, Identifiable {
    public let id: Int
    public let announce: String
    public let scrape: String
    public let sitename: String
    public let tier: Int

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeOrDefault(Int.self, forKey: .id, default: 0)
        announce = try c.decodeOrDefault(String.self, forKey: .announce, default: "")
        scrape = try c.decodeOrDefault(String.self, forKey: .scrape, default: "")
        sitename = try c.decodeOrDefault(String.self, forKey: .sitename, default: "")
        tier = try c.decodeOrDefault(Int.self, forKey: .tier, default: 0)
    }
}

public struct TrackerStat: Codable, Sendable {
    public let id: Int
    public let host: String
    public let announce: String
    public let sitename: String
    public let tier: Int
    public let announceState: Int
    public let downloadCount: Int
    public let hasAnnounced: Bool
    public let hasScraped: Bool
    public let isBackup: Bool
    public let lastAnnounceResult: String
    public let lastAnnounceSucceeded: Bool
    public let lastAnnounceTimedOut: Bool
    public let lastAnnounceTime: Int
    public let lastScrapeResult: String
    public let lastScrapeSucceeded: Bool
    public let lastScrapeTimedOut: Bool
    public let lastScrapeTime: Int
    public let leecherCount: Int
    public let nextAnnounceTime: Int
    public let nextScrapeTime: Int
    public let scrapeState: Int
    public let seederCount: Int

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeOrDefault(Int.self, forKey: .id, default: 0)
        host = try c.decodeOrDefault(String.self, forKey: .host, default: "")
        announce = try c.decodeOrDefault(String.self, forKey: .announce, default: "")
        sitename = try c.decodeOrDefault(String.self, forKey: .sitename, default: "")
        tier = try c.decodeOrDefault(Int.self, forKey: .tier, default: 0)
        announceState = try c.decodeOrDefault(Int.self, forKey: .announceState, default: 0)
        downloadCount = try c.decodeOrDefault(Int.self, forKey: .downloadCount, default: -1)
        hasAnnounced = try c.decodeOrDefault(Bool.self, forKey: .hasAnnounced, default: false)
        hasScraped = try c.decodeOrDefault(Bool.self, forKey: .hasScraped, default: false)
        isBackup = try c.decodeOrDefault(Bool.self, forKey: .isBackup, default: false)
        lastAnnounceResult = try c.decodeOrDefault(String.self, forKey: .lastAnnounceResult, default: "")
        lastAnnounceSucceeded = try c.decodeOrDefault(Bool.self, forKey: .lastAnnounceSucceeded, default: false)
        lastAnnounceTimedOut = try c.decodeOrDefault(Bool.self, forKey: .lastAnnounceTimedOut, default: false)
        lastAnnounceTime = try c.decodeOrDefault(Int.self, forKey: .lastAnnounceTime, default: 0)
        lastScrapeResult = try c.decodeOrDefault(String.self, forKey: .lastScrapeResult, default: "")
        lastScrapeSucceeded = try c.decodeOrDefault(Bool.self, forKey: .lastScrapeSucceeded, default: false)
        lastScrapeTimedOut = try c.decodeOrDefault(Bool.self, forKey: .lastScrapeTimedOut, default: false)
        lastScrapeTime = try c.decodeOrDefault(Int.self, forKey: .lastScrapeTime, default: 0)
        leecherCount = try c.decodeOrDefault(Int.self, forKey: .leecherCount, default: -1)
        nextAnnounceTime = try c.decodeOrDefault(Int.self, forKey: .nextAnnounceTime, default: 0)
        nextScrapeTime = try c.decodeOrDefault(Int.self, forKey: .nextScrapeTime, default: 0)
        scrapeState = try c.decodeOrDefault(Int.self, forKey: .scrapeState, default: 0)
        seederCount = try c.decodeOrDefault(Int.self, forKey: .seederCount, default: -1)
    }

    enum CodingKeys: String, CodingKey {
        case id, host, announce, sitename, tier
        case announceState, downloadCount, hasAnnounced, hasScraped, isBackup
        case lastAnnounceResult, lastAnnounceSucceeded, lastAnnounceTimedOut, lastAnnounceTime
        case lastScrapeResult, lastScrapeSucceeded, lastScrapeTimedOut, lastScrapeTime
        case leecherCount, nextAnnounceTime, nextScrapeTime, scrapeState, seederCount
    }
}
