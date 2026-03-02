import RevenueCat
import StoreKit
import SwiftUI

struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var revenueCatService = RevenueCatService.shared
  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var selectedPackageID: String = ""

  var body: some View {
    NavigationStack {
      ZStack {
        backgroundGradient
        ScrollView {
          VStack(spacing: 30) {
            headerSection
            featuresSection
            pricingSection
            actionButtonsSection
            legalSection
          }
          .padding(.horizontal, 20)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
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
          dismiss()
        }
      }
      .onAppear {
        revenueCatService.fetchPackages()
      }
      .onChange(of: revenueCatService.currentOffering) { offering in
        guard selectedPackageID.isEmpty else { return }
        // Default to yearly
        if let id = offering?.annual?.identifier {
          selectedPackageID = id
        }
      }
    }
  }

  private var backgroundGradient: some View {
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
  }

  private var headerSection: some View {
    VStack(spacing: 16) {
      Text("🧠")
        .font(.system(size: 80))

      Text("Unlock Personalized Calm")
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
  }

  private var featuresSection: some View {
    VStack(spacing: 20) {
      FeatureRow(
        icon: "📄",
        title: "Full Clinical PDF Report",
        description: "Multi-page doctor's report with trigger charts, severity history, time-of-day patterns & journal themes — shareable directly with your therapist"
      )

      FeatureRow(
        icon: "🎯",
        title: "Personalized Panic Plans",
        description: "AI-powered strategies tailored to your specific triggers, intensity patterns, and recovery history"
      )

      FeatureRow(
        icon: "📊",
        title: "Trigger Tracker Insights",
        description: "Full episode log, weekly trend charts, outcome-per-trigger analysis, and custom trigger categories"
      )

      FeatureRow(
        icon: "🧠",
        title: "AI Daily Check-in Coach",
        description: "Daily mood coaching with personalised recommendations and pattern insights powered by AI"
      )

      FeatureRow(
        icon: "💜",
        title: "AI Emergency Companion",
        description: "24/7 adaptive support for crisis moments with personalised guidance when you need it most"
      )
    }
  }

  private var pricingSection: some View {
    VStack(spacing: 12) {
      if let offering = revenueCatService.currentOffering {
        if let pkg = offering.weekly {
          PricingOptionRow(
            package: pkg,
            label: "Weekly",
            badge: nil,
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
        if let pkg = offering.monthly {
          PricingOptionRow(
            package: pkg,
            label: "Monthly",
            badge: nil,
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
        if let pkg = offering.annual {
          PricingOptionRow(
            package: pkg,
            label: "Yearly",
            badge: "7-Day Free Trial",
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
      }
      Text("Cancel anytime • No commitment")
        .font(.subheadline)
        .foregroundColor(Color(.secondaryLabel))
    }
  }

  private var actionButtonsSection: some View {
    VStack(spacing: 16) {
      Button(action: purchaseSubscription) {
        HStack {
          if revenueCatService.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(0.8)
          } else {
            HStack {
              Text("🙌")
                .font(.title2)
              Text(selectedPackageID == revenueCatService.currentOffering?.annual?.identifier ? "Try Free for 7 Days" : "Subscribe")
                .fontWeight(.semibold)
              Spacer()
              Text("→")
                .font(.title2)
                .fontWeight(.bold)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
      .disabled(revenueCatService.isLoading)

      Button(action: restorePurchases) {
        Text("Restore Purchases")
          .font(.subheadline)
          .foregroundColor(.blue)
      }
      .disabled(revenueCatService.isLoading)
    }
  }

  private var legalSection: some View {
    VStack(spacing: 8) {
      HStack(spacing: 20) {
        Button("Terms of Service") {
          if let url = URL(
            string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
          {
            UIApplication.shared.open(url)
          }
        }
        .font(.caption)
        .foregroundColor(.blue)

        Button("Privacy Policy") {
          if let url = URL(
            string:
              "https://destiny-fender-4ad.notion.site/CalmMeNow-Privacy-Policy-26777834762b80798c5ade6a83b6a88c"
          ) {
            UIApplication.shared.open(url)
          }
        }
        .font(.caption)
        .foregroundColor(.blue)
      }

      Text(
        "By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period."
      )
      .font(.caption2)
      .foregroundColor(Color(.secondaryLabel))
      .multilineTextAlignment(.center)
      .padding(.horizontal)
    }
    .padding(.bottom, 20)
  }

  private func purchaseSubscription() {
    guard let offering = revenueCatService.currentOffering,
      let pkg = offering.availablePackages.first(where: { $0.identifier == selectedPackageID })
        ?? offering.monthly
    else { return }

    Task {
      do {
        let result = try await Purchases.shared.purchase(package: pkg)
        if result.customerInfo.entitlements.active[Billing.entitlement] != nil {
          dismiss()
        } else if !result.userCancelled {
          await MainActor.run {
            errorMessage = "Purchase completed but entitlement not active"
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

  private func restorePurchases() {
    Task {
      do {
        let restored = try await revenueCatService.restorePurchases()
        if restored {
          dismiss()
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

struct PricingOptionRow: View {
  let package: Package
  let label: String
  let badge: String?
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack {
        // Selection indicator
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundColor(isSelected ? .blue : .gray)
          .font(.title3)

        VStack(alignment: .leading, spacing: 2) {
          Text(label)
            .font(.headline)
            .foregroundColor(.black)
          Text(package.storeProduct.localizedPriceString)
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.6))
        }

        Spacer()

        if let badge = badge {
          Text(badge)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badge == "Best Value" ? Color.green : Color.blue)
            .cornerRadius(8)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Text(icon)
        .font(.title2)
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.black)

        Text(description)
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.7))
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  PaywallView()
}
