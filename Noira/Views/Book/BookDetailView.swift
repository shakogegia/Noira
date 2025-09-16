//
//  BookDetailView.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import SwiftUI

struct BookDetailView: View {
    let book: Book
    @State private var showingPlayer = false
    @State private var dominantColor: Color = Color.black
    
    var body: some View {
        ZStack {
            // Gradient overlay (bottom to top, opaque to transparent)
            // Dynamic gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    dominantColor.opacity(1),
                    dominantColor.opacity(0.8),
                    dominantColor.opacity(0.2),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            ScrollView {
                VStack(spacing: 30) {
                    // Cover and Basic Info Section
                    HStack(alignment: .top, spacing: 40) {
                        // Cover Image
                        AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 450, height: 450)
                                .clipped()
                                .onAppear {
                                    extractDominantColor(from: image)
                                }
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 300, height: 450)
                                .overlay{
                                    Image(systemName: "book.pages.fill")
                                        .foregroundColor(Color.gray.opacity(0.6))
                                        .font(Font.system(size: 60))
                                        .hoverEffectDisabled(true)
                                }
                        }
                        .cornerRadius(12)
                        
                        // Book Information
                        VStack(alignment: .leading, spacing: 20) {
                            // Title and Author
                            VStack(alignment: .leading, spacing: 8) {
                                Text(book.title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("by \(book.authors.map(\.name).joined(separator: ", "))")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Narrators
                            if !book.narrators.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Narrated by")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(book.narrators.joined(separator: ", "))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Genres
                            if !book.genres.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Genres")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        ForEach(book.genres, id: \.self) { genre in
                                            Text(genre)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                            
                            // Duration
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text(book.formattedDuration)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            
                            // Progress (if any)
                            if book.progress > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Progress")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(book.progress * 100))% complete")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    ProgressView(value: book.progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .scaleEffect(y: 1.5)
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: 400)
                    }
                    .padding(.horizontal)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(book.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Play Button Section
                    VStack(spacing: 16) {
                        Button(book.progress > 0 ? "Resume Playing" : "Start Playing") {
                            showingPlayer = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 300, height: 50)
                        .background(book.progress > 0 ? Color.blue : Color.green)
                        .cornerRadius(25)
                        .focusable()
                        
                        if book.progress > 0 {
                            Button("Start from Beginning") {
                                // TODO: Start from beginning
                                showingPlayer = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .focusable()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.all, 60)
            //.background(Color.black)
            //.navigationTitle(book.title)
            //.navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingPlayer) {
                // NowPlayingView(book: book)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: [.all]) // <- HERE
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

#Preview("Book 1") {
    NavigationView {
        BookDetailView(book: Book.sampleBooks[0]) // The Hobbit with 30% progress
    }
}

#Preview("Book 2") {
    NavigationView {
        BookDetailView(book: Book.sampleBooks[1]) // Dune with 0% progress
    }
}
