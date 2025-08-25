import WatchConnectivity

class WCSessionDelegateHelper: NSObject, WCSessionDelegate {
  static let shared = WCSessionDelegateHelper()
  private override init() { super.init() }

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
    print("⌚️ Watch WCSession activated")
  }

  func sendStartAudio(length: Int) {
    let msg: [String: Any] = ["action": "startAudio", "length": length]
    print("⌚️ sendMessage ->", msg, "reachable:", WCSession.default.isReachable)

    guard WCSession.default.isReachable else {
      print("⚠️ iPhone not reachable (open the iOS app).")
      return
    }

    WCSession.default.sendMessage(
      msg,
      replyHandler: { reply in
        print("⌚️ got reply from iPhone:", reply)
      },
      errorHandler: { error in
        print("❌ sendMessage error:", error.localizedDescription)
      })
  }

  func sendStopAudio() {
    let msg: [String: Any] = ["action": "stopAudio"]
    print("⌚️ sendStopAudio ->", msg, "reachable:", WCSession.default.isReachable)

    guard WCSession.default.isReachable else {
      print("⚠️ iPhone not reachable (open the iOS app).")
      return
    }

    WCSession.default.sendMessage(
      msg,
      replyHandler: { reply in
        print("⌚️ got reply from iPhone:", reply)
      },
      errorHandler: { error in
        print("❌ sendStopAudio error:", error.localizedDescription)
      })
  }

  func sendPing() {
    let msg = ["ping": Date().timeIntervalSince1970]
    print("⌚️ PING ->", msg)
    guard WCSession.default.isReachable else {
      print("⚠️ not reachable")
      return
    }
    WCSession.default.sendMessage(
      msg,
      replyHandler: { reply in
        print("⌚️ PING reply:", reply)
      },
      errorHandler: { error in
        print("❌ PING error:", error.localizedDescription)
      })
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    print("🔌 Watch reachable to iPhone:", session.isReachable)
  }

  // Required
  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    print(
      "✅ Watch activation state:", activationState.rawValue, "error:",
      error?.localizedDescription ?? "none")
  }
}
