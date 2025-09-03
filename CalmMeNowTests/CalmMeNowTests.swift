import Testing
import WatchConnectivity

@testable import CalmMeNow

struct CalmMeNowTests {

  @Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  }

  @Test func testWCSessionActivation() async throws {
    // Test that WCSession is supported
    #expect(WCSession.isSupported())

    // Test that PhoneWCSessionHandler can be instantiated
    let handler = PhoneWCSessionHandler.shared

    // Test that the handler can activate (this should not throw)
    handler.activate()

    // Give it a moment to activate
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // Check if the session is activated (using correct enum values)
    let session = WCSession.default
    #expect(session.activationState == .activated || session.activationState == .inactive)
  }

}
