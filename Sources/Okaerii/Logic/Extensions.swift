// Okaerii/Logic/Extensions.swift
import SwiftUI

extension Color {
    static let okaerizenPrimary = Color(red: 0.33, green: 0.52, blue: 0.98)
    static let okaerizenSecondary = Color(red: 0.46, green: 0.42, blue: 0.95)
    static let okaerizenAccent = Color(red: 0.24, green: 0.83, blue: 0.78)
    static let okaerizenHighlight = Color(red: 0.98, green: 0.72, blue: 0.35)
    static let okaerizenBackground: Color = {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }()
    static let okaerizenSurface = Color.primary.opacity(0.06)
}
