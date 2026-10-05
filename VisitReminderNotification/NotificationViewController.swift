//  NotificationViewController.swift
//  VisitReminderNotification
//
//  Template placeholder – replaced on feature/visit-reminder-notification.

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        label.frame = view.bounds
        label.numberOfLines = 0
        view.addSubview(label)
    }

    func didReceive(_ notification: UNNotification) {
        label.text = notification.request.content.body
    }
}
