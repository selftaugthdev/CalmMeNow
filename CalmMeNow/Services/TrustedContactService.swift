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

  @Published var contacts: [TrustedContact] = []
  @Published var bystanderMessage: String =
    "I'm having a panic/anxiety episode. I'm not in physical danger. Please stay calm and stay with me. I may need a moment to breathe."

  private let contactsKey = "trustedContacts"
  private let legacyContactKey = "trustedContact"
  private let bystanderKey = "bystanderMessage"

  private init() {
    loadContacts()
    loadBystanderMessage()
  }

  // MARK: - Public Methods

  func addOrUpdate(_ contact: TrustedContact) {
    if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
      contacts[index] = contact
    } else if contacts.count < 3 {
      contacts.append(contact)
    }
    saveContacts()
  }

  func removeContact(id: UUID) {
    contacts.removeAll { $0.id == id }
    saveContacts()
  }

  func saveBystander(_ message: String) {
    bystanderMessage = message
    UserDefaults.standard.set(message, forKey: bystanderKey)
  }

  func hasContacts() -> Bool {
    !contacts.isEmpty
  }

  // Kept for backwards compatibility
  func hasValidContact() -> Bool {
    hasContacts()
  }

  /// Send SMS to a specific contact
  func sendSMS(to contact: TrustedContact, completion: ((Bool) -> Void)? = nil) {
    guard contact.isValid else {
      completion?(false)
      return
    }

    let cleanedNumber = cleanPhoneNumber(contact.phoneNumber)
    let encodedMessage =
      contact.customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

    if let smsURL = URL(string: "sms:\(cleanedNumber)&body=\(encodedMessage)"),
      UIApplication.shared.canOpenURL(smsURL)
    {
      UIApplication.shared.open(smsURL) { success in completion?(success) }
      return
    }

    if let smsURL = URL(string: "sms:\(cleanedNumber)?body=\(encodedMessage)"),
      UIApplication.shared.canOpenURL(smsURL)
    {
      UIApplication.shared.open(smsURL) { success in completion?(success) }
      return
    }

    completion?(false)
  }

  /// Call a specific contact
  func callContact(_ contact: TrustedContact, completion: ((Bool) -> Void)? = nil) {
    guard contact.isValid else {
      completion?(false)
      return
    }

    let cleanedNumber = cleanPhoneNumber(contact.phoneNumber)

    if let phoneURL = URL(string: "tel://\(cleanedNumber)"),
      UIApplication.shared.canOpenURL(phoneURL)
    {
      UIApplication.shared.open(phoneURL) { success in completion?(success) }
      return
    }

    completion?(false)
  }

  // MARK: - Legacy single-contact methods (backwards compatibility with existing call sites)

  func sendSMS(completion: ((Bool) -> Void)? = nil) {
    guard let contact = contacts.first else {
      completion?(false)
      return
    }
    sendSMS(to: contact, completion: completion)
  }

  func callContact(completion: ((Bool) -> Void)? = nil) {
    guard let contact = contacts.first else {
      completion?(false)
      return
    }
    callContact(contact, completion: completion)
  }

  // MARK: - Private Methods

  private func loadContacts() {
    // Try new array key first
    if let data = UserDefaults.standard.data(forKey: contactsKey),
      let loaded = try? JSONDecoder().decode([TrustedContact].self, from: data)
    {
      contacts = loaded
      return
    }

    // Migrate from legacy single-contact key
    if let data = UserDefaults.standard.data(forKey: legacyContactKey),
      let contact = try? JSONDecoder().decode(TrustedContact.self, from: data)
    {
      contacts = [contact]
      saveContacts()
      UserDefaults.standard.removeObject(forKey: legacyContactKey)
    }
  }

  private func saveContacts() {
    if let encoded = try? JSONEncoder().encode(contacts) {
      UserDefaults.standard.set(encoded, forKey: contactsKey)
    }
  }

  private func loadBystanderMessage() {
    if let saved = UserDefaults.standard.string(forKey: bystanderKey) {
      bystanderMessage = saved
    }
  }

  private func cleanPhoneNumber(_ number: String) -> String {
    number
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")
  }
}
