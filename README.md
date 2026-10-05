# HomeVisit

**A round planner for community nurses who deliver care in patients' homes.**

HomeVisit helps a community (district) nurse run a day of 6–10 home visits: who to see next, where they live, what care they need, what safety alert to read before knocking, and a fast way to document each visit at the door. It also takes new GP or hospital referrals straight from Mail, Messages or Notes.

| | |
|---|---|
| Platform | iOS 17.0+, iPhone |
| Xcode | 16.0 or later (project uses folder-synchronised groups) |
| Language | Swift 5 language mode, SwiftUI, Swift Testing |
| Database | Core Data (local, private) |
| Extensions | WidgetKit widget · Share Extension · Notification Content Extension |
| App Group | `group.com.student.HomeVisit` |

---

## 1. Domain context

**Primary stakeholder:** a community nurse managing a daily round of home visits across a suburban area (for example, a district nurse in Western Sydney seeing post-discharge, wound-care and palliative patients).

**The problem.** Community nurses work alone, in the car, between homes. Their day is a list of visits that keeps changing: new referrals arrive, visits overrun, patients are not home. When the round lives on paper or in a desktop system:

- the next address and safety alert (dog on premises, falls risk) are not at hand when the nurse is in the car;
- referrals arrive by email or message and are retyped later, or lost;
- visits are documented hours later, from memory;
- visits clash or the day is overbooked, and visits get rushed or missed.

**Evidence.**

- The King's Fund (2016), *Understanding quality in district nursing services*, found a "profound and growing gap" between capacity and demand in district nursing, with visits being **missed or postponed**, care becoming rushed and task-focused, and the risk that care failures go undetected "behind closed doors" in patients' homes. Reported in Public Finance, "District nursing 'at breaking point', says King's Fund" (1 September 2016): https://www.publicfinance.co.uk/node/24542
- Blay, Duffield, Murray-Parahi, Drennan, Rowles & Sousa (2025), *Community nursing: A time and motion study of community nurses' work and workload*, Journal of Advanced Nursing 81(7), 3868–3878. This Australian study identified **inefficient documentation and travel practices** as areas where community nursing workload could be improved. https://ro.ecu.edu.au/ecuworks2022-2026/5441

---

## 2. What the app does (nurse workflow → screens)

The tabs and screens follow the nurse's day: **plan → drive → document → take new referrals.**

| # | Screen | Nurse task |
|---|---|---|
| 1 | **Today's Round** | See outstanding visits in driving order, progress, and which visits are running late |
| 2 | **Visit Detail** | Clinical alert first, then address with *Directions in Maps*, *Call patient*, visit outcome |
| 3 | **Record Visit Outcome** | Document *Care completed* (clinical note) or *No access* (reason) at the door |
| 4 | **Add Visit to Round** | Book a visit: patient, care type, time, duration |
| 5 | **Caseload** | Every patient; anyone with no visit booked in the next 7 days is flagged first |
| 6 | **Patient Detail** | Contact, alert, reason for referral, booked visits, documented visit history |
| 7 | **Admit to Caseload / Accept Referral** | Add a patient by hand or from a shared referral |
| 8 | **Referral Inbox** | Referrals saved by the Share Extension, oldest first |

Swipe actions use domain words: **Cancel Visit**, **Discharge**, **Decline**.

---

## 3. Architecture

```
Views (SwiftUI) ──> ViewModels (ObservableObject) ──> Use Cases (structs) ──> CaseloadRepository (protocol) ──> Core Data
                                                            │
                                                            └──> RoundSyncing (protocol) ──> App Group JSON + WidgetCenter + reminders
```

- **Views** never touch Core Data; they only call their ViewModel.
- **ViewModels** hold `@Published` state and call Use Cases. They get Use Cases from `AppDependencies`.
- **Use Cases** hold every business rule and throw a typed, nurse-facing error enum.
- **CaseloadRepository** is a protocol. `CoreDataCaseloadRepository` is the only type that builds fetch requests; `MockCaseloadRepository` replaces it in tests.
- **RoundSyncing** is called by Use Cases after every change to the round. The app implementation (`WidgetAndReminderRoundSync`) writes a snapshot to the App Group, calls `WidgetCenter.shared.reloadAllTimelines()` and reschedules visit reminders.

### Semantic domain model

| Type | Meaning |
|---|---|
| `Patient` | A person on the nurse's caseload |
| `CareVisit` | One booked home visit |
| `CareType` | Wound care, medication review, post-discharge check, diabetes management, palliative support |
| `VisitStatus` / `VisitOutcome` | Scheduled → Completed / No access |
| `TodaysRound` | The nurse's day: outstanding, closed and running-late visits |
| `CaseloadEntry` | A patient plus their visits and continuity-of-care flag |
| `PatientReferral` | A referral shared in from another app, waiting in the inbox |

### Use Cases and their business rules

