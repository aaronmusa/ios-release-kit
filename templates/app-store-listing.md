# App Store listing — {{APP_NAME}}

Fill this in, then check every field fits before pasting anything into App Store
Connect:

```
xcrun swift ../scripts/check-listing.swift app-store-listing.md
```

The limits in the headings are what the checker reads. Leave them alone.

Write the description unwrapped, one line per paragraph. Hard wraps paste into
App Store Connect as literal line breaks and split sentences in half.

## Name (30)

```
{{APP_NAME}}
```

## Subtitle (30)

```

```

Say the one thing that separates this app from the others in its category. This
is the field that answers Guideline 4.3 in six words.

## Promotional text (170)

```

```

Editable without shipping a build, unlike everything else here.

## Description (4000)

```

```

The first two lines are all most people read before deciding whether to tap
"more". Spend them on the differentiator, not on "welcome to {{APP_NAME}}".

## Keywords (100, comma separated, no spaces after commas)

```

```

The app name is already indexed, so repeating it is wasted. Apple matches
singular and plural, so pick one.

## App Review information

Put this in **Notes**. If anything in the app sits behind a gate — a paywall, a
usage limit, an account — say exactly how a reviewer reaches it. A reviewer who
cannot reach an in-app purchase files a 2.1, and that is the most common
in-app-purchase rejection there is.

```
No account or sign-in is required.

The purchase is reachable at {{WHERE}} without {{PRECONDITION}}.

{{WHAT_IT_UNLOCKS}}. Non-consumable, one-time purchase, no subscription.
```

## Other fields

- **Category**: primary, and a secondary if one genuinely fits
- **Age rating**: answer the questionnaire honestly; most utilities land at 4+
- **Privacy Policy URL**: required, and it must resolve — a dead link is a 5.1.1 rejection
- **Support URL**: required, and a bare `mailto:` is not accepted
- **EULA**: leave blank to use Apple's standard one
- **Copyright**: `{{YEAR}} {{DEVELOPER}}` — no © symbol, App Store Connect adds it

## Screenshots

6.9" (1320 x 2868) is the only size you need; App Store Connect scales it down.

Only the first three appear in search results, so spend them on what the app
does that others do not. Alternating light and dark screens gives the row of
thumbnails some rhythm.

Rules worth holding to:

- The screen itself must be the real app. Captions, backgrounds and device
  frames around it are fine; a mocked-up screen is not.
- Never screenshot the paywall. It sells nothing, and the purchase has its own
  required review screenshot in App Store Connect.
- Use real-looking content, not "Item 1" and "Team A".
- Check no debug affordance is visible before compositing.

Generate them with `scripts/make-store-shots.swift` and a copy of
`store-shots.json`.
