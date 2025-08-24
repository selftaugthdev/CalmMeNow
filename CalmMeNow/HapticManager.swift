import Foundation
import UIKit

class HapticManager {
  static let shared = HapticManager()

  private init() {}

  // MARK: - Haptic Feedback Methods

  /// Light haptic feedback for subtle interactions
  func lightImpact() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
  }

  /// Medium haptic feedback for standard button taps
  func mediumImpact() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
  }

  /// Heavy haptic feedback for important actions
  func heavyImpact() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    impactFeedback.impactOccurred()
  }

  /// Rigid haptic feedback for sharp, precise interactions
  func rigidImpact() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    impactFeedback.impactOccurred()
  }

  /// Soft haptic feedback for gentle interactions
  func softImpact() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
    impactFeedback.impactOccurred()
  }

  /// Success haptic feedback for positive outcomes
  func success() {
    let notificationFeedback = UINotificationFeedbackGenerator()
    notificationFeedback.notificationOccurred(.success)
  }

  /// Warning haptic feedback for cautionary actions
  func warning() {
    let notificationFeedback = UINotificationFeedbackGenerator()
    notificationFeedback.notificationOccurred(.warning)
  }

  /// Error haptic feedback for negative outcomes
  func error() {
    let notificationFeedback = UINotificationFeedbackGenerator()
    notificationFeedback.notificationOccurred(.error)
  }

  /// Selection haptic feedback for picker/selection changes
  func selection() {
    let selectionFeedback = UISelectionFeedbackGenerator()
    selectionFeedback.selectionChanged()
  }

  // MARK: - Context-Specific Methods

  /// Haptic feedback for emotion button selection
  func emotionButtonTap() {
    mediumImpact()
  }

  /// Haptic feedback for emergency/panic button
  func emergencyButtonTap() {
    heavyImpact()
  }

  /// Haptic feedback for intensity selection
  func intensitySelection() {
    lightImpact()
  }

  /// Haptic feedback for continue/confirmation buttons
  func continueButtonTap() {
    success()
  }

  /// Haptic feedback for cancel/back buttons
  func cancelButtonTap() {
    lightImpact()
  }

  /// Haptic feedback for audio play/pause
  func audioControl() {
    softImpact()
  }

  /// Haptic feedback for breathing exercises
  func breathingPhase() {
    lightImpact()
  }
}
