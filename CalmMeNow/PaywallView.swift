import StoreKit
import SwiftUI

struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var revenueCatService = RevenueCatService.shared
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),
            Color(hex: "#D0BFFF"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all, edges: .top)
        .padding(.bottom, 20)

        ScrollView {
          VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
              Text("🧠")
                .font(.system(size: 80))

              Text("Unlock AI-Powered Calm")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

              Text("Get personalized support when you need it most")
                .font(.title3)
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Features
            VStack(spacing: 20) {
              FeatureRow(
                icon: "🎯",
                title: "Personalized Panic Plans",
                description: "AI-generated strategies tailored to your triggers and preferences"
              )

              FeatureRow(
                icon: "📊",
                title: "Smart Daily Check-ins",
                description: "Get intelligent insights and recommendations based on your mood"
              )

              FeatureRow(
                icon: "🤖",
                title: "AI Emergency Companion",
                description: "24/7 AI support for crisis moments with personalized guidance"
              )

              FeatureRow(
                icon: "🧘‍♀️",
                title: "Enhanced Breathing",
                description: "AI-optimized breathing patterns for maximum effectiveness"
              )
            }
            .padding(.horizontal, 20)

            // Pricing
            VStack(spacing: 16) {
              Text("Just $4.99/month")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(.label))

              Text("Cancel anytime • No commitment")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )

            // Action Buttons
            VStack(spacing: 16) {
              Button(action: purchaseSubscription) {
                HStack {
                  if revenueCatService.isLoading {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.8)
                  } else {
                    Text("🚀 Unlock AI Features")
                  }
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
              }
              .disabled(revenueCatService.isLoading)

              Button("Restore Purchases") {
                restorePurchases()
              }
              .font(.subheadline)
              .foregroundColor(.blue)
              .disabled(revenueCatService.isLoading)

              Button("Continue with Free Features") {
                dismiss()
              }
              .font(.subheadline)
              .foregroundColor(.blue)
            }
            .padding(.horizontal, 40)

            // Free features reminder
            VStack(spacing: 12) {
              Text("✨ Free features you can use right now:")
                .font(.headline)
                .foregroundColor(Color(.label))

              Text(
                "✅ Emergency Calm Button\n✅ Calming Games\n✅ Basic Breathing Exercises\n✅ Progress Tracking"
              )
              .font(.subheadline)
              .foregroundColor(Color(.label))
              .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
              RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 40)
          }
        }
        .padding(.bottom, 20)  // Reduced bottom padding
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            dismiss()
          }
          .foregroundColor(.blue)
          .fontWeight(.semibold)
        }
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
      .onReceive(revenueCatService.$isSubscribed) { isSubscribed in
        if isSubscribed {
          // Subscription successful - dismiss paywall
          dismiss()
        }
      }
    }
  }

  private func purchaseSubscription() {
    Task {
      do {
        let success = try await revenueCatService.purchaseSubscription()
        if success {
          print("✅ Paywall: Subscription purchased successfully")
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingError = true
        }
      }
    }
  }

  private func restorePurchases() {
    Task {
      do {
        let restored = try await revenueCatService.restorePurchases()
        if restored {
          print("✅ Paywall: Purchases restored successfully")
        } else {
          await MainActor.run {
            errorMessage = "No previous purchases found to restore"
            showingError = true
          }
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingError = true
        }
      }
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(spacing: 16) {
      Text(icon)
        .font(.title2)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(Color(.label))

        Text(description)
          .font(.subheadline)
          .foregroundColor(Color(.secondaryLabel))
          .lineLimit(2)
      }

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 15)
        .fill(Color(.systemBackground))
    )
  }
}

#Preview {
  PaywallView()
}
