//
//  glassHelper.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-10-23.
//

// Glass helper
import SwiftUI

extension View {
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
                .environment(\.colorScheme, .light)
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(radius: 6, y: 2)
        }
    }

    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
                .environment(\.colorScheme, .light) 
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(radius: 6, y: 2)
        }
    }
}
