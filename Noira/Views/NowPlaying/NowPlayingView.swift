//
//  NowPlayingView.swift
//  Noira
//
//  Created by Shalva Gegia on 18/09/2025.
//

import SwiftUI

struct NowPlayingView: View {
    @State private var book = Book.sampleBooks[0]
    @State private var dominantColor: Color = Color.clear

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    dominantColor.opacity(1),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            HStack(alignment: .center) {
                VStack(alignment: .center) {
                    SquareBookCover(
                        url: book.coverImageURL,
                        size: 400,
                        radius: 12
                    )
                    .shadow(radius: 12)
                    .onAppear {
                        extractDominantColor()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func extractDominantColor() {
        // Convert SwiftUI Image to UIImage and extract colors
        DispatchQueue.global(qos: .background).async {
            // This is a simplified approach - in reality you'd need to
            // convert the SwiftUI Image to UIImage properly
            // For now, we'll use a fallback approach with URL
            if let urlString = book.coverImageURL,
                let url = URL(string: urlString),
                let data = try? Data(contentsOf: url),
                let uiImage = UIImage(data: data)
            {
                let prominent = uiImage.prominentSwiftUIColor
                
                DispatchQueue.main.async {
                    dominantColor = prominent ?? Color.clear
                }
            }
        }
    }
}

#Preview {
    NowPlayingView()
}
