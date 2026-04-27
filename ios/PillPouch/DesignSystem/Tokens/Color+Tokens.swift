import SwiftUI
import UIKit

enum PPColor {
    static let background = dynamic(light: 0xFAF7F2, dark: 0x1C1A17)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x26231F)
    static let stroke = dynamic(light: 0xE8E2D8, dark: 0x3A352F)
    static let textPrimary = dynamic(light: 0x2C2823, dark: 0xF2EEE6)
    static let textSecondary = dynamic(light: 0x7A736B, dark: 0x9E978D)

    static let morning = dynamic(light: 0xF5C56B, dark: 0xC9A157)
    static let lunch = dynamic(light: 0xE89A78, dark: 0xB97155)
    static let evening = dynamic(light: 0x7B6BA8, dark: 0x5E5283)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