| Use Case | Business rules | Error enum |
|---|---|---|
| `PlanTodaysRoundUseCase` | Outstanding visits in time order; flagged **running late** more than 15 min after start | `PlanTodaysRoundError` |
| `ScheduleHomeVisitUseCase` | Patient must be on caseload · not in the past (5 min grace) · 15–180 min · max **10 visits/day** · **no clashes** (back-to-back allowed) | `ScheduleHomeVisitError` |
| `RecordVisitOutcomeUseCase` | Outcome recorded **once** · not more than 30 min before the visit · clinical note at least **10 characters** | `RecordVisitOutcomeError` |
| `CancelHomeVisitUseCase` | Completed / no-access visits are part of the clinical record and **cannot be cancelled** | `CancelHomeVisitError` |
| `AdmitPatientToCaseloadUseCase` | Name required · address must include a street number · phone at least 8 digits if given · **no duplicates** · referral leaves the inbox only after a successful admission | `AdmitPatientError` |
| `ReviewCaseloadUseCase` | Flags any patient with **no visit booked in the next 7 days**; flagged patients first | `ReviewCaseloadError` |
| `DischargePatientUseCase` | Cannot discharge while any booked visit is still **undocumented** | `DischargePatientError` |

Every error has an `errorDescription` (what went wrong) and a `recoverySuggestion` (what to do next), shown together in `ErrorBannerView`. Example:

> *This visit overlaps your 10:00 AM visit with Arthur Nguyen. Pick a start time after that visit finishes.*

---

## 4. Database: Core Data

**Why Core Data, not CloudKit.** A nurse's caseload is health information. It must be fast, available offline (rural blackspots, inside brick homes), and it must **not** sync to the nurse's personal iCloud account. Core Data keeps it on the device, in the App Group container, and it works with no signal at all.

**Schema** (`HomeVisit.xcdatamodeld`) – two related entities:

```
PatientRecord 1 ──── * CareVisitRecord
  patientID (UUID)          visitID (UUID)
  fullName                  scheduledStart (Date)
  homeAddress               durationMinutes (Int16)
  contactNumber             careTypeRaw (String)
  clinicalAlert             statusRaw (String)
  referralNote              outcomeNote
  admittedOn (Date)         outcomeRecordedAt (Date)
  visits  (to-many, Cascade)  patient (to-one, Nullify)
```

Discharging a patient deletes their visits too (**Cascade**), so no orphan visits are left on the round.

**Domain query with a predicate** (`CoreDataCaseloadRepository.fetchOutstandingVisits(scheduledOn:)`):

```swift
NSPredicate(format: "scheduledStart >= %@ AND scheduledStart < %@ AND statusRaw == %@",
            startOfDay as NSDate, startOfNextDay as NSDate, VisitStatus.scheduled.rawValue)
```

*"Fetch every visit scheduled for today that the nurse has not yet documented."*

---

## 5. System extensions and why the nurse needs them

All three share data through the App Group **`group.com.student.HomeVisit`** (see `Shared/AppGroup.swift`).

### NextVisitWidget (WidgetKit) – Home Screen and Lock Screen

*Scenario:* the nurse is in the car between homes with the phone in a cradle. She needs the next visit time and address without unlocking the phone or opening the app.

- Families: `systemSmall`, `systemMedium`, `accessoryRectangular`, `accessoryInline`.
- Reads `TodaysRoundSnapshot.json` from the App Group container.
- The app reloads it (`WidgetCenter.shared.reloadAllTimelines()`) after **every** change: booking, documenting, cancelling, discharging, and when the app becomes active.
- Patient names use `.privacySensitive()`, so they are redacted on a locked device while the address and time stay visible.
- Never shows a bare "No data": it shows *Open HomeVisit*, *No visits today* or *Round complete*.

### ReferralShareExtension (Share Extension)

*Scenario:* a GP emails a referral. Instead of retyping it later, the nurse selects the text, taps **Share → HomeVisit**, checks the pre-filled name and address, and saves it.

- Accepts plain text and web links.
- Pre-fills name and address from lines like `Patient:` and `Address:` (`ReferralTextParser`).
- Writes the referral to `ReferralInbox.json` in the App Group container, then always dismisses (`completeRequest` / `cancelRequest`).
- The app shows it in the **Referral Inbox** tab (with a badge) until the patient is admitted or the referral is declined.

### VisitReminderNotification (Notification Content Extension)

*Scenario:* 15 minutes before each visit the nurse gets a reminder. Pressing and holding it shows a visit card with the time, patient, care type, address, and the **clinical alert in orange** ("Dog on premises – call ahead"), so she reads it before getting out of the car.

- Handles the `VISIT_REMINDER` category (`Config/VisitReminderNotification-Info.plist`).
- Visit details travel in the notification's `userInfo` (`VisitReminderPayload`).
- **Start Visit** action button.

---

## 6. Setup

1. Unzip and open **`HomeVisit.xcodeproj`** in Xcode 16 or later.
2. Select each of the four targets → **Signing & Capabilities** → choose your **Team**:
   `HomeVisit`, `NextVisitWidgetExtension`, `ReferralShareExtension`, `VisitReminderNotification`.
