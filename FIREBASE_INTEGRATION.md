# Firebase Cloud Functions Integration Guide

## Overview

This guide explains how to integrate Firebase Cloud Functions with your CalmMeNow iOS app for AI-powered personalized panic plans and daily check-ins.

## What's Been Added

### 1. Core Service (`AIService.swift`)

- Handles Firebase Cloud Function calls
- Manages authentication (anonymous sign-in)
- Provides methods for generating panic plans and daily check-ins

### 2. Data Models

- `PanicPlan.swift` - Structures the response from panic plan generation
- `DailyCheckInResponse.swift` - Structures daily check-in responses

### 3. View Models

- `AIServiceViewModel.swift` - SwiftUI integration layer
- Handles loading states, error handling, and local storage

### 4. SwiftUI Views

- `PersonalizedPanicPlanGeneratorView.swift` - AI-powered panic plan creation
- `DailyCheckInView.swift` - Intelligent daily check-in with AI feedback

## Required Firebase Packages

You need to add these packages to your Xcode project:

### Swift Package Manager

1. In Xcode, go to File → Add Package Dependencies
2. Add these Firebase packages:
   - `https://github.com/firebase/firebase-ios-sdk`
   - Select these products:
     - FirebaseAuth
     - FirebaseFunctions
     - FirebaseAppCheck (optional, for security)

### CocoaPods Alternative

If you prefer CocoaPods, add to your `Podfile`:

```ruby
pod 'FirebaseAuth'
pod 'FirebaseFunctions'
pod 'FirebaseAppCheck' # optional
```

## Configuration

### 1. Firebase Setup

Your app already has Firebase configured in `CalmMeNowApp.swift` with:

```swift
FirebaseApp.configure()
```

### 2. Region Configuration

The AI service is configured for `europe-west1`. Update this in `AIService.swift` if your functions are deployed elsewhere:

```swift
private lazy var functions = Functions.functions(region: "europe-west1")
```

### 3. Cloud Functions

Ensure your Firebase project has these functions deployed:

- `generatePanicPlan` - Creates personalized panic plans
- `dailyCheckIn` - Processes daily check-ins and provides feedback

## Usage Examples

### Generate a Panic Plan

```swift
let service = AIService()

let intake: [String: Any] = [
    "triggers": ["crowded places"],
    "symptoms": ["racing heart", "dizzy"],
    "preferences": ["breathing", "grounding"],
    "duration": 120,
    "phrase": "This will pass; I'm safe."
]

let plan = try await service.generatePanicPlan(intake: intake)
```

### Submit Daily Check-in

```swift
let checkin: [String: Any] = [
    "mood": 3,
    "tags": ["poor-sleep", "work-stress"],
    "note": "Heart feels jumpy before meetings."
]

let response = try await service.dailyCheckIn(checkin: checkin)
```

## Integration Points

### 1. ContentView

- Panic Plan card now opens `PersonalizedPanicPlanGeneratorView`
- Daily Coach opens `DailyCoachView` which uses AI-powered check-ins

### 2. Navigation Flow

- Home → Panic Plan → AI-generated personalized plan
- Home → Daily Coach → AI-powered daily check-in → Personalized feedback

## Error Handling

The service includes comprehensive error handling:

- Network errors
- Authentication failures
- Invalid responses
- User-friendly error messages

## Local Storage

Generated plans are stored locally using UserDefaults for offline access:

- Panic plans persist between app sessions
- Check-in responses are cached for reference

## Security

- Anonymous authentication for privacy
- No personal data stored on Firebase
- All sensitive data processed locally

## Testing

### Development

- Use Firebase Emulator for local testing
- Test with various input combinations
- Verify error handling scenarios

### Production

- Ensure functions are deployed to production
- Test with real user data patterns
- Monitor function performance and errors

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Check Firebase project configuration
2. **Function Not Found**: Verify function names and deployment
3. **Region Mismatch**: Ensure region matches your function deployment
4. **Network Errors**: Check internet connectivity and Firebase status

### Debug Steps

1. Check Xcode console for error messages
2. Verify Firebase project settings
3. Test functions in Firebase Console
4. Check network connectivity

## Next Steps

1. Deploy your Cloud Functions to Firebase
2. Test the integration with real data
3. Customize the AI responses based on your needs
4. Add more sophisticated error handling if needed
5. Consider adding analytics for function usage

## Support

For Firebase-specific issues:

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Support](https://firebase.google.com/support)

For app-specific issues:

- Check the Xcode console for detailed error messages
- Review the Firebase Console for function logs
