//  RoundProgressView.swift
//  HomeVisit
//
//  Summary card at the top of Today's Round: how far through the day the nurse is.

import SwiftUI

struct RoundProgressView: View {

    //MARK: - PROPERTIES
    let round: TodaysRound

    //MARK: - BODY
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(round.day, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(round.progressSummary)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                Image(systemName: round.isRoundComplete ? "checkmark.seal.fill" : "car.fill")
                    .font(.title)
                    .foregroundColor(round.isRoundComplete ? Color.green : Color.accentColor)
            } //: HStack

            ProgressView(value: round.progressFraction)
                .tint(round.isRoundComplete ? Color.green : Color.accentColor)

            HStack(spacing: 16) {
                Label("\(round.completedVisitCount) completed", systemImage: "checkmark.circle")
                Label("\(round.noAccessVisitCount) no access", systemImage: "door.left.hand.closed")
                if !round.runningLateVisitIDs.isEmpty {
                    Label("\(round.runningLateVisitIDs.count) late", systemImage: "clock.badge.exclamationmark")
                        .foregroundColor(.red)
                }
            } //: HStack
            .font(.caption)
            .foregroundColor(.secondary)
        } //: VStack
        .padding(.vertical, 6)
    }
}

//MARK: - PREVIEW
struct RoundProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let round = TodaysRound(day: Date(), outstandingVisits: [], closedVisits: [], runningLateVisitIDs: [])
        List {
            RoundProgressView(round: round)
        }
    }
}
