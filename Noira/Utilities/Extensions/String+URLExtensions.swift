//
//  String+URLExtensions.swift
//  Noira
//
//  Created by Shalva Gegia on 23/12/2025.
//

import Foundation

extension String {
    /// Normalizes a server URL by removing whitespace and trailing slashes
    func normalizedServerURL() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
