# Store Submission Checklist

Status legend: ✅ done in this delivery · 🔲 remaining before submission

## Both stores

- ✅ Privacy policy text drafted (below) — true for the offline-only build:
  no personal data collected, no network requests made.
- ✅ In-app "About & Attribution" screen (Settings → About & Attribution).
- 🔲 Host the privacy policy at a stable public URL (both stores require a
  URL, not just in-app text). A single static page with the text below is
  enough — no server logic needed.
- 🔲 Final app icon (replace the placeholder at
  `app/assets/reference/app_icon_source.png`, then re-run
  `dart run flutter_launcher_icons`).
- 🔲 Screenshots per store's current size requirements (sizes below are a
  snapshot — **re-verify against each store's current published specs
  before submitting**, as these change):
  - Apple App Store: at minimum, 6.7" iPhone (1290×2796) and 12.9" iPad
    (2048×2732) screenshot sets; App Store Connect will list the current
    required set when you create the listing.
  - Google Play: at minimum a phone screenshot set (16:9 or 9:16, ≥320px
    on the short side) plus a feature graphic (1024×500).
- 🔲 App description copy (draft below) — review for your parish/diocese's
  actual distribution scope before publishing.
- 🔲 Support URL / contact email for both listings.
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
- 🔲 Package with an installer tool (Inno Setup, WiX, or `flutter build
  windows` + a simple Inno Setup script) — not a store requirement, so this
  can ship on your own timeline.
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
