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
    weeklyTrialLabel: "7-Day Trial",
    weeklyNoTrialLabel: "Monthly Plan",
    trialToggleDefault: true,
    termsURL: URL(string: "https://calmmenow.app/terms"),
    privacyURL: URL(string: "https://calmmenow.app/privacy"),
    features: [
      PaywallConfig.Feature(
        icon: "target",
        title: "Personalized Panic Plans",
        description: "AI-generated strategies tailored to your triggers and preferences"
      ),
      PaywallConfig.Feature(
        icon: "chart.bar",
        title: "Smart Daily Check-ins",
        description: "Get intelligent insights and recommendations based on your mood"
      ),
      PaywallConfig.Feature(
        icon: "brain.head.profile",
        title: "AI Emergency Companion",
        description: "24/7 AI support for crisis moments with personalized guidance"
      ),
      PaywallConfig.Feature(
        icon: "lungs",
        title: "Enhanced Breathing",
        description: "AI-optimized breathing patterns for maximum effectiveness"
      ),
    ]
  )

  var body: some View {
    PurchaseView(
      manager: revenueCatService,
      config: paywallConfig,
      onPurchaseComplete: {
        // Handle successful purchase
        print("✅ PaywallKit: Purchase completed successfully")
        dismiss()
      }
    )
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
    .onAppear {
      // Fetch packages when paywall appears
      revenueCatService.fetchPackages()
    }
  }
}

#Preview {
  PaywallKitView()
}
