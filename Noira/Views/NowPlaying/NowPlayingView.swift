//
//  NowPlayingView.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import SwiftUI

struct NowPlayingView: View {
    @State private var book = Book.sampleBooks[0]
    @State private var prominentColor: Color = Color.clear
    @State private var vibrantColor: Color = Color.clear
    @State private var secondaryColor: Color = Color.clear
    

    var body: some View {
        HStack(alignment: .center) {
                VStack(alignment: .center) {
                    SquareBookCover(
                        url: book.coverImageURL,
                        size: 400,
                        radius: 12
                    )
                    .shadow(radius: 12)
                }
                .frame(maxWidth: .infinity)
            }
        .dynamicGradientBackground(colors: [vibrantColor, prominentColor, secondaryColor])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            let colors = await ImageColorExtractor.extractColors(from: book.coverImageURL)
            prominentColor = colors.prominent ?? .clear
            vibrantColor = colors.vibrant ?? .clear
            secondaryColor = colors.secondary ?? .clear
        }
    }
}

#Preview {
    NowPlayingView()
}
