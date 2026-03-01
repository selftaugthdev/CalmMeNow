//
//  TrustedContactView.swift
//  CalmMeNow
//
//  Setup view for the Safe Person Card (free feature)
//

import SwiftUI

struct TrustedContactView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var contactService = TrustedContactService.shared

  @State private var editingContact: TrustedContact? = nil
  @State private var showingCrisisCard = false
  @State private var bystanderExpanded = false

  var body: some View {
    NavigationView {
      ZStack {
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
            header
            contactList
            addContactButton
            bystanderSection
            openCrisisCardButton
            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarHidden(true)
      .overlay(closeButton, alignment: .topTrailing)
    }
    .sheet(item: $editingContact) { contact in
      ContactEditSheet(contact: contact) { saved in
        contactService.addOrUpdate(saved)
        editingContact = nil
      } onCancel: {
        editingContact = nil
      }
    }
    .fullScreenCover(isPresented: $showingCrisisCard) {
      SafePersonCardView()
    }
  }

  // MARK: - Header

  private var header: some View {
    VStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.2))
          .frame(width: 80, height: 80)

        Image(systemName: "person.2.fill")
          .font(.system(size: 36))
          .foregroundColor(.blue)
      }

      Text("Safe Person Card")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.primary)

      Text("Add up to 3 trusted contacts to reach during difficult moments")
        .font(.subheadline)
        .foregroundColor(.primary.opacity(0.7))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
    .padding(.top, 60)
  }

  // MARK: - Contact List

  private var contactList: some View {
    VStack(spacing: 0) {
      if contactService.contacts.isEmpty {
        Text("No contacts added yet")
          .font(.subheadline)
          .foregroundColor(.primary.opacity(0.5))
          .padding(.vertical, 20)
          .frame(maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color.white.opacity(0.9))
          )
      } else {
        VStack(spacing: 0) {
          ForEach(Array(contactService.contacts.enumerated()), id: \.element.id) {
            index, contact in
            contactRow(contact: contact, isLast: index == contactService.contacts.count - 1)
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
        )
      }
    }
    .padding(.horizontal, 20)
  }

  private func contactRow(contact: TrustedContact, isLast: Bool) -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
          Text(contact.name)
            .font(.headline)
            .foregroundColor(.primary)

          Text(contact.phoneNumber)
            .font(.subheadline)
            .foregroundColor(.primary.opacity(0.6))
        }

        Spacer()

        // Edit
        Button(action: {
          HapticManager.shared.softImpact()
          editingContact = contact
        }) {
          Image(systemName: "pencil.circle.fill")
            .font(.title2)
            .foregroundColor(.blue)
        }

        // Delete
        Button(action: {
          HapticManager.shared.softImpact()
          withAnimation {
            contactService.removeContact(id: contact.id)
          }
        }) {
          Image(systemName: "trash.circle.fill")
            .font(.title2)
            .foregroundColor(.red.opacity(0.7))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)

      if !isLast {
        Divider().padding(.horizontal, 16)
      }
    }
  }

  // MARK: - Add Contact Button

  private var addContactButton: some View {
    Button(action: {
      HapticManager.shared.softImpact()
      editingContact = TrustedContact()
    }) {
      HStack(spacing: 8) {
        Image(systemName: "plus.circle.fill")
          .font(.title3)
        Text("Add a safe person")
          .font(.headline)
          .fontWeight(.semibold)
      }
      .foregroundColor(contactService.contacts.count >= 3 ? .gray : .white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 30)
          .fill(contactService.contacts.count >= 3 ? Color.gray.opacity(0.3) : Color.blue)
      )
      .shadow(
        color: contactService.contacts.count >= 3 ? .clear : .blue.opacity(0.3),
        radius: 8, x: 0, y: 4
      )
    }
    .disabled(contactService.contacts.count >= 3)
    .padding(.horizontal, 20)
  }

  // MARK: - Bystander Message Section

  private var bystanderSection: some View {
    VStack(spacing: 0) {
      // Toggle header
      Button(action: {
        HapticManager.shared.softImpact()
        withAnimation(.easeInOut(duration: 0.25)) {
          bystanderExpanded.toggle()
        }
      }) {
        HStack {
          Image(systemName: "person.2.wave.2.fill")
            .foregroundColor(.blue)

          Text("Bystander message")
            .font(.headline)
            .foregroundColor(.primary)

          Spacer()

          Image(systemName: bystanderExpanded ? "chevron.up" : "chevron.down")
            .font(.caption)
            .foregroundColor(.primary.opacity(0.5))
        }
        .padding(16)
      }

      if bystanderExpanded {
        VStack(alignment: .leading, spacing: 8) {
          Text("Shown when you tap 'Show to someone nearby' in the crisis card")
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))
            .padding(.horizontal, 16)

          TextEditor(text: Binding(
            get: { contactService.bystanderMessage },
            set: { contactService.saveBystander($0) }
          ))
          .frame(minHeight: 120)
          .padding(8)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
          .background(Color.white)
          .cornerRadius(8)
          .padding(.horizontal, 16)
          .padding(.bottom, 16)
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.9))
    )
    .padding(.horizontal, 20)
  }

  // MARK: - Open Crisis Card Button

  @ViewBuilder
  private var openCrisisCardButton: some View {
    if contactService.hasContacts() {
      Button(action: {
        HapticManager.shared.softImpact()
        showingCrisisCard = true
      }) {
        HStack(spacing: 8) {
          Text("🆘")
          Text("Open Crisis Card")
            .font(.headline)
            .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
          RoundedRectangle(cornerRadius: 30)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D1B2A"), Color(hex: "#1B2A3B")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
      }
      .padding(.horizontal, 20)
    }
  }

  // MARK: - Close Button

  private var closeButton: some View {
    Button(action: {
      presentationMode.wrappedValue.dismiss()
    }) {
      Image(systemName: "xmark.circle.fill")
        .font(.title2)
        .foregroundColor(.gray)
        .padding()
    }
    .padding(.top, 8)
  }
}

// MARK: - Contact Edit Sheet

struct ContactEditSheet: View {
  @State private var draft: TrustedContact
  let onSave: (TrustedContact) -> Void
  let onCancel: () -> Void

  init(contact: TrustedContact, onSave: @escaping (TrustedContact) -> Void, onCancel: @escaping () -> Void) {
    _draft = State(initialValue: contact)
    self.onSave = onSave
    self.onCancel = onCancel
  }

  var body: some View {
    NavigationView {
      Form {
        Section("Contact details") {
          TextField("Name", text: $draft.name)
          TextField("Phone number", text: $draft.phoneNumber)
            .keyboardType(.phonePad)
        }

        Section("Custom text message") {
          TextEditor(text: $draft.customMessage)
            .frame(minHeight: 100)
        }
      }
      .navigationTitle(draft.name.isEmpty ? "New contact" : draft.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { onCancel() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") { onSave(draft) }
            .disabled(!draft.isValid)
            .fontWeight(.semibold)
        }
      }
    }
  }
}

#Preview {
  TrustedContactView()
}