3. **Bundle identifiers / App Group** – if Xcode says `com.student.HomeVisit` is unavailable, change the prefix on all targets (e.g. `com.yourname.HomeVisit`, `com.yourname.HomeVisit.NextVisitWidget`, …). Then change the App Group in **three places** so they match exactly:
   - `Config/HomeVisit.entitlements`, `Config/NextVisitWidget.entitlements`, `Config/ReferralShareExtension.entitlements`
   - `Shared/AppGroup.swift` → `AppGroup.identifier`
   - (or use **+ Capability → App Groups** on each target and pick the same group)
4. Choose the **HomeVisit** scheme and an iPhone simulator (iOS 17+), then **Run** (⌘R). Allow notifications when asked.
5. Run the unit tests with **⌘U**.

> The simulator honours App Group entitlements without a paid developer account. On a real iPhone, the App Group must be registered to your team.

### Try every feature end-to-end (about 3 minutes)

1. **Caseload → person.badge.plus** – admit a patient with a street number in the address and a clinical alert.
2. **Today's Round → +** – book a visit for later today. Try a clashing time to see the nurse-facing error banner.
3. **Widget** – go to the Home Screen, long-press → **+** → *HomeVisit / Next Home Visit*, add the small or medium widget. For the Lock Screen widget: lock (⌘L), long-press the Lock Screen → Customize → add *Next Home Visit*.
4. **Notification extension** – open the visit → **Preview Visit Reminder**, then press ⇧⌘H to go Home. When the banner arrives, press and hold (or pull down) to see the visit card.
5. **Share extension** – open **Notes** in the simulator, type a referral such as
   ```
   Patient: Beatrice Collins
   Address: 5 Marsden Street, Parramatta NSW 2150
   Post hip replacement – wound review within 48 hours.
   ```
   select the text → **Share** → **HomeVisit** (you may need *More* the first time) → **Save to Inbox**. Open HomeVisit → **Referrals** → tap the referral → **Admit**.
6. **Record Visit Outcome** – open a visit, record *Care completed* with a note. The widget moves on to the next patient.

---

## 7. Unit tests

`HomeVisitTests/` uses **Swift Testing** (`@Test`, `#expect`) and **mock implementations only** – `MockCaseloadRepository`, `MockRoundSync`, `MockReferralInbox`. No test touches the Core Data stack or the App Group.

| File | What it proves |
|---|---|
| `ScheduleHomeVisitUseCaseTests` | Happy path + widget refresh; past time; clash names the other patient; discharged patient; storage failure message; **boundaries** 14/181 rejected, 15/180 accepted; back-to-back allowed; 5-min grace; 11th visit rejected |
| `RecordVisitOutcomeUseCaseTests` | Completed and No access; can't overwrite; can't document 31 min early; **boundaries** 9-char note rejected, 10 accepted, exactly 30 min early accepted |
| `AdmitPatientToCaseloadUseCaseTests` | Admission; referral cleared from inbox; address without street number; duplicate (case-insensitive); referral kept on failure; phone digits |
| `PlanTodaysRoundUseCaseTests` | Driving order and progress; other days excluded; running late at 16 min but not 15; nurse-facing failure |
| `CaseloadManagementUseCaseTests` | 7-day continuity flag; discharge blocked by undocumented visit; discharge; cancel blocked for documented visits; cancel |
| `DomainModelTests` | Visit clash rule; referral parser; every scheduling error has a next step |

Test names describe the scenario in nursing terms, e.g. `"A visit that overlaps another visit is rejected and names the clashing patient"`.

---

## 8. Project structure

```
HomeVisit/
├── HomeVisit/                     App target
│   ├── Domain/                    Patient, CareVisit, CareType, VisitStatus, TodaysRound, CaseloadEntry
│   ├── UseCases/                  7 Use Case structs + typed error enums
│   ├── Repository/                CaseloadRepository protocol, Core Data implementation, model, mapping
│   ├── Services/                  AppDependencies, RoundSyncing, reminders, referral inbox
│   ├── ViewModels/                One ObservableObject per screen
│   └── Views/                     SwiftUI screens + Components
├── Shared/                        Compiled into the app AND all extensions (App Group, snapshot, referral, payload)
├── HomeVisitWidget/               WidgetKit extension
├── ReferralShareExtension/        Share extension
├── VisitReminderNotification/     Notification content extension
├── HomeVisitTests/                Swift Testing unit tests + Mocks/
└── Config/                        Entitlements and extension Info.plists
```

---

## 9. Git workflow

- `main` holds only stable, working code. Features were built on branches and merged with `--no-ff`:
  `feature/domain-model`, `feature/core-data-repository`, `feature/use-cases`, `feature/round-screens`, `feature/caseload-and-referrals`, `feature/next-visit-widget`, `feature/referral-share-extension`, `feature/visit-reminder-notification`, `test/use-case-coverage`, `docs/readme`.
- Commit messages follow **Conventional Commits** (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).

To publish the history to GitHub:

```bash
git remote add origin https://github.com/<your-username>/HomeVisit.git
git push -u origin main
git push origin --all
```
