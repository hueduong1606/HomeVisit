//  NotificationViewController.swift
//  VisitReminderNotification (Notification Content Extension)
//
//  User scenario: 15 minutes before each visit the nurse gets a reminder.
//  Pressing and holding it shows VisitReminderCardView instead of the plain
//  notification, so she can check the address and safety alert
//  (e.g. "Dog on premises – call ahead") before getting out of the car.
//
//  Handles notifications whose category is VISIT_REMINDER
//  (see Config/VisitReminderNotification-Info.plist).

import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    //MARK: - UNNotificationContentExtension
    // Called by iOS with the reminder that was opened
    func didReceive(_ notification: UNNotification) {
        guard let payload = VisitReminderPayload(userInfo: notification.request.content.userInfo) else {
            return // Not a HomeVisit reminder
        }

        // Show the SwiftUI visit card inside the notification (UIKit -> SwiftUI bridge)
        let hostingController = UIHostingController(rootView: VisitReminderCardView(payload: payload))
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        preferredContentSize = CGSize(width: view.bounds.width, height: 260)
    }
}
