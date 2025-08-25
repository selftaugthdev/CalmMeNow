import Foundation
import WatchConnectivity

final class PhoneWCSessionHandler: NSObject, WCSessionDelegate {
  static let shared = PhoneWCSessionHandler()

  func activate() {
    guard WCSession.isSupported() else { return }
    let s = WCSession.default
    s.delegate = self
    s.activate()
    print("📡 iPhone WCSession activating…")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      let s = WCSession.default
      print(
        "📱 state → isPaired:", s.isPaired,
        "watchAppInstalled:", s.isWatchAppInstalled,
        "reachable:", s.isReachable)

      // Test UserDefaults
      let endBehavior = UserDefaults.standard.integer(forKey: "endBehavior")
      print("🔧 Initial endBehavior setting:", endBehavior)
    }
  }

  // MARK: Logs so you can see state changes
  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    print(
      "✅ iPhone activation:", activationState.rawValue, "error:",
      error?.localizedDescription ?? "none")
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    print("🔌 iPhone reachable to Watch:", session.isReachable)
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    print("📩 iPhone didReceiveMessage:", message)
    handle(message)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    print("📩 iPhone didReceiveMessage + replyHandler:", message)
    handle(message)
    replyHandler(["ok": true])
  }

  private func handle(_ message: [String: Any]) {
    print("🔍 Handling message:", message)

    if message["action"] as? String == "startAudio",
      let length = message["length"] as? Int
    {
      print("🎵 Starting calm audio for \(length)s (from Watch)")
      DispatchQueue.main.async {
        // Pick a default calm sound you already bundle
        AudioManager.shared.playSound("mixkit-serene-anxious")  // TODO: change to your preferred filename

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(length)) {
          print("🛑 Stopping calm audio (auto-stop)")
          AudioManager.shared.stopSound()
        }
      }
    } else if message["action"] as? String == "stopAudio" {
      print("🛑 Stop audio (from Watch)")

      // Check user preference for end behavior
      let endBehavior = UserDefaults.standard.integer(forKey: "endBehavior")
      print("🔧 Current endBehavior setting:", endBehavior)

      switch endBehavior {
      case 0:  // Ask every time
        // For now, just stop audio. In a full implementation, you'd show an alert
        print("📋 User preference: Ask every time - stopping audio")
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      case 1:  // Continue audio
        print("🎵 User preference: Continue audio - keeping audio playing")
      // Do nothing, let audio continue
      case 2:  // Stop audio
        print("🛑 User preference: Stop audio - stopping audio")
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      default:
        print("🛑 Default behavior: Stop audio")
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      }
      return
    } else if message["ping"] != nil {
      print("📶 Received ping")
    } else {
      print("ℹ️ Unhandled message:", message)
    }
  }

  // iOS-only required stubs when switching between watches
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
