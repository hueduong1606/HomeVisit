//  ShareViewController.swift
//  ReferralShareExtension (Share Extension)
//
//  User scenario: a GP emails or messages a new referral. Instead of retyping it,
//  the nurse selects the text, taps Share -> HomeVisit, checks the name and address
//  and saves it. The referral is written to the App Group container, and the app
//  shows it in the Referral Inbox ready to admit.

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    //MARK: - PROPERTIES
    private let draft = ReferralDraft()

    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        embedCaptureView()
        loadSharedReferral()
    }

    //MARK: - UI
    // Hosts the SwiftUI form inside the extension's UIKit view controller
    private func embedCaptureView() {
        let captureView = ReferralCaptureView(
            draft: draft,
            onSave: { [weak self] in self?.saveReferral() },
            onCancel: { [weak self] in self?.cancelShare() }
        )
        let hostingController = UIHostingController(rootView: captureView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    //MARK: - READ SHARED CONTENT
    // Pulls plain text (and web links) out of what the host app shared
    private func loadSharedReferral() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            draft.isLoading = false
            return
        }

        let loadingGroup = DispatchGroup()

        for extensionItem in extensionItems {
            // Some apps put the text straight on the item
            if let attributedText = extensionItem.attributedContentText?.string {
                draft.append(attributedText)
            }

            for provider in extensionItem.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    loadingGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
                        let sharedText = ShareViewController.text(from: item)
                        DispatchQueue.main.async {
                            self?.draft.append(sharedText)
                            loadingGroup.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    loadingGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                        let sharedLink = (item as? URL)?.absoluteString
                        DispatchQueue.main.async {
                            self?.draft.append(sharedLink.map { "Referral link: \($0)" })
                            loadingGroup.leave()
                        }
                    }
                }
            }
        }

        loadingGroup.notify(queue: .main) { [weak self] in
            self?.draft.isLoading = false
        }
    }

    // Shared text can arrive as a String or as raw Data depending on the host app
    private static func text(from item: NSSecureCoding?) -> String? {
        if let string = item as? String {
            return string
        }
        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        if let url = item as? URL, url.isFileURL {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        return nil
    }

    //MARK: - SAVE / CANCEL

    // Writes the referral into the App Group inbox, then closes the share sheet
    private func saveReferral() {
        do {
            try SharedContainerStore.appendReferral(draft.makeReferral())
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil) // Always dismiss
        } catch {
            draft.errorMessage = "The referral couldn't be saved to HomeVisit. Open HomeVisit once, then try sharing again."
        }
    }

    // Closes the share sheet without saving anything
    private func cancelShare() {
        let cancelError = NSError(domain: "HomeVisit.ReferralShare", code: NSUserCancelledError, userInfo: nil)
        extensionContext?.cancelRequest(withError: cancelError)
    }
}
