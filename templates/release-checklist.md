# Release pre-flight — {{APP_NAME}}

Run before every upload. Record what you verified at the bottom; the value of
this document is the row you add, not the list.

1. **Release build carries no debug code.** Build Release, then grep the binary
   for strings that only exist behind your debug flag:

   ```
   xcodebuild -project {{PROJECT}}.xcodeproj -scheme {{SCHEME}} -configuration Release \
     -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
   strings -a <Release-iphonesimulator>/{{APP}}.app/{{APP}} | grep -c '{{DEBUG_STRINGS}}'
   ```

   It must report 0. **Run the control before believing that zero**, because two
   things make a false pass easy:

   - A Debug build is a ~60 KB launcher stub with the code in a separate
     `{{APP}}.debug.dylib`. Grepping `{{APP}}.app/{{APP}}` in Debug finds nothing
     either, so a broken grep looks exactly like a clean binary. The same grep
     against the dylib must **find** the strings.
   - Build tooling has been known to silently drop a `configuration` argument
     and build Debug while reporting success. Confirm a `Release-iphonesimulator`
     directory actually appeared.

   The Release bundle must also contain no `.debug.dylib` and no `__preview.dylib`.

2. **Display name** reads correctly on the home screen.

3. **Launch screen** matches the app's own first frame. `UILaunchScreen` scales
   its image to **cover**, so the larger screen dimension drives the scale. iOS
   caches launch snapshots per app, so a device that has run an older build will
   lie about this — test on one that has not.

4. **App icon** is 1024x1024 with no alpha channel:
   `sips -g pixelWidth -g pixelHeight -g hasAlpha AppIcon.png`

5. **Privacy manifest** (`PrivacyInfo.xcprivacy`) declares tracking, collected
   data types, and a reason for every required-reason API actually used. Check
   for file timestamps, system boot time, disk space, active keyboards and
   UserDefaults before assuming the list is complete.

6. **App Privacy answers** in App Store Connect match what the app really does.
   Data held in the user's own iCloud is not collected by you; data sent to a
   server you run is.

7. **Build number is higher than the last upload.** App Store Connect rejects
   anything that is not, and the counter drifts the moment a build is
   distributed from a machine without the bump coming back into git. Check what
   is already uploaded rather than trusting the project file.
   `scripts/bump-build.sh` does the bump.

8. **Export compliance** is declared in `Info.plist` as
   `ITSAppUsesNonExemptEncryption`, so uploads stop asking. `false` is only true
   while the app's sole use of encryption is HTTPS through Apple's own
   frameworks. Adding custom cryptography, or a third-party SDK that ships its
   own, makes the declaration false. It is a legal declaration, not a build
   setting.

9. **Anything written to iCloud, or to any server, is a privacy policy edit as
   well as a code change.** A shipped policy that no longer describes the app is
   a 5.1.1 problem, and the drift is invisible from inside the codebase.

## Record

| Date | Build | Steps verified | Notes |
|---|---|---|---|
| | | | |
