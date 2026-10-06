# HomeVisit

**A round planner for community nurses who deliver care in patients' homes.**

| | |
|---|---|
| Platform | iOS 17.0+, iPhone (Xcode 16 or later) |
| Architecture | SwiftUI · MVVM · Use Cases · Repository protocol |
| Database | Core Data (two related entities) |
| Extensions | WidgetKit widget · Share Extension · Notification Content Extension |
| App Group | `group.com.heather.HomeVisit` |
| Bundle IDs | `com.heather.HomeVisit` (+ `.NextVisitWidget`, `.ReferralShare`, `.VisitReminder`) |

---

## 1. Domain context

**Stakeholder:** a community nurse who drives between 6–10 patients' homes a day (wound care, medication reviews, post-discharge checks, palliative support).

**Problem:** the round changes all day. New referrals arrive by email or message and get retyped or lost; the next address and safety alert (e.g. *dog on premises*) are not at hand in the car; visits clash or are documented hours later from memory.

**Evidence:**

- The King's Fund (2016), *Understanding quality in district nursing services* – visits being **missed or postponed** because demand outstrips capacity. Reported in Public Finance: https://www.publicfinance.co.uk/node/24542
- Blay et al. (2025), *Community nursing: A time and motion study of community nurses' work and workload*, Journal of Advanced Nursing 81(7) – **documentation and travel** identified as areas to improve. https://ro.ecu.edu.au/ecuworks2022-2026/5441

---

## 2. Six screens (following the nurse's day)

