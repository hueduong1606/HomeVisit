//  ErrorBannerView.swift
//  HomeVisit
//
//  A dismissable banner shown at the top of a screen when a Use Case rejects
//  an action. The message tells the nurse what went wrong and what to do next.

import SwiftUI

struct ErrorBannerView: View {

    //MARK: - PROPERTIES
    let message: String
    var onDismiss: () -> Void

    //MARK: - BODY
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header row
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text("Check before you continue")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()

                // Dismiss button
                Button {
                    withAnimation {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            } //: HStack

            // Nurse-facing message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        } //: VStack
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.92))
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .zIndex(1)
    }
}

//MARK: - PREVIEW
struct ErrorBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorBannerView(message: "This visit overlaps your visit with Arthur Nguyen. Pick a start time after that visit finishes.", onDismiss: {})
            .previewLayout(.sizeThatFits)
    }
}
