//
//  SquareBookCover.swift
//  Noira
//
//  Created by Shalva Gegia on 17/09/2025.
//

import SwiftUI

struct SquareBookCover: View {
    let url: String?
    let size: CGFloat
    let radius: CGFloat
    
    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                case .success(let image):
                    image
                        .resizable()
                default:
                    Rectangle()
                        .foregroundColor(.gray)
                        .cornerRadius(radius)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: radius))
        } else {
            Rectangle()
                .foregroundColor(.gray)
                .cornerRadius(radius)
                .overlay {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: radius))
        }
    }
}

#Preview("With URL") {
    SquareBookCover(
        url: "https://www.graphicaudiointernational.net/media/catalog/product/cache/0164cd528593768540930b5b640a411b/r/e/red_rising_saga_1_red_rising_1_of_2_1.jpg",
        size: 256,
        radius: 24
    )
    .preferredColorScheme(.light)
}

#Preview("No URL") {
    SquareBookCover(
        url: nil,
        size: 256,
        radius: 24
    )
    .preferredColorScheme(.light)
}
