//  CareType.swift
//  HomeVisit
//
//  The kind of nursing care delivered during a home visit.

import Foundation

enum CareType: String, CaseIterable, Identifiable, Codable {
    case woundCare = "Wound care"
    case medicationReview = "Medication review"
    case postDischargeCheck = "Post-discharge check"
    case diabetesManagement = "Diabetes management"
    case palliativeSupport = "Palliative support"

    //MARK: - PROPERTIES
    // Identifiable lets SwiftUI Pickers loop over every care type
    var id: String { rawValue }

    // SF Symbol shown next to the care type in lists, widget and notification
    var symbolName: String {
        switch self {
        case .woundCare:
            return "bandage.fill"
        case .medicationReview:
            return "pills.fill"
        case .postDischargeCheck:
            return "house.and.flag.fill"
        case .diabetesManagement:
            return "drop.fill"
        case .palliativeSupport:
            return "heart.fill"
        }
    }

    // Typical visit length the nurse can start from when booking
    var typicalDurationMinutes: Int {
        switch self {
        case .woundCare:
            return 45
        case .medicationReview:
            return 30
        case .postDischargeCheck:
            return 60
        case .diabetesManagement:
            return 30
        case .palliativeSupport:
            return 60
        }
    }

    //MARK: - FUNCTION
    // Safe conversion from the String stored in Core Data
    static func fromStoredValue(_ value: String?) -> CareType {
        CareType(rawValue: value ?? "") ?? .postDischargeCheck
    }
}
