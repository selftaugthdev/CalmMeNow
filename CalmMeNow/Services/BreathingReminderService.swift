import UserNotifications
import SwiftUI

final class BreathingReminderService: ObservableObject {
  static let shared = BreathingReminderService()

  @Published var isEnabled: Bool {
    didSet { UserDefaults.standard.set(isEnabled, forKey: "breathingReminderEnabled") }
  }
  @Published var hour: Int {
    didSet { UserDefaults.standard.set(hour, forKey: "breathingReminderHour") }
  }
  @Published var minute: Int {
    didSet { UserDefaults.standard.set(minute, forKey: "breathingReminderMinute") }
  }

  private let notificationID = "calmnow_breathing_reminder"

  private let messages: [(title: String, body: String)] = [
    ("Time to breathe 🌬️", "A short breathing session can reset your whole day."),
    ("Your daily calm awaits 🧘", "Take 2 minutes to breathe and reset."),
    ("Breathing break ✨", "Keep your streak going — one session is all it takes."),
    ("Pause and breathe 💙", "Your mind will thank you for a quick breathing session."),
  ]

  init() {
    isEnabled = UserDefaults.standard.bool(forKey: "breathingReminderEnabled")
    hour      = UserDefaults.standard.object(forKey: "breathingReminderHour")   as? Int ?? 18
    minute    = UserDefaults.standard.object(forKey: "breathingReminderMinute") as? Int ?? 0
  }

  // MARK: - Public

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

    let msg = messages[Int.random(in: 0..<messages.count)]
    let content = UNMutableNotificationContent()
    content.title = msg.title
    content.body  = msg.body
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

  var timeDisplayString: String {
    var dc = DateComponents()
    dc.hour = hour; dc.minute = minute
    guard let date = Calendar.current.date(from: dc) else { return "\(hour):\(String(format: "%02d", minute))" }
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
  }
}
