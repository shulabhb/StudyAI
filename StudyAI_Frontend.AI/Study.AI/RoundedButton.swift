//
//  RoundedButton.swift
//  Study.AI
//
//  Created by Shulabh Bhattarai on 5/14/25.
//

import SwiftUI



struct RoundedButton: View {
    let label: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let image = systemImage {
                    Image(systemName: image)
                }
                Text(label)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
