import UserNotifications
import SwiftUI

final class CheckInReminderService: ObservableObject {
  static let shared = CheckInReminderService()

  @Published var isEnabled: Bool {
    didSet { UserDefaults.standard.set(isEnabled, forKey: "reminderEnabled") }
  }
  @Published var hour: Int {
    didSet { UserDefaults.standard.set(hour, forKey: "reminderHour") }
  }
  @Published var minute: Int {
    didSet { UserDefaults.standard.set(minute, forKey: "reminderMinute") }
  }

  private let notificationID = "calmnow_checkin_reminder"

  init() {
    isEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
    hour      = UserDefaults.standard.object(forKey: "reminderHour")   as? Int ?? 9
    minute    = UserDefaults.standard.object(forKey: "reminderMinute") as? Int ?? 0
  }

  // MARK: - Public

  /// Request permission then schedule. Returns true if granted.
  @discardableResult
  func requestPermissionAndEnable() async -> Bool {
    do {
      let granted = try await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound])
      if granted {
        await MainActor.run {
          isEnabled = true
          scheduleReminder()
        }
      }
      return granted
    } catch {
      return false
    }
  }

  func scheduleReminder() {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [notificationID])

    let content = UNMutableNotificationContent()
    content.title = "How are you today? 🌱"
    content.body  = "Take a moment to check in with Calm SOS."
    content.sound = .default

    var dc = DateComponents()
    dc.hour   = hour
    dc.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
    let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
    center.add(request)
  }

  func disableReminder() {
    isEnabled = false
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
  }

  func updateTime(hour: Int, minute: Int) {
    self.hour   = hour
    self.minute = minute
    if isEnabled { scheduleReminder() }
  }

  /// Formatted display string, e.g. "9:00 AM"
  var timeDisplayString: String {
    var dc = DateComponents()
    dc.hour = hour; dc.minute = minute
    guard let date = Calendar.current.date(from: dc) else { return "\(hour):\(String(format: "%02d", minute))" }
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
  }
}
