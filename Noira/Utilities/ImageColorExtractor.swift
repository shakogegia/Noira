//
//  ImageColorExtractor.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import UIKit
import SwiftUI

class ImageColorExtractor {
    /// Extracts prominent, vibrant, and secondary colors from an image URL
    static func extractColors(from urlString: String?) async -> (prominent: Color?, vibrant: Color?, secondary: Color?) {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return (nil, nil, nil)
        }

        let prominent = uiImage.prominentSwiftUIColor
        let vibrant = uiImage.vibrantSwiftUIColor
        let secondary = uiImage.secondarySwiftUIColor

        return (prominent, vibrant, secondary)
    }

    /// Extracts the dominant/average color from an image URL
    static func extractDominantColor(from urlString: String?) async -> Color? {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return nil
        }

        return uiImage.averageSwiftUIColor
    }
}
