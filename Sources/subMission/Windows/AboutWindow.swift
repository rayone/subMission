import AppKit

// MARK: - AboutWindowController

@MainActor
final class AboutWindowController {

    private static var window: NSWindow?

    static func show() {
        if let w = window, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            return
        }

        let vc = AboutViewController()
        let w = NSWindow(contentViewController: vc)
        w.title = S.App.about
        w.styleMask = [.titled, .closable]
        w.isReleasedWhenClosed = false
        w.setContentSize(NSSize(width: 300, height: 260))
        w.center()
        window = w
        w.makeKeyAndOrderFront(nil)
    }
}

// MARK: - AboutViewController

private final class AboutViewController: NSViewController {

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 260))
        container.wantsLayer = true

        // Icon — use theme-appropriate variant
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.image = loadThemedIcon()
        container.addSubview(iconView)

        // App name
        let nameLabel = NSTextField(labelWithString: "subMission")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = Theme.fg
        nameLabel.alignment = .center
        container.addSubview(nameLabel)

        // Version
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.font = .systemFont(ofSize: 12)
        versionLabel.textColor = Theme.comment
        versionLabel.alignment = .center
        container.addSubview(versionLabel)

        // Description
        let descLabel = NSTextField(labelWithString: "Native macOS client for Transmission")
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 11)
        descLabel.textColor = Theme.fgDark
        descLabel.alignment = .center
        container.addSubview(descLabel)

        // GitHub link
        let linkButton = NSButton(title: "github.com/rayone/subMission", target: self, action: #selector(openGitHub))
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.bezelStyle = .inline
        linkButton.isBordered = false
        linkButton.font = .systemFont(ofSize: 11)
        linkButton.contentTintColor = Theme.blue
        let linkStyle = NSMutableParagraphStyle()
        linkStyle.alignment = .center
        let linkAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: Theme.blue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: linkStyle,
        ]
        linkButton.attributedTitle = NSAttributedString(string: "github.com/rayone/subMission", attributes: linkAttrs)
        container.addSubview(linkButton)

        // Copyright
        let copyrightLabel = NSTextField(labelWithString: "Copyright \u{00A9} 2025")
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        copyrightLabel.font = .systemFont(ofSize: 10)
        copyrightLabel.textColor = Theme.comment
        copyrightLabel.alignment = .center
        container.addSubview(copyrightLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            versionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 8),
            descLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            linkButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            linkButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            copyrightLabel.topAnchor.constraint(equalTo: linkButton.bottomAnchor, constant: 12),
            copyrightLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])

        view = container
    }

    private func loadThemedIcon() -> NSImage? {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let name = isDark ? "AppIconDark" : "AppIconLight"
        if let url = Bundle.main.url(forResource: name, withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return NSApp.applicationIconImage
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/rayone/subMission")!)
    }
}
