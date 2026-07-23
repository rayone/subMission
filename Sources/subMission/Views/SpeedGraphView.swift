import AppKit

final class SpeedGraphView: NSView {
    private let appService: AppService
    private var history: [(dl: Int64, ul: Int64)] = []
    private var observerToken: ObserverToken?

    init(frame: NSRect, appService: AppService) {
        self.appService = appService
        super.init(frame: frame)
        wantsLayer = true
        observerToken = appService.addObserver { [weak self] event in
            if case .statsUpdated = event { self?.update() }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { observerToken?.cancel() }

    private func update() {
        history = appService.speedHistory
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !history.isEmpty else { return }
        let b = bounds.insetBy(dx: 1, dy: 1)
        guard b.width > 4, b.height > 4 else { return }

        let maxVal = history.map { max($0.dl, $0.ul) }.max() ?? 1
        let peak = max(maxVal, 1024) // min scale 1KB/s

        func x(for i: Int) -> CGFloat {
            b.minX + b.width * CGFloat(i) / CGFloat(max(history.count - 1, 1))
        }
        func y(for val: Int64) -> CGFloat {
            b.minY + b.height * CGFloat(val) / CGFloat(peak)
        }

        func drawLine(values: [Int64], color: NSColor) {
            guard values.count > 1 else { return }
            let path = NSBezierPath()
            path.move(to: NSPoint(x: x(for: 0), y: y(for: values[0])))
            for i in 1..<values.count {
                path.line(to: NSPoint(x: x(for: i), y: y(for: values[i])))
            }
            color.setStroke()
            path.lineWidth = 1.5
            path.stroke()
        }

        drawLine(values: history.map(\.dl), color: NSColor.systemBlue.withAlphaComponent(0.9))
        drawLine(values: history.map(\.ul), color: NSColor.systemGreen.withAlphaComponent(0.9))
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        guard !history.isEmpty else { return }
        let last = history.last!
        let tip = "↓ \(Formatters.formatSpeed(last.dl))  ↑ \(Formatters.formatSpeed(last.ul))"
        toolTip = tip
    }
}
