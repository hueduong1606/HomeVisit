# HomeVisit

## Overview

HomeVisit is a SwiftUI iOS MVP developed for a community nursing context.

The purpose of the app is to support community nurses who deliver care in patients' homes. Instead of relying on paper lists, retyped referrals and notes written up hours later from memory, the nurse can use the app to see today's round in time order, plan visits ahead, admit patients from shared referrals and record the outcome of each visit.

The prototype uses a community nursing service as the context for the solution. It is an academic prototype and is not an official health service application.

## Domain Context

A community nurse drives between 6–10 patients' homes a day to provide wound care, medication reviews, post-discharge checks and palliative support. The round changes throughout the day, so the system needs to represent both the planned visit and what actually happened at the patient's home.

For example, a nurse cannot be in two homes at once, so a visit should not be booked if it overlaps another visit still to do. A visit must also be safe in length (15–180 minutes), finish before midnight on its day, and be planned no more than 14 days ahead.

When a visit's planned finish time passes with nothing recorded, it is flagged as *Outcome overdue*. An outcome (*Care completed* or *No access*) can only be recorded once and needs a clinical note of at least 10 characters.

Safety information, such as *Dog on premises – call ahead*, must be visible before the nurse arrives at the door.

This problem is supported by published evidence:

- The King's Fund (2016), *Understanding quality in district nursing services* – visits being missed or postponed because demand outstrips capacity. Reported in Public Finance: https://www.publicfinance.co.uk/node/24542
- Blay et al. (2025), *Community nursing: A time and motion study of community nurses' work and workload*, Journal of Advanced Nursing 81(7) – documentation and travel identified as areas to improve. https://ro.ecu.edu.au/ecuworks2022-2026/5441

HomeVisit was designed around this nursing workflow so that the names, rules, errors and screens represent the actual home-visit domain.

## Main Features

The MVP allows the community nurse to:

- View today's round of visits still to do, in time order
- See visits flagged as *Outcome overdue*
- See visits already done today and visits *Coming up* on later days
- View a patient's address and clinical safety alert for each visit
- Add a visit to today's round, or plan ahead up to 14 days
- Choose the patient, care type, date, time and duration of a visit
- Record a visit outcome of *Care completed* or *No access* with a clinical note
- View the caseload of patients and the referrals waiting to be admitted
- Admit a patient manually or from a shared referral
- See the next visit on a Home Screen or Lock Screen widget
- Receive a visit reminder 15 minutes before each visit, showing a visit card
- Share referral text from another app straight into HomeVisit
- View meaningful messages when a business rule prevents an action

## Domain-Centred Architecture

The application is organised using domain-centred naming so that the code structure reflects the home-visit nursing problem rather than generic programming concepts.

```
View  ──>  ViewModel  ──>  Use Case  ──>  CaseloadRepository (protocol)  ──>  Core Data
                              │
                              └──>  RoundSyncing (protocol)  ──>  App Group + widget + reminders
```

### Domain

The Domain layer contains the main records and concepts used by the nursing round.
Including:
- `Patient`
- `CareVisit`
- `CareType`
- `VisitStatus` and `VisitOutcome`
- `TodaysRound`
- home-visit domain errors

These types represent information and rules that have meaning in the community nursing context.

### Use Cases

Business operations are separated into four main Use Cases:

- `PlanTodaysRoundUseCase`
- `ScheduleHomeVisitUseCase`
- `RecordVisitOutcomeUseCase`
- `AdmitPatientToCaseloadUseCase`

Each Use Case is responsible for one main business operation instead of placing the business rules directly inside the SwiftUI views. Each one enforces its own domain rules and has a typed error enum (`PlanTodaysRoundError`, `ScheduleHomeVisitError`, `RecordVisitOutcomeError`, `AdmitPatientError`).

### Services and System Extensions

The application uses services for work that is shared between the app and its system extensions:

- `RoundSyncing` / `WidgetAndReminderRoundSync`
- `VisitReminderScheduler`
- `ReferralInbox` / `AppGroupReferralInbox`

These services keep the widget and reminders in step with the round, but only after a successful save. They also read the referrals shared from other apps.

Information is shared with the extensions through the App Group `group.com.heather.HomeVisit`:

- **NextVisitWidget** shows the next visit's time, patient, address and alert on the Home Screen and Lock Screen.
- **ReferralShareExtension** saves referral text shared from another app so it appears under *Referrals waiting*.
- **VisitReminderNotification** shows a visit card 15 minutes before each visit, with the safety alert in orange.

### Repository and Persistence

`CaseloadRepository` defines how patients and visits can be loaded and saved.

`CoreDataCaseloadRepository` provides the Core Data implementation used by the MVP. It uses two related entities, `PatientRecord` and `CareVisitRecord`, with a one-to-many relationship and a cascade delete.

A domain query uses a predicate to fetch the visits on a day that the nurse has not documented yet:

