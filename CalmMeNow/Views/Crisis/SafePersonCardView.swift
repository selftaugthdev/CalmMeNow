//
//  SafePersonCardView.swift
//  CalmMeNow
//
//  Full-screen crisis card with contact buttons and bystander mode
//

import SwiftUI

struct SafePersonCardView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var contactService = TrustedContactService.shared

  @State private var bystanderMode = false

  private let navyGradient = LinearGradient(
    gradient: Gradient(colors: [
      Color(hex: "#0D1B2A"),
      Color(hex: "#1B2A3B"),
    ]),
    startPoint: .top,
    endPoint: .bottom
  )

  var body: some View {
    ZStack {
      navyGradient.ignoresSafeArea()

      if bystanderMode {
        bystanderContent
          .transition(.opacity.combined(with: .move(edge: .trailing)))
      } else {
        crisisContent
          .transition(.opacity.combined(with: .move(edge: .leading)))
      }

      // Dismiss button on top so the ScrollView doesn't swallow taps
      VStack {
        HStack {
          Spacer()
          Button(action: {
            HapticManager.shared.softImpact()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.white.opacity(0.6))
              .padding()
          }
        }
        Spacer()
      }
    }
  }

  // MARK: - Crisis Mode

  private var crisisContent: some View {
    ScrollView {
      VStack(spacing: 32) {
        Spacer(minLength: 60)

        // Header
        VStack(spacing: 12) {
          Text("❤️")
            .font(.system(size: 60))

          Text("You are not alone.")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          Text("Your safe people are here.")
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
        }

        // Divider
        Rectangle()
          .fill(Color.white.opacity(0.15))
          .frame(height: 1)
          .padding(.horizontal, 40)

        // Contact cards
        VStack(spacing: 16) {
          ForEach(contactService.contacts) { contact in
            contactCard(for: contact)
          }
        }
        .padding(.horizontal, 24)

        // Divider
        Rectangle()
          .fill(Color.white.opacity(0.15))
          .frame(height: 1)
          .padding(.horizontal, 40)

        // Bystander mode button
        Button(action: {
          HapticManager.shared.softImpact()
          withAnimation(.easeInOut(duration: 0.4)) {
            bystanderMode = true
          }
        }) {
          HStack(spacing: 10) {
            Text("👥")
            Text("Show to someone nearby")
              .font(.system(size: 17, weight: .medium, design: .rounded))
          }
          .foregroundColor(.white.opacity(0.85))
          .padding(.vertical, 14)
          .padding(.horizontal, 28)
          .overlay(
            RoundedRectangle(cornerRadius: 30)
              .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
          )
        }

        Spacer(minLength: 40)
      }
    }
  }

  private func contactCard(for contact: TrustedContact) -> some View {
    VStack(spacing: 14) {
      Text(contact.name)
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: 12) {
        // Call button
        Button(action: {
          HapticManager.shared.softImpact()
          TrustedContactService.shared.callContact(contact)
        }) {
          HStack(spacing: 6) {
            Text("📞")
            Text("Call")
              .font(.system(size: 16, weight: .semibold, design: .rounded))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 13)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.white.opacity(0.2))
          )
        }

        // Text button
        Button(action: {
          HapticManager.shared.softImpact()
          TrustedContactService.shared.sendSMS(to: contact)
        }) {
          HStack(spacing: 6) {
            Text("💬")
            Text("Text")
              .font(.system(size: 16, weight: .semibold, design: .rounded))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 13)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.white.opacity(0.2))
          )
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.1))
    )
  }

  // MARK: - Bystander Mode

  private var bystanderContent: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 80)

      // Icon + caption
      VStack(spacing: 12) {
        Text("👥")
          .font(.system(size: 60))

        Text("SHOW THIS TO THE PERSON WITH YOU")
          .font(.system(size: 13, weight: .semibold, design: .rounded))
          .foregroundColor(.white.opacity(0.6))
          .tracking(1.5)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }

      // Divider
      Rectangle()
        .fill(Color.white.opacity(0.15))
        .frame(height: 1)
        .padding(.horizontal, 40)
        .padding(.vertical, 28)

      // Message
      Text(contactService.bystanderMessage)
        .font(.system(size: 22, weight: .regular, design: .rounded))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .lineSpacing(6)
        .padding(.horizontal, 36)

      // Divider
      Rectangle()
        .fill(Color.white.opacity(0.15))
        .frame(height: 1)
        .padding(.horizontal, 40)
        .padding(.vertical, 28)

      Spacer()

      // Back button
      Button(action: {
        HapticManager.shared.softImpact()
        withAnimation(.easeInOut(duration: 0.4)) {
          bystanderMode = false
        }
      }) {
        HStack(spacing: 8) {
          Image(systemName: "chevron.left")
          Text("Back")
            .font(.system(size: 17, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.vertical, 14)
        .padding(.horizontal, 28)
        .overlay(
          RoundedRectangle(cornerRadius: 30)
            .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
        )
      }
      .padding(.bottom, 60)
    }
  }
}

#Preview {
  SafePersonCardView()
}
