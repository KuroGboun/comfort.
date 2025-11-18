//
//  extension.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-10-22.
//
import SwiftUI

extension Color {
    static let comfortBackground = Color(red: 255/255, green: 150/255, blue: 150/255)
}

extension Font {
    static func comfort(size: CGFloat) -> Font {
        //.custom("KohSantepheap-Regular", size: size)
        .system(size: size)

    }
}

extension Font {
    static func comfort_light(size: CGFloat) -> Font {
        .custom("KohSantepheap-Light", size: size)
    }
}

extension Font{
    static func comfort_thin(size: CGFloat) -> Font {
        .custom("KohSantepheap-Thin", size: size)
    }
}
