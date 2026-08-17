import SwiftUI

// MARK: - 跨平台颜色扩展

#if canImport(UIKit)
import UIKit
extension Color {
    static let bubbleBackground = Color(UIColor.systemGray5)
    static let inputBackground = Color(UIColor.systemGray5)
    static let inputFieldBackground = Color(UIColor.systemGray5)
    static let disabledGray = Color(UIColor.systemGray3)
    static let sectionBackground = Color(UIColor.systemGray6)
}
#else
extension Color {
    static let bubbleBackground = Color.gray.opacity(0.15)
    static let inputBackground = Color.gray.opacity(0.15)
    static let inputFieldBackground = Color.gray.opacity(0.15)
    static let disabledGray = Color.gray.opacity(0.4)
    static let sectionBackground = Color.gray.opacity(0.1)
}
#endif
