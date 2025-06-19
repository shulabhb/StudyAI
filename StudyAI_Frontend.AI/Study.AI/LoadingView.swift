import SwiftUI

struct LoadingView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: AppColors.accent)
                )
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .center)
    }
} 