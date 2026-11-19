# PhysioConnect website (Flutter web on Firebase Hosting)

The same Flutter code base now builds for the browser. The site layout is:

| URL | Served from |
|---|---|
| `/` and every app route | Flutter web app (`build/web/index.html`) |
| `/pages/<file>.html` | Your existing static pages (`web/pages/`) |
| `/<file>.html`, `/<file>` (old links) | 301 redirect to `/pages/<file>.html` |
| `/pages/<missing>` | `web/pages/404.html` |

## One-time setup

1. Static pages (doctor / patient decks, marketing hub, festive campaigns) live
   in `web/pages/` (images in `web/pages/assets/`). Short links redirect:
   `/doctor`, `/patient`, `/hub`, `/festive`, `/diwali`, `/dhanteras` →
   `/pages/<name>`. Add new short links in `firebase.json` (`redirects` +
   matching `/pages/<name>` rewrite). The old `public/` folder is no longer used.
2. **Firebase Web app**: done. "PhysioConnect Web" is registered and its
   config is in `lib/firebase_web_options.dart`.
3. **Phone OTP login on web** — Console → Authentication → Settings →
   *Authorized domains*: make sure your site domain is listed
   (`physio-connect-app.web.app` and any custom domain).
4. **App Check** — the reCAPTCHA v3 site key in `lib/main.dart` must allow your
   website domain (Google reCAPTCHA admin console), and the Web app must be
   registered under Console → App Check with that key. Otherwise Firebase
   calls from the website will be rejected if enforcement is on.
5. **Payments** — until Razorpay approves the website domain, the website
   pays via Payment Link + UPI QR. Deploy the migration, functions and webhook
   listed in [WEB_PAYMENTS_SERVER.md](WEB_PAYMENTS_SERVER.md); before that the
   website asks users to pay in the Android app.
6. **Firebase CLI account** — sign in with the Google account that owns
   `physio-connect-app`: `firebase login:add` then `firebase login:use <email>`.
7. If your existing pages are on a *non-default* Hosting site, add
   `"site": "<site-id>"` to the `hosting` block in `firebase.json`.

## Deploy

```bash
scripts/deploy_web.sh preview   # 7-day preview URL – check it first
scripts/deploy_web.sh           # live
```


## Test locally

```bash
flutter build web --release && firebase emulators:start --only hosting
```

Open http://localhost:5000 — the hosting emulator applies the same redirects
and rewrites as production.

## Website URLs

The app uses real paths (`/dashboard`, `/booking-history`), not `/#/…`.
Firebase Hosting rewrites every app path to `index.html`, so refresh, bookmarks
and shared links work. Rules on direct visits:

- Signed-out visitors opening a protected page go to `/login`.
- Booking steps (`/selectServiceArea` … `/bookingConfirmation`) keep their
  choices in memory; on refresh they restart at `/selectServiceCity`.
- `/booking-detail?id=<id>` and `/doctor-profile?id=<id>` load from the URL.
  A booking is shown only to its patient or doctor.
- Unknown paths go to the dashboard (or login).

Local testing needs a server with the same SPA fallback (`firebase emulators`
does this); `python -m http.server` will 404 on refresh.

## What behaves differently on web

- **Payments** use a Razorpay Payment Link / UPI QR dialog (pay on this
  device, or scan the QR from a phone); the server confirms the payment.
  Android keeps the native Razorpay SDK.
- **Invoices / prescriptions / letter heads** open the browser's print/save-as-PDF dialog.
- **Push & reminder notifications**, Crashlytics and the animated HTML splash
  are mobile-only; the web gets a simple branded splash.
- **"Use current location"** fills coordinates; the street address must be typed
  (reverse geocoding is unavailable in the browser).
