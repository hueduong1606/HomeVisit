# HomeVisit

## Overview

HomeVisit is a SwiftUI iOS MVP for community nurses who deliver care in patients' homes. It brings the daily round, upcoming visits, patient details and shared referrals into one place. Nurses can plan visits up to 14 days ahead and record outcomes while the details are still fresh.

## Domain Context
The MVP is designed around a community nurse visiting about 6–10 patients' homes a day. Visits may involve wound care, medication reviews, post-discharge checks or palliative support.
The app records both the planned visit and its outcome. Its main business rules are:
- A new visit must not overlap another visit still to do.
- A visit must not start in the past, must last 15-180 minutes and must finish before midnight on its scheduled day.
- Visits can be planned up to 14 days ahead.
- An outstanding visit is marked Outcome overdue once its planned finish time has passed.
- An outcome can be recorded once, as Care completed or No access.
- Each outcome requires a note of at least 10 characters describing the care provided or why access was not possible.
- Access and safety information, such as Dog on premises - call ahead, is shown with the visit details so the nurse can check it before entering the home.

## Main Features

The nurse can:
- View today's outstanding visits in time order, including Outcome overdue warnings.
- Review visits with recorded outcomes and see later visits under Coming up.
- Check patient details and schedule visits by care type, date, time and duration.
- Record Care completed or No access, together with a note.
- Review the caseload and admit patients manually or from shared referral text.
- Check the next visit through a Home Screen or Lock Screen widget.
- Share referral text from another app and view custom visit reminder cards.
- Receive clear messages when information cannot be loaded, an action fails or a business rule prevents it.

## Domain-Centred Architecture
The main business flow is:

```
View  --->  ViewModel  --->  Use Case  --->  CaseloadRepository (protocol)  --->  Core Data
                               |
                               -> RoundSyncing (protocol)  --->  App Group + widget + reminders
```
After a successful change to the round, RoundSyncing updates the widget snapshot and reminders. Shared referrals enter through ReferralInbox for admission.

### Domain
It contains Patient, CareVisit, CareType, VisitStatus, VisitOutcome and TodaysRound. These types represent the caseload, planned care, recorded outcomes and daily progress.

### Use Cases

Business operations are separated into four main Use Cases:

- PlanTodaysRoundUseCase
- ScheduleHomeVisitUseCase
- RecordVisitOutcomeUseCase
- AdmitPatientToCaseloadUseCase

Each Use Case is responsible for one main business operation instead of placing the business rules directly inside the SwiftUI views. Each one enforces its own domain rules and has a typed error enum (PlanTodaysRoundError, ScheduleHomeVisitError, RecordVisitOutcomeError, AdmitPatientError).

### Services and System Extensions

The application uses services for work that is shared between the app and its system extensions:
- WidgetAndReminderRoundSync implements RoundSyncing
- VisitReminderScheduler manages reminder
- AppGroupReferralInbox implements ReferralInbox.

The widget supports Home Screen (systemSmall) and Lock Screen (accessoryRectangular) layouts. The Home Screen layout also shows any recorded access or safety alert. Shared referrals are reviewed, and missing details entered, before admission.

The main app schedules reminders, normally 15 minutes before a visit. The custom card appears when the notification is expanded. Notifications require permission and follow the device's notification settings.

- NextVisitWidget: it shows the next visit's time, patient, address and alert on the Home Screen and Lock Screen.
 -> Therefor between visits, while parked, the nurse can quickly check the next appointment time, patient and address without opening the app. This keeps the next visit easy to find during a busy round.

- VisitReminderNotification shows a visit card 15 minutes before each visit, with the safety alert in orange.
 -> The reminder draws attention to an upcoming visit. When expanded, its custom card brings the appointment details, address and highlighted safety alert together, helping the nurse check important information before entering the home.

- ReferralShareExtension saves referral text shared from another app so it appears under Referrals waiting.
  -> The nurse can share selected referral text from another app into HomeVisit. This reduces retyping and keeps referrals together under Referrals waiting, ready for review and admission.

Overall these services keep the widget and reminders in step with the round, but only after a successful save. They also read the referrals shared from other apps.

### Repository and Persistence
- CaseloadRepository defines how patients and visits are loaded and saved. 
- CoreDataCaseloadRepository implements this protocol using Core Data. Views and ViewModels do not call Core Data APIs directly. 

The database has two related entities: PatientRecord and CareVisitRecord. One patient can receive several visits, with each visit having its own schedule and outcome. This allows patient details to be stored once and linked to multiple visits. Queries can then identify visits that still need an outcome on a particular day, supporting the nurse's daily round.

Core Data was chosen for local storage and offline access, so the nurse can load and save information without an internet connection. The persistent store is held in the App Group container.

If a save fails, the repository rolls back the unsaved changes and reports the failure. The form remains available so the nurse can retry.

### ViewModel

Each screen has its own ViewModel:
- AdmitPatientViewModel
- CaseloadViewMode
- RecordOutcomeViewModel
- ScheduleVisitViewModel
- TodaysRoundViewModel

The ViewModels:

- load the round, patients and referrals
- call the required Use Case
- update the published state shown on screen
- provide error messages to the interface

### Views

The main SwiftUI screens include:
- TodaysRoundView
- VisitDetailView
- RecordOutcomeView
- ScheduleVisitView
- CaseloadView
- AdmitPatientView

The screens follow the nurse's day from planning the round and visiting each home through to recording outcomes and admitting new patients from referrals.

## Accessibility

Clinical alerts are shown with a warning symbol and written text, not by colour alone. Buttons and screen titles use clear domain language, such as **Add to Round**, **Record Visit Outcome** and **Admit to Caseload**, so that the required action is understandable to the nurse using the app.

## Testing

Unit testing focuses on the four business Use Cases:
- PlanTodaysRoundUseCase
- ScheduleHomeVisitUseCase
- RecordVisitOutcomeUseCase
- AdmitPatientToCaseloadUseCase

The project uses Swift Testing with `@Test` and `#expect`.

The six tests above cover:
- successful business operations
- boundary conditions
- important domain error cases

A mock repository (`MockCaseloadRepository`) is used during unit testing so that the business logic can be tested without depending on Core Data or the App Group.

## App Group Identifier

The App Group identifier is group.com.heather.HomeVisit.

- The main app, Widget and Share Extension use this shared container to exchange information:
- The main app saves the round snapshot, which the widget reads to display the next visit.
- The Share Extension saves referral text, which the main app reads for patient admission.


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
- Git and GitHub : Gitlink: https://github.com/hueduong1606/HomeVisit
