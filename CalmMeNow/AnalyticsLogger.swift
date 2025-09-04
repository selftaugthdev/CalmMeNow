import FirebaseAnalytics
import Foundation

enum AnalyticEvent: String {
  case emergencyCalmStart = "emergency_calm_start"
  case emergencyCalmComplete = "emergency_calm_complete"
  case planGenerated = "plan_generated"
  case dailyCheckinSubmitted = "daily_checkin_submitted"
  case emergencyUsed = "emergency_used"
}

enum AnalyticParam {
  static let sessionId = "session_id"
  static let source = "source"
  static let durationMs = "duration_ms"
  static let completed = "completed"
  static let planVersion = "plan_version"
  static let stepsCount = "steps_count"
  static let model = "model"
  static let latencyMs = "latency_ms"
  static let severity = "severity"
  static let suggestedPath = "suggested_path"
  static let action = "action"
}

final class AnalyticsLogger {
  static let shared = AnalyticsLogger()
  private init() {}

  // Track running timers per session
  private var startTimes: [String: CFAbsoluteTime] = [:]

  // MARK: - Convenience

  func setUserProperty(_ name: String, value: String?) {
    Analytics.setUserProperty(value, forName: name)
  }

  func log(_ event: AnalyticEvent, _ params: [String: Any] = [:]) {
    Analytics.logEvent(event.rawValue, parameters: params)
  }

  // MARK: - Scenarios

  // Emergency Calm
  func emergencyCalmStart(source: String = "home") -> String {
    let id = UUID().uuidString
    startTimes[id] = CFAbsoluteTimeGetCurrent()
    log(
      .emergencyCalmStart,
      [
        AnalyticParam.sessionId: id,
        AnalyticParam.source: source,
      ])
    return id
  }

  func emergencyCalmComplete(sessionId: String, completed: Bool) {
    let started = startTimes.removeValue(forKey: sessionId) ?? CFAbsoluteTimeGetCurrent()
    let durMs = Int((CFAbsoluteTimeGetCurrent() - started) * 1000)
    log(
      .emergencyCalmComplete,
      [
        AnalyticParam.sessionId: sessionId,
        AnalyticParam.durationMs: durMs,
        AnalyticParam.completed: completed ? 1 : 0,
      ])
  }

  // Plan generated
  func planGenerated(stepsCount: Int, planVersion: String, model: String, latencyMs: Int) {
    log(
      .planGenerated,
      [
        AnalyticParam.stepsCount: stepsCount,
        AnalyticParam.planVersion: planVersion,
        AnalyticParam.model: model,
        AnalyticParam.latencyMs: latencyMs,
      ])
  }

  // Daily check-in
  func dailyCheckinSubmitted(severity: Int, suggestedPath: String, latencyMs: Int) {
    log(
      .dailyCheckinSubmitted,
      [
        AnalyticParam.severity: severity,
        AnalyticParam.suggestedPath: suggestedPath,
        AnalyticParam.latencyMs: latencyMs,
      ])
  }

  // Emergency screen actions (hotline, etc.)
  func emergencyUsed(action: String, sessionId: String) {
    log(
      .emergencyUsed,
      [
        AnalyticParam.action: action,
        AnalyticParam.sessionId: sessionId,
      ])
  }
}
