# Store Submission Checklist

Status legend: ✅ done in this delivery · 🔲 remaining before submission

## Both stores

- ✅ Privacy policy text drafted (below) — true for the offline-only build:
  no personal data collected, no network requests made.
- ✅ In-app "About & Attribution" screen (Settings → About & Attribution).
- ✅ Privacy policy hosted at a stable public URL (round 13 — published as
  a standalone page; ask the project for the current link).
- ✅ Final app icon in place at `app/assets/reference/app_icon_source.png`
  and regenerated for every platform (round 13, built from the user's own
  logo artwork — see `docs/ARCHITECTURE.md` §4 round 13; also fixed a
  pre-existing `ios: true` config bug the regeneration run surfaced).
- ✅ Google Play phone screenshots captured (round 13) — 5 screens (Today
  dashboard, a checklist in progress, Inventory, the Reference Library,
  and the Parish/Diocesan Calendar), verified against Google's current
  published spec (checked live, not from a stale snapshot): clears the
  320px hard minimum comfortably, though at 720×1612 they're below the
  1080px+ Google recommends for eligibility toward premium promotional
  placement — check the phone's native Screenshots folder for
  higher-resolution originals if that matters to you; not required to
  publish.
- ✅ Feature graphic built (round 13):
  `store_assets/feature_graphic.png`, exactly 1024×500, 24-bit PNG with
  no alpha channel, matching Google's spec exactly. Built from the same
  brand system as the icon/privacy/support pages (the app's own emblem,
  seed maroon, Fraunces/Public Sans) rather than a generic template — see
  `docs/ARCHITECTURE.md` §4 round 13 for how it was built.
- 🔲 Apple App Store screenshots: not pursued (iOS testing deliberately
  dropped this round, no Mac available) — at minimum, 6.7" iPhone
  (1290×2796) and 12.9" iPad (2048×2732) sets would be needed if iOS is
  revisited later; **re-verify against Apple's current published specs
  at that time**, as these change.
- ✅ App description copy (draft below) reviewed against the actual shipped
  feature set (round 13) — every Mass type, the "customizable checklists"
  claim, offline/no-data-collection claims, and the reference library all
  checked against the real code, not just proofread. No changes needed;
  the copy is already fully generic (no named parish/diocese), so it
  works regardless of distribution scope.
- ✅ Developer/publisher name for both listings: **Meye Catholic Asoreba**
  (the user's own name, confirmed round 13 — use this when creating the
  Play Console and Microsoft Partner Center developer accounts).
- ✅ Support URL for both listings (round 13 — hosted alongside the privacy
  policy as a standalone page, with a short FAQ; ask the project for the
  current link).
- 🔲 Confirm current minimum OS versions against Apple's and Google's
  published requirements at build time (these change roughly yearly) and
  set `minSdkVersion` (Android) / deployment target (iOS) accordingly.

## Apple App Store specific

- 🔲 Apple Developer Program enrollment (paid, annual).
- 🔲 App privacy "nutrition label" in App Store Connect — answer "No" to
  data collection across the board for the offline-only build; revisit if
  optional cloud sync is added later.
- 🔲 Export compliance question (this app does no custom encryption beyond
  what the OS/Flutter provide — answer per Apple's standard-encryption
  exemption guidance, confirmed at submission time).
- 🔲 TestFlight beta pass with a few real sacristans before public release —
  strongly recommended given the target users are not typically
  early-adopter/technical.

## Google Play specific

- 🔲 Google Play Console developer account (paid, one-time).
- 🔲 Data safety form — same "no data collected" answer as Apple's privacy
  label, for the offline-only build.
- 🔲 Target API level meets Play's current requirement (check at build
  time — Play enforces a rolling minimum target SDK).
- 🔲 Closed testing track with a few real sacristans before production
  rollout.

## Windows (desktop installer)

- 🔲 Code-signing certificate for the installer, if distributing outside a
  store (recommended — unsigned installers trigger SmartScreen warnings).
  The installer script below documents how to plug one in once you have
  one; not required to distribute the app in the meantime.
- ✅ Installer built and verified (round 13): `installer/sacristan.iss`
  (Inno Setup) compiles cleanly and the resulting
  `SACRISTAN-Setup-1.0.0.exe` has been installed and launched successfully
  on the user's own machine — Start Menu entry, no admin rights needed.
  See the comments at the top of that file for how to rebuild it after
  future code changes (needs Inno Setup installed once, free).
- 🔲 *(Stretch goal, not required)* Microsoft Store packaging via MSIX:
  add the `msix` pub package, configure `msix_config` in `app/pubspec.yaml`,
  run `dart run msix:create`. Low marginal cost once the Windows build
  itself works, since it reuses the same Flutter Windows binary.

