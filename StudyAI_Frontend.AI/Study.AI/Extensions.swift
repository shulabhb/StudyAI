//
//  Extensions.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/28/25.
//


import Foundation

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
