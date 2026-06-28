# OldPhotoRestoration

Generated from niche `old-photo-restore` (AI Image, tier S, score 86).

**Utility:** Repair, deblur and colorize old/damaged photos
**Primary ASO keyword:** `restore old photos`
**Also target:** `photo restoration`, `fix old photo`, `colorize photo`, `unblur`
**Paywall hook:** Unlimited restores, 4K export, batch

> Emotional hook (family photos) = high conversion. Older demographic pays.

## Build it

```bash
brew install xcodegen        # once
cd OldPhotoRestoration
xcodegen generate
open OldPhotoRestoration.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `old-photo-restore_yearly` and `old-photo-restore_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.oldphotorestore`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
