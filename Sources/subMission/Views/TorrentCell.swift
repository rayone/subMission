import AppKit
import TransmissionRPC

// MARK: - TorrentCell (status icon + name, single line)

final class TorrentCell: NSTableCellView {
    private let statusIcon = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.imageScaling = .scaleProportionallyDown
        NSLayoutConstraint.activate([
            statusIcon.widthAnchor.constraint(equalToConstant: 14),
            statusIcon.heightAnchor.constraint(equalToConstant: 14),
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let hStack = NSStackView(views: [statusIcon, nameLabel])
        hStack.orientation = .horizontal
        hStack.spacing = 6
        hStack.alignment = .centerY
        hStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func configure(torrent: Torrent) {
        nameLabel.stringValue = torrent.name
        statusIcon.image = statusImage(for: torrent.status)
        nameLabel.textColor = torrent.error != 0 ? Theme.red : Theme.fg
    }

    private func statusImage(for status: TorrentStatus) -> NSImage? {
        switch status {
        case .stopped:         return NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: nil)
        case .queuedVerify,
             .queuedDownload,
             .queuedSeed:     return NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil)
        case .verifying:      return NSImage(systemSymbolName: "magnifyingglass.circle.fill", accessibilityDescription: nil)
        case .downloading:    return NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
        case .seeding:        return NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: nil)
        }
    }
}