## Accessibility

The original spec calls for accessibility compliance; this is what's been
verified so far, and what's left before calling it done. See
`docs/ARCHITECTURE.md` §4 (round 7) for how each item was checked.

- ✅ Liturgical color is never the only signal: every color chip/pill
  pairs the color with its text name (`LiturgicalColorChip` in
  `color_chip.dart`), and checklist items use an icon-shape change
  (circle-outline vs. filled check) in addition to color, per
  `BigCheckboxTile`'s doc comment.
- ✅ Contrast: every `swatchFor()` background/foreground pairing in
  `theme/app_theme.dart` was checked against the WCAG contrast formula —
  all seven liturgical colors clear 6.5:1, well above the 4.5:1 AA
  threshold for normal text (verified with an independent Python
  calculation, round 7).
- ✅ Touch targets: `AppTheme.minTouchTarget` (56dp) applied to buttons;
  `BigCheckboxTile` enforces a 64dp minimum row height; the whole
  checklist row (not just the checkbox glyph) is the tap target.
- ✅ Every icon-only button in the app has a `tooltip`, which Flutter also
  surfaces as the screen-reader accessibility label — a repo-wide sweep
  in round 7 found and fixed 5 of 17 `IconButton`s that were missing one
  (delete buttons on Profiles/Contacts/Suppliers, and the inventory
  quantity +/- steppers).
- 🔲 Not yet verified by an actual screen reader (VoiceOver/TalkBack) —
  everything above was checked by reading the widget tree and computing
  contrast by formula, not by running the app (this sandbox has no
  Flutter runtime — see the README). **Run a real screen-reader pass on a
  device before submission**, especially through the multi-step dialogs
  (Add Inventory Item, Add Local Calendar Entry) which have the most
  form fields per screen.
- 🔲 Dynamic/system text-scaling (a user with their OS font size turned
  up) has not been checked for layout overflow anywhere in the app.

## Claims & messaging (both stores' review guidelines care about this)

- 🔲 Confirm the store listing does **not** imply institutional endorsement
  by the Catholic Church, a diocese, or the Vatican unless that
  endorsement genuinely exists. Suggested framing: "An independent app for
  parish sacristans" / "Not affiliated with or endorsed by any diocese."
  The in-app About screen already states this — mirror the same language
  in the store listing.
- 🔲 No broken links in the listing (privacy policy URL, support URL).

---

## Draft privacy policy (for the offline-only build)

> **SACRISTAN Privacy Policy**
>
> SACRISTAN collects no personal data and makes no network requests. All
> data you enter — checklists, inventory, notes, and any local calendar
> entries — is stored only in a local database on your device. There is no
> account, no login, no analytics, and no advertising SDK in this app. If a
> future version of this app adds an optional cloud-backup or
> multi-device-sync feature, it will be clearly opt-in, and this policy
> will be updated to describe exactly what that feature transmits before
> it is enabled by default for anyone.
>
> *Last updated: [fill in the date you publish this].*

## Draft store listing copy

> **Short description:** A companion for Catholic sacristans — today's
> liturgical color and rank at a glance, Mass-prep checklists, vestment and
> vessel inventory, and an offline reference library. Works fully offline.
>
> **Long description:**
> SACRISTAN helps sacristans — the volunteers and staff who prepare the
> sacristy, vestments, sacred vessels, and altar for Mass — keep track of
> the details that are easy to overlook, especially in the few minutes
> before Mass begins.
>
> - See today's liturgical color, rank, and season at a glance, plus the
>   week ahead, so you can plan vestment and linen prep in advance.
> - Customizable Mass-prep checklists for Sunday Mass, weekday Mass,
>   funerals, weddings, baptisms, Benediction/Adoration, and the special
>   rites of Holy Week.
> - Track vestments, vessels, and linens by category, color, condition,
>   and storage location.
> - An offline reference library: a glossary of vestment and vessel names
>   with original illustrations, and short notes on sacristan duties.
> - Works completely offline — every feature, including the liturgical
>   calendar, works with no internet connection, for any date past or
>   future.
> - Your data stays on your device. No account required, nothing is sent
>   to any server.
>
> SACRISTAN is an independent app for practical parish use. It is not
> published, endorsed, or reviewed by the Vatican, a diocese, or any
> parish, and it is not a substitute for the Roman Missal, the GIRM, or
> your pastor's and diocese's own instructions.
>
> SACRISTAN is free and provided as-is, with no warranty of any kind.
> Always double-check anything time-sensitive or feast-specific against
> your parish's own calendar and your pastor's instructions.
