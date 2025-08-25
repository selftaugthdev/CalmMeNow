import WatchConnectivity

class WCSessionDelegateHelper: NSObject, WCSessionDelegate {
  static let shared = WCSessionDelegateHelper()
  private override init() { super.init() }

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func sendStartAudio(length: Int) {
    let msg: [String: Any] = ["action": "startAudio", "length": length]

    guard WCSession.default.isReachable else {
      return
    }

    WCSession.default.sendMessage(
      msg,
      replyHandler: { _ in },
      errorHandler: { _ in })
  }

  func sendStopAudio() {
    let msg: [String: Any] = ["action": "stopAudio"]

    guard WCSession.default.isReachable else {
      return
    }

    WCSession.default.sendMessage(
      msg,
      replyHandler: { _ in },
      errorHandler: { _ in })
  }

  func sendPing() {
    let msg = ["ping": Date().timeIntervalSince1970]
    guard WCSession.default.isReachable else {
      return
    }
    WCSession.default.sendMessage(
      msg,
      replyHandler: { _ in },
      errorHandler: { _ in })
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    // Reachability changed
  }

  // Required
  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    // Activation completed
  }
}
