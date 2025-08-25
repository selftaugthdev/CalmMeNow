import Foundation
import WatchConnectivity

final class PhoneWCSessionHandler: NSObject, WCSessionDelegate {
  static let shared = PhoneWCSessionHandler()

  func activate() {
    guard WCSession.isSupported() else { return }
    let s = WCSession.default
    s.delegate = self
    s.activate()
  }

  // MARK: Logs so you can see state changes
  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    // Activation completed
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    // Reachability changed
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handle(message)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    handle(message)
    replyHandler(["ok": true])
  }

  private func handle(_ message: [String: Any]) {
    if message["action"] as? String == "startAudio",
      let length = message["length"] as? Int
    {
      DispatchQueue.main.async {
        // Pick a default calm sound you already bundle
        AudioManager.shared.playSound("mixkit-serene-anxious")  // TODO: change to your preferred filename

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(length)) {
          AudioManager.shared.stopSound()
        }
      }
    } else if message["action"] as? String == "stopAudio" {
      // Check user preference for end behavior
      let endBehavior = UserDefaults.standard.integer(forKey: "endBehavior")

      switch endBehavior {
      case 0:  // Ask every time
        // For now, just stop audio. In a full implementation, you'd show an alert
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      case 1:  // Continue audio
        // Do nothing, let audio continue
        break
      case 2:  // Stop audio
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      default:
        DispatchQueue.main.async {
          AudioManager.shared.stopSound()
        }
      }
      return
    } else if message["ping"] != nil {
      // Ping received - no action needed
    } else {
      print("ℹ️ Unhandled message:", message)
    }
  }

  // iOS-only required stubs when switching between watches
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
