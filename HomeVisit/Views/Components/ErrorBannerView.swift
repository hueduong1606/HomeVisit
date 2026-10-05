//  ErrorBannerView.swift
//  HomeVisit
//
//  A dismissable banner shown at the top of a screen when a Use Case
//  rejects an action. The message is always nurse-facing:
//  what went wrong + what to do next.

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
                Text("Check this before you continue")
                    .font(.headline)
                    .fontWeight(.semibold)
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
                .accessibilityLabel("Dismiss message")
            } //: HStack

            // Nurse-facing message body
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        } //: VStack
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.92))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1)
    }
}

//MARK: - PREVIEW
struct ErrorBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorBannerView(
            message: "This visit overlaps your 10:00 AM visit with Arthur Nguyen. Pick a start time after that visit finishes.",
            onDismiss: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
