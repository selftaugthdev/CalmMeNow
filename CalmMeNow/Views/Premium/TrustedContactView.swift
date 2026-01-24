//
//  TrustedContactView.swift
//  CalmMeNow
//
//  Setup and use trusted contact feature (Premium)
//

import SwiftUI

struct TrustedContactView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var contactService = TrustedContactService.shared
  @StateObject private var paywallManager = PaywallManager.shared

  @State private var editedContact = TrustedContact()
  @State private var isEditing = false
  @State private var showingSaveSuccess = false
  @State private var showingSendConfirmation = false

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),
            Color(hex: "#98D8C8"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
              ZStack {
                Circle()
                  .fill(Color.blue.opacity(0.2))
                  .frame(width: 80, height: 80)

                Image(systemName: "person.crop.circle.badge.checkmark")
                  .font(.system(size: 40))
                  .foregroundColor(.blue)
              }

              Text("Trusted Contact")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Set up a contact who can support you during difficult moments")
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            .padding(.top, 20)

            // Contact display or edit form
            if contactService.hasValidContact() && !isEditing {
              contactDisplayView
            } else {
              contactEditForm
            }

            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarHidden(true)
      .overlay(
        // Close button
        VStack {
          HStack {
            Spacer()
            Button(action: {
              presentationMode.wrappedValue.dismiss()
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            }
          }
          Spacer()
        }
      )
      .alert("Message Sent", isPresented: $showingSaveSuccess) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Your contact has been saved successfully.")
      }
      .confirmationDialog(
        "Contact \(editedContact.name)",
        isPresented: $showingSendConfirmation,
        titleVisibility: .visible
      ) {
        Button("Send Text Message") {
          contactService.sendSMS()
        }
        Button("Call") {
          contactService.callContact()
        }
        Button("Cancel", role: .cancel) {}
      }
      .onAppear {
        checkPremiumAccess()
      }
    }
  }

  // MARK: - Contact Display View

  private var contactDisplayView: some View {
    VStack(spacing: 20) {
      // Contact Card
      VStack(spacing: 16) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(contactService.trustedContact?.name ?? "")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text(contactService.trustedContact?.phoneNumber ?? "")
              .font(.body)
              .foregroundColor(.primary.opacity(0.7))
          }

          Spacer()

          Button(action: {
            if let contact = contactService.trustedContact {
              editedContact = contact
            }
            isEditing = true
          }) {
            Image(systemName: "pencil.circle.fill")
              .font(.title2)
              .foregroundColor(.blue)
          }
        }

        Divider()

        // Message Preview
        VStack(alignment: .leading, spacing: 8) {
          Text("Message:")
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))

          Text(contactService.trustedContact?.customMessage ?? "")
            .font(.body)
            .foregroundColor(.primary.opacity(0.8))
            .lineLimit(3)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.white.opacity(0.9))
      )
      .padding(.horizontal, 20)

      // Action Buttons
      VStack(spacing: 12) {
        // Send Message Button
        Button(action: {
          showingSendConfirmation = true
        }) {
          HStack {
            Image(systemName: "message.fill")
            Text("Reach Out Now")
          }
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.blue)
          )
          .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }

        // Delete Contact Button
        Button(action: {
          contactService.deleteContact()
          editedContact = TrustedContact()
        }) {
          Text("Remove Contact")
            .font(.subheadline)
            .foregroundColor(.red.opacity(0.8))
        }
      }
      .padding(.horizontal, 20)
    }
  }

  // MARK: - Contact Edit Form

  private var contactEditForm: some View {
    VStack(spacing: 20) {
      VStack(spacing: 16) {
        // Name Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Contact Name")
            .font(.headline)
            .foregroundColor(.primary)

          TextField("Enter name", text: $editedContact.name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.body)
        }

        // Phone Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Phone Number")
            .font(.headline)
            .foregroundColor(.primary)

          TextField("Enter phone number", text: $editedContact.phoneNumber)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.body)
            .keyboardType(.phonePad)
        }

        // Message Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Message to Send")
            .font(.headline)
            .foregroundColor(.primary)

          Text("This message will be pre-filled when you reach out")
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))

          TextEditor(text: $editedContact.customMessage)
            .frame(minHeight: 100)
            .padding(8)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .background(Color.white)
            .cornerRadius(8)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.white.opacity(0.9))
      )
      .padding(.horizontal, 20)

      // Save Button
      Button(action: {
        saveContact()
      }) {
        Text("Save Contact")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(editedContact.isValid ? Color.blue : Color.gray)
          )
          .shadow(
            color: editedContact.isValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
      }
      .disabled(!editedContact.isValid)
      .padding(.horizontal, 20)

      // Cancel button if editing
      if contactService.hasValidContact() {
        Button(action: {
          isEditing = false
        }) {
          Text("Cancel")
            .font(.subheadline)
            .foregroundColor(.primary.opacity(0.6))
        }
      }
    }
  }

  // MARK: - Helper Methods

  private func checkPremiumAccess() {
    Task {
      let hasAccess = await paywallManager.requestAIAccess()
      if !hasAccess {
        // User doesn't have premium - will be shown paywall automatically
        // Dismiss this view if they don't subscribe
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          if !paywallManager.shouldShowPaywall {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }

  private func saveContact() {
    contactService.saveContact(editedContact)
    isEditing = false
    showingSaveSuccess = true
  }
}

#Preview {
  TrustedContactView()
}
