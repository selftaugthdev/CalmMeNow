//
//  ContentView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Feeling overwhelmed?")
                .font(.title2)
                .padding(.bottom, 20)

            Button(action: {
                AudioManager.shared.playRandomSound()
            }) {
                Text("🧘 Calm Me Now")
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}
