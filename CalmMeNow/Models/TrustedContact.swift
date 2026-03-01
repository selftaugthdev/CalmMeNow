//
//  TrustedContact.swift
//  CalmMeNow
//
//  Model for trusted contact feature
//

import Foundation

struct TrustedContact: Codable, Equatable, Identifiable {
  var id: UUID
  var name: String
  var phoneNumber: String
  var customMessage: String

  init(
    id: UUID = UUID(),
    name: String = "",
    phoneNumber: String = "",
    customMessage: String = "I'm having a difficult moment and could use some support. You don't need to fix anything - just knowing you're there helps."
  ) {
    self.id = id
    self.name = name
    self.phoneNumber = phoneNumber
    self.customMessage = customMessage
  }

  var isValid: Bool {
    !name.isEmpty && !phoneNumber.isEmpty
  }
}
