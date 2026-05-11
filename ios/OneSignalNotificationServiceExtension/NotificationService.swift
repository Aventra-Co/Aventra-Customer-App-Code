import UserNotifications

@objc(NotificationService)
class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var receivedRequest: UNNotificationRequest!

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let urlString = extractAttachmentUrl(from: request.content.userInfo),
              let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            contentHandler(bestAttemptContent ?? request.content)
            return
        }

        downloadAttachment(from: url) { attachment in
            if let attachment {
                self.bestAttemptContent?.attachments = [attachment]
            }
            contentHandler(self.bestAttemptContent ?? request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func extractAttachmentUrl(from userInfo: [AnyHashable: Any]) -> String? {
        if let s = firstUrlString(in: userInfo["ios_attachments"]) { return s }
        if let custom = userInfo["custom"] as? [AnyHashable: Any],
           let a = custom["a"] as? [AnyHashable: Any],
           let s = firstUrlString(in: a["ios_attachments"]) { return s }
        if let osData = userInfo["os_data"] as? [AnyHashable: Any],
           let s = firstUrlString(in: osData["ios_attachments"]) { return s }
        return nil
    }

    private func firstUrlString(in value: Any?) -> String? {
        if let dict = value as? [AnyHashable: Any] {
            for (_, v) in dict { if let s = v as? String, !s.isEmpty { return s } }
            return nil
        }
        if let s = value as? String, !s.isEmpty { return s }
        return nil
    }

    private func downloadAttachment(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.downloadTask(with: url) { tempUrl, _, _ in
            guard let tempUrl else { completion(nil); return }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            let ext = components?.url?.pathExtension ?? "jpg"
            let localUrl = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext.isEmpty ? "jpg" : ext)
            do {
                try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                completion(try UNNotificationAttachment(identifier: "image", url: localUrl, options: nil))
            } catch {
                completion(nil)
            }
        }.resume()
    }
}