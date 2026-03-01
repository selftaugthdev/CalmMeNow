import PaywallKit
import RevenueCat
import SwiftUI

struct PaywallKitView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var revenueCatService = RevenueCatService.shared

  // PaywallKit configuration
  private let paywallConfig = PaywallConfig(
    title: "Unlock Personalized Calm",
    subtitle: "Tools that genuinely help you understand and manage your anxiety",
    yearlyBadgeText: "SAVE 90%",
    weeklyTrialLabel: "7-Day Free Trial",
    weeklyNoTrialLabel: "Weekly Plan",
    trialToggleDefault: true,
    termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
    privacyURL: URL(
      string:
        "https://destiny-fender-4ad.notion.site/CalmMeNow-Privacy-Policy-26777834762b80798c5ade6a83b6a88c"
    ),
    features: [
      PaywallConfig.Feature(
        icon: "doc.richtext",
        title: "Full Clinical PDF Report",
        description: "Multi-page doctor's report with trigger charts, severity history & journal themes — shareable with your therapist"
      ),
      PaywallConfig.Feature(
        icon: "target",
        title: "Personalized Panic Plans",
        description: "AI strategies tailored to your triggers, intensity patterns, and recovery history"
      ),
      PaywallConfig.Feature(
        icon: "brain.head.profile",
        title: "AI Daily Check-in Coach",
        description: "Daily mood coaching, pattern insights, and a 24/7 companion for crisis moments"
      ),
    ]
  )

  var body: some View {
    PurchaseView(
      manager: revenueCatService,
      config: paywallConfig
    ) {
      // Delay dismissal to allow our custom congratulations screen to show
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        dismiss()
      }
    }
  }
}

#Preview {
  PaywallKitView()
}
