//  ShareViewController.swift
//  ReferralShareExtension (Share Extension)
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    //PROPERTIES
    let draft = ReferralDraft()

    //LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        showCaptureView()
        loadSharedText()
    }

    // UI
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

    // READ THE SHARED TEXT
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

    //SAVE / CANCEL

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
            // ReferralSharingError explains what happened in nursing terms – nothing is overwritten,
            // and the share sheet stays open so the nurse can try again
            draft.errorMessage = error.localizedDescription
        }
    }

    // Closes the share sheet without saving
    func cancelShare() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
