# Firebase setup for CivicFix (step by step)

The code is already wired for Firebase. Until you add the packages below, the app
builds and runs on the offline mock. Once Firebase is linked, `AuthServiceFactory`
switches to `FirebaseAuthService` automatically and `CivicFixApp` calls
`FirebaseApp.configure()`. You don't have to edit any Swift.

## 1. Create the Firebase project
1. Go to <https://console.firebase.google.com> and sign in.
2. **Add project** → name it `CivicFix` → Analytics is optional → **Create project**.

## 2. Register the iOS app
1. On the project home, click the **iOS+** icon.
2. **Apple bundle ID:** `com.lozaa.CivicFix` (must match exactly. Xcode → CivicFix target → General → Bundle Identifier).
3. App nickname is optional. Skip the App Store ID. Click **Register app**.
4. **Download `GoogleService-Info.plist`**.

## 3. Add the plist to Xcode
1. Drag `GoogleService-Info.plist` into the **CivicFix** group in the Xcode sidebar.
2. In the dialog: tick **Copy items if needed**, and tick only the **CivicFix** target
   (not CivicFixTests or CivicFixUITests).
3. Click **Finish**. Back in the Firebase wizard, skip the remaining steps. Those are already done in code.

## 4. Add the Firebase SDK (Swift Package Manager)
1. Xcode → **File → Add Package Dependencies…**
2. Paste `https://github.com/firebase/firebase-ios-sdk` into the search box.
3. Dependency rule: **Up to Next Major Version** (the default). Click **Add Package** (the first download is large).
4. In the product list, add **FirebaseAuth** to the **CivicFix** target. Leave everything else unticked.
   (`FirebaseCore` comes with it.)

## 5. Enable Email/Password sign-in
1. Firebase console → **Build → Authentication → Get started**.
2. **Sign-in method** tab → **Email/Password** → toggle **Enable** → **Save**.
3. Optional: **Settings → Password policy** to enforce rules on the server. The app already asks for 8+ characters with a letter and a number.

## 6. Build and test
Run on a simulator or device (**⌘R**). Then check:

| Test | Expected |
|---|---|
| Create Account | You land on Home; the user appears under Authentication → Users |
| Force-quit and relaunch | Splash, then straight to Home (session restored from Core Data + Firebase) |
| Settings → Sign Out → Sign in with Face ID | Signs back in (uses the Keychain, see notes) |
| Settings → Change password | Succeeds; sign in with the new password |
| Settings → Change email | "Verification link sent". Tap the link in the new inbox, reopen the app, and Settings shows the new email |
| Forgot Password | Reset email arrives |

## 7. Customize the emails (optional)
Authentication → **Templates** lets you edit the verification, password-reset and email-change emails (sender name, language, subject).

## Troubleshooting
- **`The default FirebaseApp instance must be configured` crash.** `GoogleService-Info.plist` isn't in the CivicFix target. Select the file and check **Target Membership**.
- **"keychain error" / error 17995 on the simulator.** Target CivicFix → Signing & Capabilities → **+ Capability → Keychain Sharing** (no group needed), then rebuild.
- **Change email says "requires recent login".** Expected if the session is old. The user must re-enter their password. The app's form always asks for it, so this should only appear on unusual failures.
- **Change email never changes the address.** The link must be tapped. Firebase intentionally doesn't change the email until it's verified.
- **Network errors on device.** Check the bundle ID matches the one registered in step 2.

## What changed in the code
- `Services/FirebaseAuthService.swift`: sign in, register, reset, change email/password. Compiles only when FirebaseAuth is linked.
- `Services/KeychainCredentialStore.swift`: stores the last login in the Keychain so Face ID still works after an explicit sign out (Firebase clears its own session on sign out).
- `Services/SessionRepository.swift` + `UserSession` entity: Core Data login session.
- `Features/Settings/*`: settings/profile, change email, change password.
- `Core/DesignSystem/AppColors.swift` + `Core/Settings/AppAppearance.swift`: light/dark palette and Auto/Light/Dark switch.
