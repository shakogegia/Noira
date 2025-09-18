//
//  UIImage+Extensions.swift
//  Noira
//
//  Created by Shalva Gegia on 15/09/2025.
//

import UIKit
import CoreImage
import SwiftUI

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
    
    // You might also want to add SwiftUI Color support
    var averageSwiftUIColor: Color? {
        guard let uiColor = averageColor else { return nil }
        return Color(uiColor)
    }
    
    // MARK: - Prominent Color Extraction
    
    /// Extracts the most prominent (dominant) color from the image
    var prominentColor: UIColor? {
        return extractProminentColors(count: 1).first
    }
    
    /// Extracts the most prominent color as SwiftUI Color
    var prominentSwiftUIColor: Color? {
        guard let uiColor = prominentColor else { return nil }
        return Color(uiColor)
    }
    
    /// Extracts the most vibrant color from the image
    var vibrantColor: UIColor? {
        return extractVibrantColors(count: 1).first
    }
    
    /// Extracts the most vibrant color as SwiftUI Color
    var vibrantSwiftUIColor: Color? {
        guard let uiColor = vibrantColor else { return nil }
        return Color(uiColor)
    }
    
    /// Extracts secondary color (second most prominent)
    var secondaryColor: UIColor? {
        let colors = extractProminentColors(count: 2)
        return colors.count > 1 ? colors[1] : nil
    }
    
    /// Extracts secondary color as SwiftUI Color
    var secondarySwiftUIColor: Color? {
        guard let uiColor = secondaryColor else { return nil }
        return Color(uiColor)
    }
    
    /// Extracts multiple prominent colors from the image
    /// - Parameter count: Number of colors to extract (default: 5)
    /// - Returns: Array of prominent colors sorted by dominance
    func extractProminentColors(count: Int = 5) -> [UIColor] {
        guard let cgImage = self.cgImage else { return [] }
        
        // Resize image for better performance
        let resizedImage = resizeForColorExtraction()
        guard let resizedCGImage = resizedImage.cgImage else { return [] }
        
        // Get pixel data
        guard let pixelData = getPixelData(from: resizedCGImage) else { return [] }
        
        // Extract colors using k-means clustering
        return performKMeansClustering(pixelData: pixelData, k: count)
    }
    
    /// Extracts multiple prominent colors as SwiftUI Colors
    /// - Parameter count: Number of colors to extract (default: 5)
    /// - Returns: Array of prominent SwiftUI colors
    func extractProminentSwiftUIColors(count: Int = 5) -> [Color] {
        return extractProminentColors(count: count).map { Color($0) }
    }
    
    /// Extracts vibrant colors from the image (colors with high saturation)
    /// - Parameter count: Number of vibrant colors to extract (default: 3)
    /// - Returns: Array of vibrant colors
    func extractVibrantColors(count: Int = 3) -> [UIColor] {
        let allColors = extractProminentColors(count: count * 3) // Get more colors to filter from
        
        // Filter for vibrant colors (high saturation)
        let vibrantColors = allColors.compactMap { color -> (UIColor, CGFloat)? in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            // Only include colors with high saturation and reasonable brightness
            if saturation > 0.4 && brightness > 0.3 && brightness < 0.9 {
                return (color, saturation)
            }
            return nil
        }.sorted { $0.1 > $1.1 } // Sort by saturation
        
        return Array(vibrantColors.prefix(count).map { $0.0 })
    }
    
    /// Extracts vibrant colors as SwiftUI Colors
    /// - Parameter count: Number of vibrant colors to extract (default: 3)
    /// - Returns: Array of vibrant SwiftUI colors
    func extractVibrantSwiftUIColors(count: Int = 3) -> [Color] {
        return extractVibrantColors(count: count).map { Color($0) }
    }
    
    /// Extracts muted colors from the image (colors with lower saturation but good contrast)
    /// - Parameter count: Number of muted colors to extract (default: 3)
    /// - Returns: Array of muted colors
    func extractMutedColors(count: Int = 3) -> [UIColor] {
        let allColors = extractProminentColors(count: count * 3)
        
        // Filter for muted colors (lower saturation but not too low)
        let mutedColors = allColors.compactMap { color -> (UIColor, CGFloat)? in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            // Include colors with moderate saturation
            if saturation >= 0.15 && saturation <= 0.5 && brightness > 0.2 {
                return (color, brightness)
            }
            return nil
        }.sorted { $0.1 > $1.1 } // Sort by brightness
        
        return Array(mutedColors.prefix(count).map { $0.0 })
    }
    
    /// Extracts muted colors as SwiftUI Colors
    /// - Parameter count: Number of muted colors to extract (default: 3)
    /// - Returns: Array of muted SwiftUI colors
    func extractMutedSwiftUIColors(count: Int = 3) -> [Color] {
        return extractMutedColors(count: count).map { Color($0) }
    }
    
    // MARK: - Color Palette Generation
    
    /// Generates a complete color palette from the image
    /// - Returns: A tuple containing prominent, vibrant, and muted colors
    func generateColorPalette() -> (prominent: [UIColor], vibrant: [UIColor], muted: [UIColor]) {
        return (
            prominent: extractProminentColors(count: 5),
            vibrant: extractVibrantColors(count: 3),
            muted: extractMutedColors(count: 3)
        )
    }
    
    /// Generates a complete SwiftUI color palette from the image
    /// - Returns: A tuple containing prominent, vibrant, and muted SwiftUI colors
    func generateSwiftUIColorPalette() -> (prominent: [Color], vibrant: [Color], muted: [Color]) {
        let palette = generateColorPalette()
        return (
            prominent: palette.prominent.map { Color($0) },
            vibrant: palette.vibrant.map { Color($0) },
            muted: palette.muted.map { Color($0) }
        )
    }
    
    // MARK: - Helper Methods
    
    private func resizeForColorExtraction() -> UIImage {
        let targetSize = CGSize(width: 150, height: 150)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func getPixelData(from cgImage: CGImage) -> [RGBA32]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [RGBA32](repeating: RGBA32(r: 0, g: 0, b: 0, a: 0), count: width * height)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixelData
    }
    
    private func performKMeansClustering(pixelData: [RGBA32], k: Int) -> [UIColor] {
        // Filter out very dark and very light pixels for better color extraction
        let filteredPixels = pixelData.filter { pixel in
            let brightness = (CGFloat(pixel.r) + CGFloat(pixel.g) + CGFloat(pixel.b)) / (3.0 * 255.0)
            return brightness > 0.1 && brightness < 0.95
        }
        
        guard !filteredPixels.isEmpty else { return [] }
        
        // Simple k-means clustering implementation
        var centroids = initializeCentroids(k: k, from: filteredPixels)
        var previousCentroids: [RGBA32] = []
        
        // Iterate until convergence or max iterations
        for _ in 0..<10 {
            previousCentroids = centroids
            let clusters = assignPixelsToClusters(pixels: filteredPixels, centroids: centroids)
            centroids = updateCentroids(clusters: clusters)
            
            // Check for convergence
            if centroids == previousCentroids { break }
        }
        
        // Convert centroids to UIColors and sort by cluster size
        let clusters = assignPixelsToClusters(pixels: filteredPixels, centroids: centroids)
        let sortedCentroids = zip(centroids, clusters)
            .sorted { $0.1.count > $1.1.count }
            .map { $0.0 }
        
        return sortedCentroids.map { centroid in
            UIColor(
                red: CGFloat(centroid.r) / 255.0,
                green: CGFloat(centroid.g) / 255.0,
                blue: CGFloat(centroid.b) / 255.0,
                alpha: 1.0
            )
        }
    }
    
    private func initializeCentroids(k: Int, from pixels: [RGBA32]) -> [RGBA32] {
        var centroids: [RGBA32] = []
        let step = max(1, pixels.count / k)
        
        for i in 0..<k {
            let index = min(i * step, pixels.count - 1)
            centroids.append(pixels[index])
        }
        
        return centroids
    }
    
    private func assignPixelsToClusters(pixels: [RGBA32], centroids: [RGBA32]) -> [[RGBA32]] {
        var clusters = Array(repeating: [RGBA32](), count: centroids.count)
        
        for pixel in pixels {
            var minDistance = CGFloat.greatestFiniteMagnitude
            var closestCentroid = 0
            
            for (index, centroid) in centroids.enumerated() {
                let distance = colorDistance(pixel, centroid)
                if distance < minDistance {
                    minDistance = distance
                    closestCentroid = index
                }
            }
            
            clusters[closestCentroid].append(pixel)
        }
        
        return clusters
    }
    
    private func updateCentroids(clusters: [[RGBA32]]) -> [RGBA32] {
        return clusters.map { cluster in
            guard !cluster.isEmpty else { return RGBA32(r: 0, g: 0, b: 0, a: 255) }
            
            let totalR = cluster.reduce(0) { $0 + Int($1.r) }
            let totalG = cluster.reduce(0) { $0 + Int($1.g) }
            let totalB = cluster.reduce(0) { $0 + Int($1.b) }
            let count = cluster.count
            
            return RGBA32(
                r: UInt8(totalR / count),
                g: UInt8(totalG / count),
                b: UInt8(totalB / count),
                a: 255
            )
        }
    }
    
    private func colorDistance(_ color1: RGBA32, _ color2: RGBA32) -> CGFloat {
        let deltaR = CGFloat(color1.r) - CGFloat(color2.r)
        let deltaG = CGFloat(color1.g) - CGFloat(color2.g)
        let deltaB = CGFloat(color1.b) - CGFloat(color2.b)
        
        return sqrt(deltaR * deltaR + deltaG * deltaG + deltaB * deltaB)
    }
}

// MARK: - Supporting Types

struct RGBA32 {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8
}

extension RGBA32: Equatable {
    static func == (lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
    }
}

