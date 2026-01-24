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
      #if DEBUG
        print("⚠️ Firebase not ready yet, skipping emotion tracking")
      #endif
      return
    }

    Analytics.logEvent(
      "emotion_selected",
      parameters: [
        "emotion": emotion,
        "timestamp": Date().timeIntervalSince1970,
      ])

    #if DEBUG
      print("📊 Analytics: Emotion '\(emotion)' selected")
    #endif

    // Force analytics to send immediately (for debugging)
    Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)

    // Force Firebase to send events immediately
    Analytics.logEvent("debug_force_send", parameters: ["test": "immediate"])
  }

  /// Track when a user selects intensity level
  func trackIntensitySelected(emotion: String, intensity: String) {
    // Check if Firebase is ready
    guard FirebaseApp.app() != nil else {
      #if DEBUG
        print("⚠️ Firebase not ready yet, skipping intensity tracking")
      #endif
      return
    }

    Analytics.logEvent(
      "intensity_selected",
      parameters: [
        "emotion": emotion,
        "intensity": intensity,
        "timestamp": Date().timeIntervalSince1970,
      ])

    #if DEBUG
      print("📊 Analytics: Intensity '\(intensity)' selected for emotion '\(emotion)'")
    #endif
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

  // MARK: - New Feature Tracking

  /// Track when user starts 5-4-3-2-1 grounding exercise
  func trackGroundingExerciseStarted() {
    Analytics.logEvent(
      "grounding_exercise_started",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Grounding exercise started")
  }

  /// Track when user completes grounding exercise
  func trackGroundingExerciseCompleted() {
    Analytics.logEvent(
      "grounding_exercise_completed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Grounding exercise completed")
  }

  /// Track when user starts PMR exercise
  func trackPMRExerciseStarted() {
    Analytics.logEvent(
      "pmr_exercise_started",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: PMR exercise started")
  }

  /// Track when user completes PMR exercise
  func trackPMRExerciseCompleted() {
    Analytics.logEvent(
      "pmr_exercise_completed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: PMR exercise completed")
  }

  /// Track when user views crisis resources
  func trackCrisisResourcesViewed() {
    Analytics.logEvent(
      "crisis_resources_viewed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Crisis resources viewed")
  }

  /// Track when user calls crisis hotline
  func trackCrisisHotlineCalled(country: String) {
    Analytics.logEvent(
      "crisis_hotline_called",
      parameters: [
        "country": country,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Crisis hotline called from \(country)")
  }

  /// Track post-panic recovery view shown
  func trackPostRecoveryShown() {
    Analytics.logEvent(
      "post_recovery_shown",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Post-panic recovery view shown")
  }

  // MARK: - Premium Feature Tracking

  /// Track when user accesses trusted contact feature
  func trackTrustedContactAccessed() {
    Analytics.logEvent(
      "trusted_contact_accessed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Trusted contact accessed")
  }

  /// Track when user sends message to trusted contact
  func trackTrustedContactMessageSent() {
    Analytics.logEvent(
      "trusted_contact_message_sent",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Trusted contact message sent")
  }

  /// Track when user views pattern analytics
  func trackPatternAnalyticsViewed(insightsCount: Int) {
    Analytics.logEvent(
      "pattern_analytics_viewed",
      parameters: [
        "insights_count": insightsCount,
        "timestamp": Date().timeIntervalSince1970,
      ])

    print("📊 Analytics: Pattern analytics viewed with \(insightsCount) insights")
  }

  /// Track when user starts sleep routine
  func trackSleepRoutineStarted() {
    Analytics.logEvent(
      "sleep_routine_started",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Sleep routine started")
  }

  /// Track when user completes sleep routine
  func trackSleepRoutineCompleted() {
    Analytics.logEvent(
      "sleep_routine_completed",
      parameters: [
        "timestamp": Date().timeIntervalSince1970
      ])

    print("📊 Analytics: Sleep routine completed")
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
