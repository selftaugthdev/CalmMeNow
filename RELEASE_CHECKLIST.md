# 🚀 CalmMeNow Release Checklist

Generated: $(date)  
For: TestFlight/App Store submission

---

## 📋 Auto Findings

### ✅ Debug Prints & Logs

**Status: FIXED** - Wrapped verbose debug logs in `#if DEBUG` guards:

- ✅ **RevenueCatService.swift**: 20+ print statements now debug-only
- ✅ **FirebaseAnalyticsService.swift**: Analytics logging now debug-only
- ✅ **AudioManager.swift**: Audio debug logs now debug-only
- ✅ **TailoredExperienceView.swift**: Debug timing logs now debug-only
- ✅ **CalmMeNowApp.swift**: Configuration logs now debug-only

### ✅ TODO/FIXME Comments

**Status: SAFE** - Found 4 TODO comments:

- `OnboardingView.swift:196` - TODO: Add safety resources view (cosmetic)
- `DailyCoachView.swift:270,405` - TODO: Exercise timer features (not critical)
- `PhoneWCSessionHandler.swift:46` - TODO: Audio filename (functional, not blocking)

### ⚠️ Hardcoded Secrets/Keys

**Status: REVIEWED** - Found legitimate configuration:

- ✅ **CalmMeNowApp.swift:75** - RevenueCat public key `appl_xeIUzCLEhVImrKmBAgvcITeDxFn` (VALID)
- ✅ **OpenAI keys** - Properly environment-based with fallback placeholders
- ⚠️ **functions/src/index.ts** - Uses Firebase secrets (SECURE)

### ✅ RevenueCat Configuration

**Status: FIXED** - Release-ready configuration:

- ✅ Log level now conditional: `DEBUG = .debug`, `RELEASE = .warn`
- ✅ Single configure call with correct public key
- ✅ Product targeting monthly package (`offering.monthly`)
- ⚠️ **MISSING**: No `CalmMeNow001` product ID found in code (see Manual Actions)

### ✅ Firebase Configuration

**Status: FIXED** - Conditional providers:

- ✅ Debug builds: `AppCheckDebugProviderFactory()`
- ✅ Release builds: `DeviceCheckProviderFactory()`
- ✅ Analytics debug flag disabled in scheme for Release

### ✅ StoreKit Configuration

**Status: SAFE** - No `.storekit` files found

- ✅ No StoreKit test configuration detected
- ✅ Scheme properly configured for Release builds

### ✅ Build Settings

**Status: GOOD** - Deployment and optimization:

- ✅ Deployment Target: iOS 17.6+ (current)
- ✅ Swift Compilation Mode: `wholemodule` for Release
- ✅ Dead Code Stripping: Enabled
- ✅ Debug info proper for Release builds

### ⚠️ Test/Dev Endpoints

**Status: REVIEWED** - Found development references:

- ✅ Firebase functions region: `europe-west1` (PRODUCTION)
- ✅ TestFlight detection: `sandboxReceipt` check (VALID)
- ✅ No localhost/dev/staging endpoints found

---

## 🔧 Auto Fixes Applied

- ✅ **Debug Logs**: Wrapped 25+ verbose print statements in `#if DEBUG` guards
- ✅ **RevenueCat**: Log level now `.warn` for Release, `.debug` for Debug
- ✅ **Firebase App Check**: Conditional providers (Debug vs DeviceCheck)
- ✅ **Firebase Analytics**: Debug flag disabled for Release builds in scheme
- ✅ **Debug UI**: All debug buttons/views properly wrapped in `#if DEBUG`

---

## 📋 Manual Actions Required

### 🔴 Critical (Before Release)

- [ ] **Firebase Console**: Set App Check Enforcement to **ON** for Relaxing Calm production

  - Go to Firebase Console → App Check → Apps → Relaxing Calm
  - Change enforcement from "Debug mode" to "Enforce"
  - ⚠️ Only do this after verifying devices work with DeviceCheck

- [ ] **RevenueCat Dashboard**: Verify offering configuration

  - Ensure offering named "monthly" is set as **Current**
  - Verify package `$rc_monthly` maps to product `CalmMeNow001`
  - Check that `premium` entitlement is properly configured

- [ ] **App Store Connect**: Verify subscription product
  - Confirm `CalmMeNow001` ($4.99/month) exists and is "Ready for Sale"
  - Verify 7-day free trial intro offer is configured
  - Check subscription group settings

### 🟡 Testing Required

- [ ] **Real Device Testing**: Test on physical device with production API keys

  - Purchase flow with sandbox Apple ID
  - Restore purchases functionality
  - App Check DeviceCheck provider validation
  - Revenue Cat subscription status sync

- [ ] **Analytics Verification**: Confirm production analytics collection

  - Firebase Analytics events logging
  - RevenueCat subscription events
  - No debug-only events in production

- [ ] **Emergency Functions**: Test AI-powered emergency features
  - Panic plan generation via Firebase Functions
  - Daily check-in AI analysis
  - Function region `europe-west1` accessibility

### 🔵 Before App Store Submission

- [ ] **Privacy Nutrition Labels**: Update in App Store Connect

  - Analytics data collection (Firebase)
  - Subscription data (RevenueCat)
  - User content (Journal entries - local only)
  - Contact info (Anonymous Firebase UID only)

- [ ] **Version Management**:

  - [ ] Bump `MARKETING_VERSION` in project settings
  - [ ] Increment `CURRENT_PROJECT_VERSION` (build number)
  - [ ] Archive with latest Xcode release version

- [ ] **Final Verification**:
  - [ ] No test endpoints or debug tokens enabled
  - [ ] Firebase App Check enforcement ON
  - [ ] RevenueCat offering points to correct product
  - [ ] Clean Archive build succeeds
  - [ ] Upload to App Store Connect successful

---

## 🔍 Current Configuration Summary

**Bundle ID**: `com.thierrydb.CalmMeNow`  
**Display Name**: `Relaxing Calm`  
**Deployment Target**: iOS 17.6+  
**RevenueCat**: `appl_xeIUzCLEhVImrKmBAgvcITeDxFn`  
**Firebase Region**: `europe-west1`  
**Entitlement**: `premium`

**Swift Packages**:

- RevenueCat 5.37.0 ✅
- Firebase 12.2.0 ✅
- PaywallKit 0.1.5 ✅
- Lottie 4.5.2 ✅

---

## 🚨 Known Issues

1. **Product ID Mismatch**: Code references `offering.monthly` but manual mentions `CalmMeNow001`

   - **Impact**: Purchase flow may fail if offering/product mapping incorrect
   - **Fix**: Verify RevenueCat dashboard product mapping

2. **Firebase App Check**: Currently in debug mode

   - **Impact**: Relaxed security for Firebase functions
   - **Fix**: Enable enforcement after device validation

3. **No Privacy Manifest**: Missing `.xcprivacy` files for 3rd-party SDKs
   - **Impact**: App Store may require privacy declarations
   - **Fix**: Check if RevenueCat/Firebase provide privacy manifests

---

**Generated by iOS Release Engineer**  
_Last updated: $(date)_
