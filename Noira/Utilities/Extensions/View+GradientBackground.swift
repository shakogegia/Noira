//
//  View+GradientBackground.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import SwiftUI

struct DynamicGradientBackground: ViewModifier {
    let colors: [Color]

    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            content
        }
    }
}

extension View {
    func dynamicGradientBackground(colors: [Color]) -> some View {
        modifier(DynamicGradientBackground(colors: colors))
    }
}
