import AppKit

final class ProgressBarView: NSView {
    var progress: Double = 0 {
        didSet { needsDisplay = true }
    }
    var progressText: String = "" {
        didSet { needsDisplay = true }
    }
    var barColor: NSColor = Theme.blue

    private static let textAttributes: [NSAttributedString.Key: Any] = {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style,
        ]
    }()

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        let radius: CGFloat = 3
        let barRect = bounds.insetBy(dx: 1, dy: 2)

        // Background
        Theme.barTrack.setFill()
        NSBezierPath(roundedRect: barRect, xRadius: radius, yRadius: radius).fill()

        // Fill
        let fillWidth = barRect.width * CGFloat(min(max(progress, 0), 1))
        if fillWidth > 0 {
            let fillRect = NSRect(x: barRect.minX, y: barRect.minY, width: fillWidth, height: barRect.height)
            let clip = NSBezierPath(roundedRect: barRect, xRadius: radius, yRadius: radius)
            clip.setClip()
            barColor.setFill()
            NSBezierPath(rect: fillRect).fill()
        }

        // Text — vertically centered
        if !progressText.isEmpty {
            let attrs = ProgressBarView.textAttributes
            let textSize = progressText.size(withAttributes: attrs)
            let textRect = NSRect(
                x: barRect.minX,
                y: barRect.midY - textSize.height / 2,
                width: barRect.width,
                height: textSize.height
            )
            progressText.draw(in: textRect, withAttributes: attrs)
        }
    }
}