```swift
NSPredicate(format: "scheduledStart >= %@ AND scheduledStart < %@ AND statusRaw == %@", ...)
```

Core Data was chosen because patient health information must stay private on the device and must work offline, in the car or inside homes with no signal. If a save fails, the changes are rolled back so the stored round stays consistent.

### ViewModel

Each screen has its own ViewModel:

- `TodaysRoundViewModel`
- `ScheduleVisitViewModel`
- `RecordOutcomeViewModel`
- `CaseloadViewModel`
- `AdmitPatientViewModel`

The ViewModels:

- load the round, patients and referrals
- call the required Use Case
- update the published state shown on screen
- provide error messages to the interface

They keep the SwiftUI views focused mainly on displaying information and receiving user input.

### Views

The main SwiftUI screens include:

- `TodaysRoundView`
- `VisitDetailView`
- `RecordOutcomeView`
- `ScheduleVisitView`
- `CaseloadView`
- `AdmitPatientView`

The screens follow the nurse's day from planning the round and visiting each home through to recording outcomes and admitting new patients from referrals.

## Error Handling and Human-System Design

The app uses domain-specific errors instead of generic failure messages. Each message explains what went wrong and what the nurse can do next, for example:

*"This visit overlaps your visit with Arthur Nguyen. Pick a start time after that visit finishes."*

The system considers what happens at the patient's home as well as the digital record. For example, a visit that has passed its planned finish time with nothing recorded is flagged as *Outcome overdue*, so it is not forgotten.

If the round cannot be loaded, the nurse sees a message instead of an empty list. If a save fails, what she typed stays on screen so she can try again. The widget keeps its previous data rather than showing a wrong round, and reminders only say *"Reminder scheduled"* after iOS confirms it.

This is important because the application is supporting a human process involving real patients and real homes, not only changing data on a screen.

## Accessibility

The SwiftUI interface uses system text styles such as `.headline`, `.subheadline` and `.caption`, so text follows the size the user has chosen in iOS.

Clinical alerts are shown with a warning symbol and written text, not by colour alone. Buttons and screen titles use clear domain language, such as **Add to Round**, **Record Visit Outcome** and **Admit to Caseload**, so that the required action is understandable to the nurse using the app.

## Testing

Unit testing focuses on the four business Use Cases:

- `PlanTodaysRoundUseCase`
- `ScheduleHomeVisitUseCase`
- `RecordVisitOutcomeUseCase`
- `AdmitPatientToCaseloadUseCase`

The project uses Swift Testing with `@Test` and `#expect`.

The six tests cover:

- successful business operations
- boundary conditions
- important domain error cases

| Test | Use Case | Type |
|---|---|---|
| `planningTomorrowsVisitTheDayBefore_addsItToTheRoundAndRefreshesWidget` | ScheduleHomeVisit | Happy path |
| `visitOverlappingAnotherVisit_isRejectedAndNamesTheClashingPatient` | ScheduleHomeVisit | Domain error |
| `clinicalNoteWithNineCharacters_isRejected_butTenCharacters_isAccepted` | RecordVisitOutcome | Boundary |
| `visitAlreadyDocumented_cannotBeDocumentedAgain` | RecordVisitOutcome | Domain error |
| `admittingPatientFromSharedReferral_addsToCaseloadAndClearsTheReferral` | AdmitPatientToCaseload | Happy path |
| `outcomeIsOverdueOnlyAfterThePlannedFinishTime_andRoundIsInTimeOrder` | PlanTodaysRound | Boundary |

A mock repository (`MockCaseloadRepository`) is used during unit testing so that the business logic can be tested without depending on Core Data or the App Group.

## Setup Instructions

1. Clone or download the `HomeVisit` repository.
2. Open `HomeVisit.xcodeproj` in Xcode 16 or later.
3. For each of the four targets (`HomeVisit`, `NextVisitWidgetExtension`, `ReferralShareExtension`, `VisitReminderNotification`), open **Signing & Capabilities** and choose your Team. When testing in the simulator with a free Personal Team, you can set Team to **None**.
4. Check that the App Group `group.com.heather.HomeVisit` is the same in `Config/HomeVisit.entitlements`, `Config/NextVisitWidget.entitlements`, `Config/ReferralShareExtension.entitlements` and `Shared/AppGroup.swift`.
5. Select the `HomeVisit` scheme and an iPhone simulator running iOS 17 or later.
6. Press `Command + B` to build the project.
7. Press `Command + R` to run the application, and tap **Allow** for notifications.
8. Press `Command + U` to run the unit tests.
9. Open the Test Navigator in Xcode to view the unit test results.

## Technology Used
- Swift
- SwiftUI
- Swift Testing
- Core Data
- WidgetKit
- Share Extension
- User Notifications and Notification Content Extension
- App Groups
- Git and GitHub
