import SwiftUI
import AppFactoryKit

// Photo Restore — payments via native StoreKit 2 (no third-party SDK).
private enum Product {
    static let yearly = "restore_pro_yearly"
    static let weekly = "restore_pro_weekly"
}

@MainActor
enum PhotoRestoreFactory {
    static func make() -> AppFactory {
        let config = AppFactoryConfiguration(
            appName: "Photo Restore",
            purchaseProvider: StoreKit2PurchaseProvider(productIDs: [Product.yearly, Product.weekly]),
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "photo.badge.arrow.down",
                          title: "Bring Old Photos Back",
                          message: "Repair faded, soft and noisy photos — restored entirely on your device."),
                    .init(systemImage: "hand.tap",
                          title: "Compare Instantly",
                          message: "Press and hold any result to see the original side by side.")
                ],
                presentsPaywallOnFinish: true,
                accent: .purple
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Photo Restore Pro",
                subheadline: "Every memory deserves a second life.",
                benefits: [
                    .init(systemImage: "paintpalette", title: "Colorize old photos"),
                    .init(systemImage: "square.and.arrow.down", title: "Save full-resolution results"),
                    .init(systemImage: "infinity", title: "Unlimited restorations"),
                    .init(systemImage: "nosign", title: "No ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/OldPhotoRestoration/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/OldPhotoRestoration/privacy.html"),
                style: PaywallStyle(accent: .purple, heroSystemImage: "photo.badge.arrow.down")
            )
        )
        return AppFactory(config)
    }
}

@main
struct PhotoRestoreApp: App {
    @StateObject private var factory = PhotoRestoreFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.purple)
        }
    }
}
