//
//  CalmPromptView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct CalmPromptView: View {
  let prompts: [CalmPrompt] = [
    CalmPrompt(text: "You are safe."),
    CalmPrompt(text: "This feeling will pass."),
    CalmPrompt(text: "Breathe in… Breathe out…"),
    CalmPrompt(text: "You’re doing better than you think."),
    CalmPrompt(text: "You can't control what happens to you, only how you REACT to it."),
  ]

  var body: some View {
    Text(prompts.randomElement()?.text ?? "")
      .font(.title2)
      .padding()
  }
}
