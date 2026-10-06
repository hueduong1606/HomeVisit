//  ShareViewController.swift
//  ReferralShareExtension (Share Extension)
//
//  User scenario: a GP emails or messages a new referral. Instead of retyping it,
//  the nurse selects the text, taps Share -> HomeVisit, adds the patient's name
//  and saves it. The referral is written to the App Group container and appears
//  under "Referrals waiting" on the app's Caseload screen.

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    //MARK: - PROPERTIES
    let draft = ReferralDraft()

    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        showCaptureView()
        loadSharedText()
    }

    //MARK: - UI
    // Shows the SwiftUI form inside the extension (UIKit -> SwiftUI bridge)
    func showCaptureView() {
        let captureView = ReferralCaptureView(
            draft: draft,
            onSave: { self.saveReferral() },
            onCancel: { self.cancelShare() }
        )
        let hostingController = UIHostingController(rootView: captureView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    //MARK: - READ THE SHARED TEXT
    func loadSharedText() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = extensionItem.attachments?.first,
              provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) else {
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            if let sharedText = item as? String {
                DispatchQueue.main.async {
                    self.draft.referralText = sharedText
                }
            }
        }
    }

    //MARK: - SAVE / CANCEL

    // Writes the referral to the App Group, then always closes the share sheet
    func saveReferral() {
        let patientName = draft.patientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !patientName.isEmpty else {
            draft.errorMessage = "Enter the patient's name so you can find this referral in HomeVisit."
            return
        }

        let referral = PatientReferral(patientName: patientName, referralText: draft.referralText)
        do {
            try SharedContainerStore.appendReferral(referral)
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        } catch {
            // e.g. App Group not set up, or the inbox file can't be read – nothing is overwritten
            draft.errorMessage = "The referral couldn't be saved. \(error.localizedDescription)"
        }
    }

    // Closes the share sheet without saving
    func cancelShare() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
