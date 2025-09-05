import FirebaseAuth

final class AuthManager {
  static let shared = AuthManager()
  private init() {}

  /// Call at app start (non-blocking).
  func warmUpAuth() {
    Task { _ = try? await ensureSignedIn() }
  }

  /// Await this before any callable.
  @discardableResult
  func ensureSignedIn() async throws -> User {
    if let u = Auth.auth().currentUser { return u }
    let result = try await Auth.auth().signInAnonymously()
    print("🔐 Anonymous UID:", result.user.uid)
    return result.user
  }
}
