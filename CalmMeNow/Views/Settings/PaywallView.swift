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
    .ignoresSafeArea()
  }

  private var headerSection: some View {
    VStack(spacing: 16) {
      Text("💙")
        .font(.system(size: 80))

      Text("Stop panic attacks faster.")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)

      Text("Personalized support that meets you\nright when it hits.")
        .font(.title3)
        .foregroundColor(.black.opacity(0.7))
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }

  private var featuresSection: some View {
    VStack(spacing: 20) {
      FeatureRow(
        icon: "💙",
        title: "Never face it alone",
        description: "Adaptive support that kicks in the moment panic hits — every time, no matter when."
      )

      FeatureRow(
        icon: "🎯",
        title: "A plan that adapts when you struggle",
        description: "Not a generic routine. Your triggers, your patterns, your personalised recovery path."
      )

      FeatureRow(
        icon: "📊",
        title: "Understand why this keeps happening",
        description: "See exactly what sets you off, how often it's improving, and what actually helps."
      )

      FeatureRow(
        icon: "📅",
        title: "Know exactly what to do today",
        description: "Daily support tailored to how you're actually feeling — not how you should be feeling."
      )

      FeatureRow(
        icon: "📈",
        title: "See your progress, even when it doesn't feel like it",
        description: "Weekly summaries and mood trends that show how far you've really come."
      )
    }
  }

  private var pricingSection: some View {
    VStack(spacing: 12) {
      // No payment due now
      HStack(spacing: 6) {
        Image(systemName: "checkmark")
          .font(.caption.weight(.bold))
          .foregroundColor(.green)
        Text("No payment due now")
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.7))
      }

      if let offering = revenueCatService.currentOffering {
        // Annual first — highlighted
        if let pkg = offering.annual {
          PricingOptionRow(
            package: pkg,
            label: "Annual Plan",
            weeklyBreakdown: weeklyPrice(for: pkg),
            trialText: "7-day\nfree trial",
            badgeText: "Limited Time: Best Value",
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
        if let pkg = offering.monthly {
          PricingOptionRow(
            package: pkg,
            label: "Monthly Plan",
            weeklyBreakdown: nil,
            trialText: "No free\ntrial",
            badgeText: nil,
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
        if let pkg = offering.weekly {
          PricingOptionRow(
            package: pkg,
            label: "Weekly Plan",
            weeklyBreakdown: nil,
            trialText: "No free\ntrial",
            badgeText: nil,
            isSelected: selectedPackageID == pkg.identifier,
            onSelect: { selectedPackageID = pkg.identifier }
          )
        }
      }
      Text("Start free. Cancel anytime.")
        .font(.subheadline)
        .foregroundColor(Color(.secondaryLabel))
    }
  }

  private func weeklyPrice(for package: Package) -> String? {
    let weekly = package.storeProduct.price / 52
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = package.storeProduct.currencyCode
    formatter.maximumFractionDigits = 2
    guard let formatted = formatter.string(from: weekly as NSDecimalNumber) else { return nil }
    return "\(formatted)/week"
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
            HStack(spacing: 8) {
              Spacer()
              Text("🙌")
                .font(.title2)
              Text(selectedPackageID == revenueCatService.currentOffering?.annual?.identifier ? "Start My 7-Day Free Trial" : "Subscribe Now")
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
  let weeklyBreakdown: String?
  let trialText: String
  let badgeText: String?
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      ZStack(alignment: .top) {
        // Card
        HStack(alignment: .center, spacing: 12) {
          VStack(alignment: .leading, spacing: 3) {
            Text(label)
              .font(.headline)
              .foregroundColor(isSelected ? Color(hex: "#3A6ED4") : .black)

            HStack(spacing: 4) {
              Text(package.storeProduct.localizedPriceString)
                .font(.subheadline)
                .foregroundColor(isSelected ? Color(hex: "#3A6ED4") : .black.opacity(0.6))
              if let breakdown = weeklyBreakdown {
                Text("(\(breakdown))")
                  .font(.subheadline)
                  .foregroundColor(isSelected ? Color(hex: "#3A6ED4").opacity(0.7) : .black.opacity(0.45))
              }
            }
          }

          Spacer()

          Text(trialText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? Color(hex: "#3A6ED4") : .black.opacity(0.45))
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .padding(.top, badgeText != nil ? 10 : 0)
        .background(
          RoundedRectangle(cornerRadius: 14)
            .fill(isSelected ? Color.white : Color.white.opacity(0.6))
            .overlay(
              RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color(hex: "#3A6ED4") : Color.gray.opacity(0.25), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(hex: "#3A6ED4").opacity(0.15) : .clear, radius: 8, x: 0, y: 3)
        )

        // Badge overlay at top center
        if let badge = badgeText {
          Text(badge)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
              Capsule()
                .fill(
                  LinearGradient(
                    colors: [Color(hex: "#5B8FCC"), Color(hex: "#9B5FC0")],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
            )
            .offset(y: -10)
        }
      }
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
