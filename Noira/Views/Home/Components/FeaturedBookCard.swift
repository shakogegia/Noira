//
//  FeaturedBookCard.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct FeaturedBookCard: View {
    let book: Book
    @FocusState private var isFocused: Bool
    @State private var dominantColor: Color = Color.black
    
    var body: some View {
        NavigationLink(value: Destination.detail(book)) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover with gradient overlay
                ZStack(alignment: .bottom) {
                    // Cover Image
                    AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 240, height: 360)
                            .clipped()
                            .onAppear {
                                extractDominantColor(from: image)
                            }
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 240, height: 360)
                            .overlay{
                                Image(systemName: "book.pages.fill")
                                    .foregroundColor(Color.gray.opacity(0.6))
                                    .font(Font.system(size: 60))
                                    .hoverEffectDisabled(true)
                            }
                    }
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: isFocused ? 3 : 0)
                    )
                    
                    // Gradient overlay (bottom to top, opaque to transparent)
                    // Dynamic gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            dominantColor.opacity(1),
                            dominantColor.opacity(0.8),
                            //dominantColor.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .frame(width: 240, height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Book information overlay
                    VStack(alignment: .leading, spacing: 12) {
                        Spacer()
                        
                        // Title
                        Text(book.title)
                            .font(Font.system(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        
                        
                        HStack {
                            HStack {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(Font.system(size: 18))
                                    Text(book.formattedDuration)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .foregroundStyle(Color.black.opacity(0.6))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 2)
                            }
                            .foregroundColor(.black)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                        }
                    }
                    .padding(16)
                    .frame(width: 240, alignment: .leading)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: isFocused ? 4 : 0)
                )
            }
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .focused($isFocused)
        .buttonStyle(.borderless)
        
    }
    
    private func extractDominantColor(from image: Image) {
        // Convert SwiftUI Image to UIImage and extract color
        DispatchQueue.global(qos: .background).async {
            // This is a simplified approach - in reality you'd need to
            // convert the SwiftUI Image to UIImage properly
            // For now, we'll use a fallback approach with URL
            if let urlString = book.coverImageURL,
               let url = URL(string: urlString),
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data),
               let color = uiImage.averageSwiftUIColor {
                
                DispatchQueue.main.async {
                    dominantColor = color
                }
            }
        }
    }
}

#Preview("Single Card") {
    FeaturedBookCard(book: Book.sampleBooks[0]) // The Hobbit has 30% progress
        .background(Color.black)
        .padding()
}

#Preview("Multiple Featured Cards") {
    HStack(spacing: 24) {
        ForEach(Book.sampleBooks.filter { $0.progress > 0 }) { book in
            FeaturedBookCard(book: book)
        }
    }
    .background(Color.black)
    .padding()
}

