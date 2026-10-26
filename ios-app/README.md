# Tail Friends iOS

This directory contains the initial SwiftUI application shell. It targets iOS 17 and later and uses only Apple SDK frameworks.

## Open and verify

Open `TailFriends.xcodeproj` in Xcode and select the shared `TailFriends` scheme. From the repository root, the equivalent simulator checks are:

```sh
xcodebuild -project ios-app/TailFriends.xcodeproj -scheme TailFriends -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ios-app/TailFriends.xcodeproj -scheme TailFriends -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO test
```

The app bundle identifier `com.example.tailfriends.ios` is provisional and exists only to make the project buildable before the production identifier is confirmed. Replace it before distribution. No team signing, credentials, API assumptions, or release workflow are configured.
