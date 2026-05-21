// Enables rich notifications (images) on iOS. Requires mutable-content (OneSignal sets this when you add images).
// See: https://documentation.onesignal.com/docs/en/ios-sdk-setup

import UserNotifications
import OneSignalExtension

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        receivedRequest = request
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        NSLog("OneSignal NSE didReceive: \(request.content.userInfo)")

        if let bestAttemptContent {
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                receivedRequest,
                with: bestAttemptContent,
                withContentHandler: contentHandler
            )
        } else {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            NSLog("OneSignal NSE timeWillExpire")
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(receivedRequest, with: bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
}
