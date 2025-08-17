import Foundation
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
  static let shared = BiometricAuthManager()
  
  @Published var isAuthenticated = false
  @Published var biometricType: LABiometryType = .none
  
  private init() {
    checkBiometricType()
  }
  
  private func checkBiometricType() {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      biometricType = context.biometryType
    } else {
      biometricType = .none
    }
  }
  
  func authenticate() async -> Bool {
    let context = LAContext()
    let reason = "Unlock your journal entries"
    
    do {
      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: reason
      )
      
      await MainActor.run {
        self.isAuthenticated = success
      }
      
      return success
    } catch {
      await MainActor.run {
        self.isAuthenticated = false
      }
      return false
    }
  }
  
  func getBiometricTypeString() -> String {
    switch biometricType {
    case .faceID:
      return "Face ID"
    case .touchID:
      return "Touch ID"
    case .opticID:
      return "Optic ID"
    case .none:
      return "None"
    @unknown default:
      return "Unknown"
    }
  }
  
  func isBiometricAvailable() -> Bool {
    return biometricType != .none
  }
}
