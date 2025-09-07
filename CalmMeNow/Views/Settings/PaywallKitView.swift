import PaywallKit
import RevenueCat
import SwiftUI

struct PaywallKitView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var revenueCatService = RevenueCatService.shared

  // PaywallKit configuration
  private let paywallConfig = PaywallConfig(
    title: "Unlock AI-Powered Calm",
    subtitle: "Get personalized support when you need it most",
    yearlyBadgeText: "SAVE 90%",
    weeklyTrialLabel: "7-Day Free Trial",
    weeklyNoTrialLabel: "Monthly Plan",
    trialToggleDefault: true,
    termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
    privacyURL: URL(
      string:
        "https://destiny-fender-4ad.notion.site/CalmMeNow-Privacy-Policy-26777834762b80798c5ade6a83b6a88c"
    ),
    features: [
      PaywallConfig.Feature(
        icon: "target",
        title: "Personalized Panic Plans",
        description: "AI-generated strategies tailored to your triggers and preferences"
      ),
      PaywallConfig.Feature(
        icon: "brain.head.profile",
        title: "AI Companion",
        description: "24/7 emotional support and guidance when you need it most"
      ),
      PaywallConfig.Feature(
        icon: "heart.fill",
        title: "Unlimited Access",
        description: "All premium features, breathing exercises, and emergency tools"
      ),
    ]
  )

  var body: some View {
    PurchaseView(
      manager: revenueCatService,
      config: paywallConfig
    ) {
      dismiss()
    }
  }
}

#Preview {
  PaywallKitView()
}
