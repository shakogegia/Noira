//
//  BrandingView.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import SwiftUI

struct BrandingView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "books.vertical")
                .font(.system(size: 96))
                .foregroundStyle(.gray)

            Text("Noira")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Text("Audiobookshelf for tvOS")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Copyright © 2025 Shalva Gegia.\nAll rights reserved.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    BrandingView()
        .padding()
}
