import Foundation
import UserNotifications

public final class NotificationService: Sendable {
    public static let shared = NotificationService()

    private init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func sendWallpaperChangedNotification(item: WallpaperItem) {
        let content = UNMutableNotificationContent()
        content.title = "Art Wallpapers"
        content.subtitle = item.title
        content.body = "\(item.artist) • \(item.dateDisplay)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
