# ios-release-kit

The parts of shipping an iOS app to the App Store that are the same every time,
pulled out of a project that had just done it.

Nothing here is a framework. Copy what you need into a project and edit it —
these are starting points that encode mistakes already made, not abstractions.

## Scripts

### `scripts/bump-build.sh`

Bumps `CURRENT_PROJECT_VERSION` across an Xcode project, and optionally moves
the tag a cloud build watches.

```
./bump-build.sh                      # bump by one
./bump-build.sh --to 42              # set explicitly
./bump-build.sh --tag ci/testflight  # bump, then move and force-push the tag
```

The tag is a moving pointer, not a release marker, so re-triggering is a force
push. It refuses to move the tag while the working tree is dirty, because a tag
pointing at a commit without the bump in it produces the rejection you were
trying to avoid.

**Check what is already uploaded before trusting the project file.** The counter
drifts the moment a build is distributed from a machine without the bump coming
back into git.

### `scripts/make-store-shots.swift`

Composites App Store screenshots: a captured screen in a drawn device body, on a
gradient field, under a caption. Core Graphics, no dependencies.

```
xcrun swift make-store-shots.swift shots.json captures/ out/
```

Config shape is `templates/store-shots.json` — canvas, palette, font, caption
size, and the shot list. Defaults are 1320x2868, the 6.9" size that App Store
Connect scales down for every other device.

Apple requires the screen itself to be the real app, so captures are drawn
untouched and only the surround is generated.

### `scripts/capture-shots.sh`

Prepares a simulator and takes the captures.

```
./capture-shots.sh prepare <udid>          # 9:41, full battery, clean status bar
./capture-shots.sh shot <udid> out/01.png
./capture-shots.sh tap <udid> 219 387      # points, not pixels
```

Two things that waste a session, both learned the hard way: shut every other
simulator down first, because `idb` acts on whichever is booted; and a landscape
screen still comes out in the portrait frame, so rotate the file afterwards with
`sips -r 270`.

### `scripts/check-listing.swift`

Counts every App Store Connect field against Apple's limits, so a field is not
discovered to be too long by pasting it in.

```
xcrun swift check-listing.swift app-store-listing.md
```

Reads `templates/app-store-listing.md`: a heading with a limit in parentheses,
then a fenced block holding the value. Exits non-zero if anything is over.

Worth knowing, because it is not documented anywhere obvious: an **in-app
purchase description is capped at 55 characters**, not the ~170 the app-level
fields allow.

## Templates

### `templates/app-store-listing.md`

Every App Store Connect text field with its limit, plus the App Review notes —
the field that decides whether a reviewer can find a gated purchase. A reviewer
who cannot reach an in-app purchase files a 2.1, and that is the most common
in-app-purchase rejection there is.

### `templates/release-checklist.md`

Pre-flight, with a record table at the bottom. The debug-symbol step includes
its control, because **the obvious version of that check passes on a dirty
binary**: a Debug build is a launcher stub with the code in a separate
`.debug.dylib`, so grepping the app binary finds nothing in either
configuration.

### `templates/legal/`

Privacy policy, support page and an index, styled and ready for GitHub Pages.
Placeholders: `{{APP_NAME}}`, `{{DEVELOPER}}`, `{{CONTACT_EMAIL}}`,
`{{ONE_LINE_DESCRIPTION}}`, `{{EFFECTIVE_DATE}}`.

**Read every sentence of the privacy policy before publishing it.** It is
written for an app with no accounts, no analytics, no third-party SDKs, and
iCloud sync into the user's own private database. If your app does anything
else, the text is wrong, and a policy that does not describe the app is a 5.1.1
problem rather than a formatting one.

App Store Connect requires a Support URL and will not accept a bare `mailto:`,
which is why the support page exists.

Publish with GitHub Pages on its own repo, so the documents can change without
waiting on an app release.

## Things that cost time, worth knowing once

- **CloudKit has two schemas.** Development fills itself in as Debug builds
  save; Production only has what you explicitly deploy. A TestFlight build
  against an unpromoted Production schema syncs nothing and reports no error.
- **A `ModelContainer`'s CloudKit configuration is fixed when it is built**, and
  it is built once at launch. Anything gating sync on state the app learns
  asynchronously — a purchase, a sign-in — will be a launch behind.
- **UserDefaults does not survive a reinstall; `NSUbiquitousKeyValueStore`
  does.** Any flag that has to outlive a delete belongs in the latter.
- **Export compliance** belongs in `Info.plist` as
  `ITSAppUsesNonExemptEncryption`, or every upload asks.
- **A stale keychain token presents as the wrong GitHub account.** An entry
  labelled with one username can hold another's token; `git push` then fails
  with a name you do not recognise.

## Fonts

`templates/fonts/Archivo-ExtraBold.ttf` is here so the screenshot script runs out
of the box. Archivo is SIL Open Font License. Swap it for whatever the app
actually uses.
