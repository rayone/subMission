import AppKit

// MARK: - Tokyo Night theme (night for dark, day for light)

enum Theme {

    // MARK: Backgrounds

    /// Primary window / content background
    static let bg = dynamicColor(dark: 0x0d0e16, light: 0xe1e2e7)
    /// Sidebar / floating panel background
    static let bgDark = dynamicColor(dark: 0x16161e, light: 0xd0d5e3)
    /// Selection highlight, table row highlight
    static let bgHighlight = dynamicColor(dark: 0x292e42, light: 0xc4c8da)
    /// Visual selection
    static let bgVisual = dynamicColor(dark: 0x283457, light: 0xb7c1e3)

    // MARK: Foreground

    /// Primary text
    static let fg = dynamicColor(dark: 0xc0caf5, light: 0x3760bf)
    /// Secondary text
    static let fgDark = dynamicColor(dark: 0xa9b1d6, light: 0x6172b0)
    /// Muted / comment text
    static let comment = dynamicColor(dark: 0x565f89, light: 0x848cb5)
    /// Disabled / tertiary text
    static let dark5 = dynamicColor(dark: 0x737aa2, light: 0x68709a)

    // MARK: Accent colors

    static let blue = dynamicColor(dark: 0x7aa2f7, light: 0x2e7de9)
    static let cyan = dynamicColor(dark: 0x7dcfff, light: 0x007197)
    static let green = dynamicColor(dark: 0x9ece6a, light: 0x587539)
    static let red = dynamicColor(dark: 0xf7768e, light: 0xf52a65)
    static let yellow = dynamicColor(dark: 0xe0af68, light: 0x8c6c3e)
    static let orange = dynamicColor(dark: 0xff9e64, light: 0xb15c00)
    static let magenta = dynamicColor(dark: 0xbb9af7, light: 0x9854f1)
    static let purple = dynamicColor(dark: 0x9d7cd8, light: 0x7847bd)
    static let teal = dynamicColor(dark: 0x1abc9c, light: 0x118c74)

    // MARK: Semantic

    static let error = dynamicColor(dark: 0xdb4b4b, light: 0xc64343)
    static let warning = dynamicColor(dark: 0xe0af68, light: 0x8c6c3e)
    static let info = dynamicColor(dark: 0x0db9d7, light: 0x07879d)
    static let hint = dynamicColor(dark: 0x1abc9c, light: 0x118c74)

    // MARK: Git / diff

    static let gitAdd = dynamicColor(dark: 0x449dab, light: 0x4197a4)
    static let gitChange = dynamicColor(dark: 0x6183bb, light: 0x506d9c)
    static let gitDelete = dynamicColor(dark: 0x914c54, light: 0xc47981)

    // MARK: Border

    static let border = dynamicColor(dark: 0x15161e, light: 0xb4b5b9)
    static let borderHighlight = dynamicColor(dark: 0x27a1b9, light: 0x4094a3)

    // MARK: Progress bar track

    static let barTrack = dynamicColor(dark: 0x292e42, light: 0xc4c8da)

    // MARK: - Helpers

    private static func dynamicColor(dark: UInt32, light: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? color(hex: dark)
                : color(hex: light)
        }
    }

    private static func color(hex: UInt32) -> NSColor {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8)  & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
