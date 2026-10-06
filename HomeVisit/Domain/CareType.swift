//  CareType.swift
//  HomeVisit
//
//  The kind of nursing care delivered during a home visit.

import Foundation

enum CareType: String, CaseIterable, Identifiable {
    case woundCare = "Wound care"
    case medicationReview = "Medication review"
    case postDischargeCheck = "Post-discharge check"
    case palliativeSupport = "Palliative support"

    //MARK: - PROPERTIES
    // Identifiable lets SwiftUI Pickers loop over every care type
    var id: String { rawValue }

    // SF Symbol shown next to the care type
    var symbolName: String {
        switch self {
        case .woundCare:
            return "bandage.fill"
        case .medicationReview:
            return "pills.fill"
        case .postDischargeCheck:
            return "house.fill"
        case .palliativeSupport:
            return "heart.fill"
        }
    }
}
