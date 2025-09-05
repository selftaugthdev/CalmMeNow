//
//  CalmPrompt.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

public struct CalmPrompt: Identifiable, Codable {
  public let id = UUID()
  public let text: String

  public init(text: String) {
    self.text = text
  }
}