| # | Screen | What the nurse does |
|---|---|---|
| 1 | **Today's Round** | Sees visits still to do in time order, *Outcome overdue* warnings, visits done, and visits *Coming up* on later days |
| 2 | **Visit Detail** | Reads the clinical alert and address; opens *Record Visit Outcome* |
| 3 | **Record Visit Outcome** | Records *Care completed* or *No access* with a clinical note |
| 4 | **Add Visit to Round** | Books a visit for today or plans ahead (up to 14 days, e.g. tomorrow's round the day before): patient, care type, date, time, duration |
| 5 | **Caseload** | Sees *Referrals waiting* (from the Share Extension) and all patients |
| 6 | **Admit Patient** | Adds a patient by hand or from a shared referral |

---

## 3. Architecture

```
View  ──>  ViewModel  ──>  Use Case  ──>  CaseloadRepository (protocol)  ──>  Core Data
                              │
                              └──>  RoundSyncing (protocol)  ──>  App Group JSON + WidgetCenter reload + reminders
```

### Four Use Cases

| Use Case | Business rules | Error enum |
|---|---|---|
| `PlanTodaysRoundUseCase` | Visits in time order; **Outcome overdue** once the planned finish time passes with nothing recorded; visits for the coming days listed under *Coming up* | `PlanTodaysRoundError` |
| `ScheduleHomeVisitUseCase` | Patient on caseload · not in the past · **15–180 minutes** · **up to 14 days ahead** · **finishes before midnight on its day** · **no clashing visits** | `ScheduleHomeVisitError` |
| `RecordVisitOutcomeUseCase` | Outcome recorded **once only** · clinical note **at least 10 characters** | `RecordVisitOutcomeError` |
| `AdmitPatientToCaseloadUseCase` | Name required · address needs a **street number** · **no duplicates** · referral cleared only after admission (and the nurse is told if it couldn't be cleared) | `AdmitPatientError` |

Every error message says **what went wrong and what to do next**, e.g.
*"This visit overlaps your visit with Arthur Nguyen. Pick a start time after that visit finishes."*

**Reliability:** loading failures show a message instead of an empty list; a failed Core Data save is rolled back and the nurse's typing stays on screen; the widget and reminders are only refreshed after a successful save (and keep their previous data if the round can't be read); App Group files are written atomically and the referral inbox is updated with `NSFileCoordinator`, so an unreadable inbox is never overwritten; reminders say *"Reminder scheduled"* only after iOS confirms, and explain when notifications are turned off. The round, caseload, referrals and widget refresh whenever the app becomes active.

### Core Data

`PatientRecord` 1 ──< `CareVisitRecord` (cascade delete). Domain query with a predicate in `CoreDataCaseloadRepository.fetchOutstandingVisits(scheduledOn:)`:

```swift
NSPredicate(format: "scheduledStart >= %@ AND scheduledStart < %@ AND statusRaw == %@", ...)
// "fetch all visits scheduled for today that the nurse has not documented yet"
```

**Why Core Data:** patient health information must stay private on the device (not in a personal iCloud account) and must work offline in the car or inside homes with no signal.

---

## 4. System extensions

| Extension | Nurse scenario | How it uses the App Group |
|---|---|---|
| **NextVisitWidget** (Home Screen `systemSmall` + Lock Screen `accessoryRectangular`) | In the car between homes, she sees the next time, patient and address without opening the app | Reads `TodaysRound.json`; the app calls `WidgetCenter.shared.reloadAllTimelines()` after every booking or outcome |
| **ReferralShareExtension** | A GP's referral arrives as text; she shares it straight into HomeVisit instead of retyping it | Writes `ReferralInbox.json`; the app shows it under *Referrals waiting* |
| **VisitReminderNotification** | 15 min before a visit, the reminder shows a visit card with the address and the **safety alert in orange** | Visit details travel in the notification (category `VISIT_REMINDER`) |

---

## 5. Setup

1. Unzip and open **`HomeVisit.xcodeproj`** in Xcode 16 or later.
2. For each of the 4 targets – `HomeVisit`, `NextVisitWidgetExtension`, `ReferralShareExtension`, `VisitReminderNotification` – open **Signing & Capabilities** and choose your **Team**.
3. The App Group `group.com.heather.HomeVisit` must be **identical** in these files:
   - `Config/HomeVisit.entitlements`
   - `Config/NextVisitWidget.entitlements`
   - `Config/ReferralShareExtension.entitlements`
   - `Shared/AppGroup.swift` → `AppGroup.identifier`
4. Select the **HomeVisit** scheme and an **iPhone simulator (iOS 17+)**, then press **⌘R**. Tap **Allow** for notifications.

> If Xcode shows a signing error about App Groups with a free Personal Team, set Team to **None** while you test in the simulator – the simulator does not need a provisioning profile.

---

## 6. How to test each feature, one by one

Do these in order – each step creates the data the next step needs.

### Step 1 – Admit a patient (Screens 5 → 6)
1. Tap the **Caseload** tab → tap the **person +** icon (top right).
2. Full name `Margaret Thompson`, address `14 Wattle Street, Parramatta`, clinical alert `Dog on premises – call ahead`.
3. Tap **Admit to Caseload** → Margaret appears under *Patients*.
4. **Error check:** admit someone with the address `Wattle Street` (no number) → red banner explains the street number is missing.

### Step 2 – Add a visit to the round (Screens 1 → 4)
1. Tap **Today's Round** → **+**.
2. Choose Margaret, *Wound care*, a time **about 30 minutes from now** (you can also pick tomorrow or any day in the next 14 days – it then appears under *Coming up*), 45 min → **Add to Round**.
3. The visit appears under *Still to visit*.
4. **Error checks:** set the duration to 10 min → "outside the safe range"; book a visit at 11:30 PM for 60 min → "would finish after midnight"; book a second visit at an overlapping time → "overlaps your visit with Margaret Thompson".

### Step 3 – Widget (Home Screen and Lock Screen)
1. Press **⇧⌘H** to go to the Home Screen.
2. Press and hold an empty area → **Edit** (top left) → **Add Widget** → search **HomeVisit** → **Next Home Visit** → **Add Widget** → **Done**.
3. The widget shows Margaret's time, name, address and the ⚠️ alert.
4. Lock Screen: press **⌘L** to lock, click once to wake it (don't unlock), press and hold the Lock Screen → **Customize** → **Lock Screen** → tap the widget area under the clock → **HomeVisit** → **Next Home Visit**.
5. Leave the widget on screen – Step 6 checks that it updates.

### Step 4 – Visit reminder (Notification Content Extension)
1. In the app, tap Margaret's visit → **Preview Visit Reminder**.
2. Wait until the screen says **"Reminder scheduled – it arrives in 5 seconds"** (if it says reminders are turned off, allow notifications in Settings → Notifications → HomeVisit), then press **⇧⌘H** (Home) or **⌘L** (lock).
3. When the banner arrives, **click and hold** it (on the Lock Screen, hold the notification). The custom **visit card** opens: time, patient, care type, address and the orange safety alert.
4. A real reminder is also scheduled automatically 15 minutes before every visit still to do – today and on the coming days you planned ahead.

### Step 5 – Share a referral (Share Extension)
1. Open **Safari** in the simulator and go to any page with text (on a real iPhone you can also use Notes, Mail or Messages).
2. Press and hold a word, drag the handles to select a few lines → tap **Share…** in the menu.
3. Tap **HomeVisit** in the app row (if it's not shown, scroll the row to **More** and turn HomeVisit on).
4. In *New Referral*, type patient name `Beatrice Collins` → **Save Referral to HomeVisit**. The share sheet closes.
5. Open HomeVisit → **Caseload** tab. The app refreshes when it becomes active, so Beatrice is already under **Referrals waiting**.
6. Tap the referral → the form is pre-filled → add the address `5 Marsden Street, Parramatta` → **Admit to Caseload**. The referral disappears and Beatrice is under *Patients*.

### Step 6 – Record the visit outcome (Screens 2 → 3)
1. **Today's Round** → tap Margaret's visit → **Record Visit Outcome**.
2. **Error check:** type `Done` → **Save Outcome** → banner: the note needs at least 10 characters.
3. Type `Dressing changed, wound healing well.` → **Save Outcome**.
4. The visit moves to *Visited today*. Go to the Home Screen – the widget now shows **Round complete** (or your next visit).

### Step 7 – Unit tests
Press **⌘U** (or open the Test navigator with **⌘6** and press ▶). All **6 tests** should pass.

### If something doesn't show
| Problem | Fix |
|---|---|
| Widget says *Open HomeVisit* | Open the app once – it writes today's round to the App Group |
| Widget or referrals never update | The App Group is different in one of the 4 places in Setup step 3 |
| Plain notification instead of the visit card | Click **and hold** the banner; make sure you ran the **HomeVisit** scheme |
| HomeVisit missing from the share sheet | Share **selected text** (not a link), then check **More** in the app row |

---

## 7. Unit tests (6, mock repository only)

`HomeVisitTests/Mocks.swift` holds `MockCaseloadRepository`, `MockRoundSync` and `MockReferralInbox` – no test touches Core Data or the App Group.

| # | Test | Use Case | Type |
|---|---|---|---|
| 1 | `planningTomorrowsVisitTheDayBefore_addsItToTheRoundAndRefreshesWidget` | ScheduleHomeVisit | Happy path |
| 2 | `visitOverlappingAnotherVisit_isRejectedAndNamesTheClashingPatient` | ScheduleHomeVisit | Domain error |
| 3 | `clinicalNoteWithNineCharacters_isRejected_butTenCharacters_isAccepted` | RecordVisitOutcome | Boundary |
| 4 | `visitAlreadyDocumented_cannotBeDocumentedAgain` | RecordVisitOutcome | Domain error |
| 5 | `admittingPatientFromSharedReferral_addsToCaseloadAndClearsTheReferral` | AdmitPatientToCaseload | Happy path |
| 6 | `outcomeIsOverdueOnlyAfterThePlannedFinishTime_andRoundIsInTimeOrder` | PlanTodaysRound | Boundary |

---

## 8. Project structure

```
HomeVisit/
├── HomeVisit/                  App: Domain, UseCases, Repository, Services, ViewModels, Views
├── Shared/                     Compiled into the app AND the extensions (App Group files)
├── HomeVisitWidget/            Widget extension
├── ReferralShareExtension/     Share extension
├── VisitReminderNotification/  Notification content extension
├── HomeVisitTests/             6 Swift Testing unit tests + mocks
└── Config/                     Entitlements and extension Info.plists
```

## 9. Git

`main` holds stable code; work is done on `feature/…`, `test/…`, `refactor/…` and `docs/…` branches and merged with `--no-ff`. Commits follow Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).

```bash
git remote add origin https://github.com/<your-username>/HomeVisit.git
git push -u origin main
git push origin --all
```
