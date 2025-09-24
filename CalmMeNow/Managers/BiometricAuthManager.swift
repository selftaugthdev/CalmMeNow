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
    // Check if biometric authentication is available
    guard isBiometricAvailable() else {
      print("🔐 Biometric authentication not available")
      await MainActor.run {
        self.isAuthenticated = false
      }
      return false
    }
    
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
      
      print("🔐 Biometric authentication successful: \(success)")
      return success
    } catch {
      await MainActor.run {
        self.isAuthenticated = false
      }
      
      // Log the specific error for debugging
      if let laError = error as? LAError {
        switch laError.code {
        case .userCancel:
          print("🔐 Biometric authentication cancelled by user")
        case .userFallback:
          print("🔐 Biometric authentication fallback requested")
        case .systemCancel:
          print("🔐 Biometric authentication cancelled by system")
        case .passcodeNotSet:
          print("🔐 Biometric authentication failed: Passcode not set")
        case .biometryNotAvailable:
          print("🔐 Biometric authentication failed: Biometry not available")
        case .biometryNotEnrolled:
          print("🔐 Biometric authentication failed: Biometry not enrolled")
        case .biometryLockout:
          print("🔐 Biometric authentication failed: Biometry locked out")
        default:
          print("🔐 Biometric authentication failed with error: \(laError.localizedDescription)")
        }
      } else {
        print("🔐 Biometric authentication failed with unknown error: \(error.localizedDescription)")
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
