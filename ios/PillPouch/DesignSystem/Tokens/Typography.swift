import SwiftUI

enum PPFont {
    static let titleL: Font = .system(.largeTitle, design: .rounded).weight(.semibold)
    static let titleM: Font = .system(.title2, design: .rounded).weight(.semibold)
    static let body: Font = .system(.body, design: .rounded)
    static let caption: Font = .system(.caption, design: .rounded)
    static let mono: Font = .system(.body, design: .monospaced)
}
