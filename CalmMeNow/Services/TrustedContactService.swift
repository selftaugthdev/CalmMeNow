//
//  TrustedContactService.swift
//  CalmMeNow
//
//  Service for managing trusted contacts
//

import Foundation
import UIKit

class TrustedContactService: ObservableObject {
  static let shared = TrustedContactService()

  @Published var trustedContact: TrustedContact?

  private let userDefaultsKey = "trustedContact"

  private init() {
    loadContact()
  }

  // MARK: - Public Methods

  func saveContact(_ contact: TrustedContact) {
    trustedContact = contact

    if let encoded = try? JSONEncoder().encode(contact) {
      UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
  }

  func deleteContact() {
    trustedContact = nil
    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
  }

  func hasValidContact() -> Bool {
    trustedContact?.isValid ?? false
  }

  /// Send SMS to trusted contact
  /// Returns true if SMS can be opened, false otherwise
  func sendSMS(completion: ((Bool) -> Void)? = nil) {
    guard let contact = trustedContact, contact.isValid else {
      completion?(false)
      return
    }

    let cleanedNumber = contact.phoneNumber
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")

    // URL encode the message
    let encodedMessage =
      contact.customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

    // Try SMS URL scheme
    if let smsURL = URL(string: "sms:\(cleanedNumber)&body=\(encodedMessage)") {
      if UIApplication.shared.canOpenURL(smsURL) {
        UIApplication.shared.open(smsURL) { success in
          completion?(success)
        }
        return
      }
    }

    // Fallback to alternative format
    if let smsURL = URL(string: "sms:\(cleanedNumber)?body=\(encodedMessage)") {
      if UIApplication.shared.canOpenURL(smsURL) {
        UIApplication.shared.open(smsURL) { success in
          completion?(success)
        }
        return
      }
    }

    completion?(false)
  }

  /// Call trusted contact
  func callContact(completion: ((Bool) -> Void)? = nil) {
    guard let contact = trustedContact, contact.isValid else {
      completion?(false)
      return
    }

    let cleanedNumber = contact.phoneNumber
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")

    if let phoneURL = URL(string: "tel://\(cleanedNumber)") {
      if UIApplication.shared.canOpenURL(phoneURL) {
        UIApplication.shared.open(phoneURL) { success in
          completion?(success)
        }
        return
      }
    }

    completion?(false)
  }

  // MARK: - Private Methods

  private func loadContact() {
    if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
      let contact = try? JSONDecoder().decode(TrustedContact.self, from: data)
    {
      trustedContact = contact
    }
  }
}
