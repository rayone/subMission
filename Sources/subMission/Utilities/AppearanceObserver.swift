import AppKit

/// Observes system appearance changes and updates the Dock/app-switcher icon
/// to match: dark icon for Dark Aqua, light icon for Aqua / all other appearances.
/// The icon is masked with macOS's continuous-corner (squircle) curve.
///
/// Usage: instantiate once in AppDelegate and hold a strong reference.
final class AppearanceObserver: NSObject {

    private var kvoToken: NSKeyValueObservation?

    override init() {
        super.init()
        // Apply immediately on launch
        applyIcon(for: NSApp.effectiveAppearance)
        // Watch for subsequent changes (user switches in System Settings)
        kvoToken = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] app, _ in
            self?.applyIcon(for: app.effectiveAppearance)
        }
    }

    private func applyIcon(for appearance: NSAppearance) {
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let name = isDark ? "AppIconDark" : "AppIconLight"
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "icns"),
            let source = NSImage(contentsOf: url)
        else { return }
        NSApp.applicationIconImage = squircleMasked(source)
    }

    /// Returns a copy of `image` clipped to the macOS continuous-corner squircle.
    private func squircleMasked(_ image: NSImage) -> NSImage {
        // Use the largest available representation for the canonical size.
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let masked = NSImage(size: size)
        masked.lockFocus()

        // macOS continuous-corner radius ≈ 22.37% of side length (matches system icons).
        let radius = min(size.width, size.height) * 0.2237
        let rect   = CGRect(origin: .zero, size: size)
        let path   = CGPath(roundedRect: rect,
                            cornerWidth:  radius,
                            cornerHeight: radius,
                            transform:    nil)

        NSGraphicsContext.current?.cgContext.addPath(path)
        NSGraphicsContext.current?.cgContext.clip()

        image.draw(in: rect)

        masked.unlockFocus()
        return masked
    }
}
