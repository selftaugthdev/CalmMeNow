import FirebaseAnalytics
import FirebaseCore
import Foundation

class FirebaseAnalyticsService {
  static let shared = FirebaseAnalyticsService()

  private init() {}

  // MARK: - Emotion Tracking

  /// Track when a user selects an emotion
  func trackEmotionSelected(emotion: String) {
    // Check if Firebase is ready
    guard FirebaseApp.app() != nil else {
      print("⚠️ Firebase not ready yet, skipping emotion tracking")
      return
    }

    Analytics.logEvent(
      "emotion_selected",
      parameters: [
        "emotion": emotion,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Emotion '\(emotion)' selected")

    // Force analytics to send immediately (for debugging)
    Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)

    // Force Firebase to send events immediately
    Analytics.logEvent("debug_force_send", parameters: ["test": "immediate"])
  }

  /// Track when a user selects intensity level
  func trackIntensitySelected(emotion: String, intensity: String) {
    // Check if Firebase is ready
    guard FirebaseApp.app() != nil else {
      print("⚠️ Firebase not ready yet, skipping intensity tracking")
      return
    }

    Analytics.logEvent(
      "intensity_selected",
      parameters: [
        "emotion": emotion,
        "intensity": intensity,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Intensity '\(intensity)' selected for emotion '\(emotion)'")
  }

  /// Track when a user starts a relief program
  func trackReliefProgramStarted(emotion: String, intensity: String, programType: String) {
    Analytics.logEvent(
      "relief_program_started",
      parameters: [
        "emotion": emotion,
        "intensity": intensity,
        "program_type": programType,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Relief program '\(programType)' started for \(intensity) \(emotion)")
  }

  /// Track when a user completes a relief program
  func trackReliefProgramCompleted(
    emotion: String, intensity: String, programType: String, duration: TimeInterval
  ) {
    Analytics.logEvent(
      "relief_program_completed",
      parameters: [
        "emotion": emotion,
        "intensity": intensity,
        "program_type": programType,
        "duration_seconds": duration,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print(
      "📊 Analytics: Relief program '\(programType)' completed in \(Int(duration))s for \(intensity) \(emotion)"
    )
  }

  /// Track when a user exits a relief program early
  func trackReliefProgramExited(
    emotion: String, intensity: String, programType: String, duration: TimeInterval
  ) {
    Analytics.logEvent(
      "relief_program_exited",
      parameters: [
        "emotion": emotion,
        "intensity": intensity,
        "program_type": programType,
        "duration_seconds": duration,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print(
      "📊 Analytics: Relief program '\(programType)' exited after \(Int(duration))s for \(intensity) \(emotion)"
    )
  }

  // MARK: - Emergency Calm Tracking

  /// Track when emergency calm is used
  func trackEmergencyCalmUsed() {
    Analytics.logEvent(
      "emergency_calm_used",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Emergency calm used")
  }

  // MARK: - App Usage Tracking

  /// Track app session start
  func trackAppSessionStart() {
    Analytics.logEvent(
      "app_session_start",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: App session started")
  }

  /// Track app session end
  func trackAppSessionEnd(duration: TimeInterval) {
    Analytics.logEvent(
      "app_session_end",
      parameters: [
        "duration_seconds": duration,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: App session ended after \(Int(duration))s")
  }

  // MARK: - Feature Usage Tracking

  /// Track when user accesses journal
  func trackJournalAccessed() {
    Analytics.logEvent(
      "journal_accessed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Journal accessed")
  }

  /// Track when user creates journal entry
  func trackJournalEntryCreated(emotion: String?, intensity: String?) {
    var parameters: [String: Any] = [
      "timestamp": Date().timeIntervalSince1970
    ]

    if let emotion = emotion {
      parameters["emotion"] = emotion
    }

    if let intensity = intensity {
      parameters["intensity"] = intensity
    }

    Analytics.logEvent("journal_entry_created", parameters: parameters)

    print("📊 Analytics: Journal entry created")
  }

  /// Track when user accesses breathing exercises
  func trackBreathingExerciseAccessed() {
    Analytics.logEvent(
      "breathing_exercise_accessed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Breathing exercise accessed")
  }

  // MARK: - User Properties

  /// Set user properties for better analytics
  func setUserProperties() {
    // Set user properties that will be included in all events
    Analytics.setUserProperty("ios_user", forName: "platform")
    Analytics.setUserProperty("calm_me_now", forName: "app_name")

    print("📊 Analytics: User properties set")
  }

  // MARK: - Debug Methods

  /// Check if Firebase Analytics is properly configured
  func checkFirebaseConfiguration() {
    print("📊 Analytics: Checking Firebase configuration...")

    // Log a test event
    Analytics.logEvent(
      "firebase_test",
      parameters: [
        "test": "configuration_check",
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Test event logged")
  }
}
