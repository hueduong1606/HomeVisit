//  NotificationViewController.swift
//  VisitReminderNotification (Notification Content Extension)
//
//  User scenario: 15 minutes before each visit the nurse gets a reminder.
//  The default notification only fits one line of text; pressing and holding
//  shows this custom card so the nurse can check the address and any safety
//  alert (e.g. "Dog on premises – call ahead") before getting out of the car.
//
//  Handles notifications whose category is VISIT_REMINDER
//  (see VisitReminderNotification-Info.plist).

import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    //MARK: - PROPERTIES
    private var hostingController: UIHostingController<VisitReminderCardView>?

    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    //MARK: - UNNotificationContentExtension
    // Called by iOS with the reminder that was expanded
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        let cardView = VisitReminderCardView(
            payload: VisitReminderPayload(userInfo: content.userInfo),
            fallbackTitle: content.title,
            fallbackBody: content.body
        )

        // Re-use the hosting controller if iOS delivers an updated reminder
        if let existingController = hostingController {
            existingController.rootView = cardView
            return
        }

        let controller = UIHostingController(rootView: cardView)
        controller.view.backgroundColor = .clear
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        controller.didMove(toParent: self)
        hostingController = controller

        // Size the notification to fit the card
        let fittingSize = controller.sizeThatFits(in: CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude))
        preferredContentSize = CGSize(width: view.bounds.width, height: fittingSize.height)
    }
}
