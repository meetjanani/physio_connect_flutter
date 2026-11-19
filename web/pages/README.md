# Legacy static pages → served under `/pages/`

Copy your existing HTML pages (and their CSS/JS/images) into this folder,
keeping the same folder structure they had on the old site:

    web/pages/privacy-policy.html   →  https://<your-site>/pages/privacy-policy.html
    web/pages/terms.html            →  https://<your-site>/pages/terms.html
    web/pages/legal/refund.html     →  https://<your-site>/pages/legal/refund.html

`flutter build web` copies everything in `web/` into `build/web/`, so these
files are deployed next to the Flutter app automatically.

Old links (`/privacy-policy.html`) keep working: `scripts/deploy_web.sh` runs
`scripts/sync_page_redirects.py`, which writes a 301 redirect for every page
in this folder into `firebase.json`.

Notes
- Do not add an `index.html` at the root of this folder for the old home page
  if you want `/pages/` to stay empty; the site root `/` is now the Flutter app.
- Links *inside* the old pages that point to `/style.css` etc. must become
  relative (`style.css`) or `/pages/style.css`.
- This README is not deployed (see `ignore` in firebase.json).
