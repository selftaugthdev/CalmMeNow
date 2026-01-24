//
//  CrisisResourcesView.swift
//  CalmMeNow
//
//  Crisis hotlines and mental health resources
//

import SwiftUI

struct CrisisResourcesView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var crisisService = CrisisResourceService.shared

  private var currentResources: CrisisResourceConfig {
    crisisService.getCrisisResources()
  }

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
              Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))

              Text("Crisis Resources")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("You are not alone. Help is available.")
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.7))
                .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Emergency Numbers Section
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: "Emergency Services", icon: "phone.fill.badge.checkmark")

              // Emergency Number
              CrisisResourceRow(
                icon: "phone.fill",
                iconColor: .red,
                title: "Emergency Services",
                subtitle: currentResources.emergencyNumber,
                description: "For immediate danger or medical emergency",
                action: {
                  callNumber(currentResources.emergencyNumber)
                }
              )

              // Crisis Hotline
              if currentResources.crisisHotline != currentResources.emergencyNumber {
                CrisisResourceRow(
                  icon: "heart.fill",
                  iconColor: .pink,
                  title: "Crisis Hotline",
                  subtitle: currentResources.crisisHotline,
                  description: "24/7 mental health crisis support",
                  action: {
                    callNumber(currentResources.crisisHotline)
                  }
                )
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
            )
            .padding(.horizontal, 20)

            // Local Resources Section
            if !currentResources.resources.isEmpty {
              VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Local Resources", icon: "map.fill")

                ForEach(currentResources.resources, id: \.number) { resource in
                  CrisisResourceRow(
                    icon: "phone.circle.fill",
                    iconColor: .blue,
                    title: resource.name,
                    subtitle: resource.number,
                    description: resource.description,
                    action: {
                      callNumber(resource.number)
                    }
                  )

                  if resource.number != currentResources.resources.last?.number {
                    Divider()
                      .background(Color.primary.opacity(0.1))
                  }
                }
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color.white.opacity(0.9))
              )
              .padding(.horizontal, 20)
            }

            // International Resources
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: "Find Help Worldwide", icon: "globe")

              Button(action: {
                openFindAHelpline()
              }) {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("FindAHelpline.com")
                      .font(.headline)
                      .foregroundColor(.primary)

                    Text("Find crisis support in your country")
                      .font(.caption)
                      .foregroundColor(.primary.opacity(0.6))
                  }

                  Spacer()

                  Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                )
              }
              .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
            )
            .padding(.horizontal, 20)

            // Disclaimer
            Text(
              "This app is not a substitute for professional mental health treatment. If you are in crisis, please reach out to a crisis line or emergency services immediately."
            )
            .font(.caption)
            .foregroundColor(.primary.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .padding(.vertical, 20)

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
    }
  }

  // MARK: - Helper Methods

  private func callNumber(_ number: String) {
    let cleanedNumber = number.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")

    if let url = URL(string: "tel://\(cleanedNumber)") {
      UIApplication.shared.open(url)
    }
  }

  private func openFindAHelpline() {
    let url = CrisisResourceService.shared.getFindAHelplineURL()
    UIApplication.shared.open(url)
  }
}

// MARK: - Section Header

struct SectionHeader: View {
  let title: String
  let icon: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(.blue)

      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)
    }
  }
}

// MARK: - Crisis Resource Row

struct CrisisResourceRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String
  let description: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        // Icon
        ZStack {
          Circle()
            .fill(iconColor.opacity(0.2))
            .frame(width: 50, height: 50)

          Image(systemName: icon)
            .font(.title2)
            .foregroundColor(iconColor)
        }

        // Content
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundColor(.primary)

          Text(subtitle)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.blue)

          Text(description)
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))
        }

        Spacer()

        // Call indicator
        Image(systemName: "phone.arrow.up.right")
          .font(.title3)
          .foregroundColor(.green)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  CrisisResourcesView()
}
