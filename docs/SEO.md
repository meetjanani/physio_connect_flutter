# Website SEO

The Flutter web app paints on a canvas, so search engines can't read it. Search
traffic lands on plain-HTML pages instead, and each one links into the app.

| URL | Targets searches like |
|---|---|
| `/physiotherapy-at-home-ahmedabad/` | physiotherapy at home Ahmedabad, home physio near me |
| `/physiotherapy-at-home-gandhinagar/` | physiotherapy at home Gandhinagar / GIFT City |
| `/online-physiotherapy-consultation/` | online physiotherapy consultation |
| `/conditions-we-treat/` | back pain / knee replacement / stroke physiotherapy |
| `/for-physiotherapists/` | physiotherapist jobs / home visit patients (supply side) |

## Editing

All of these pages, plus `web/sitemap.xml` and `web/robots.txt`, are generated:

```bash
python3 scripts/generate_landing_pages.py
```

Edit the copy in `PAGES` inside that script, never the generated HTML.
`scripts/deploy_web.sh` runs it before every build. To add a city, copy one of
the city entries, write new local copy (don't just swap the city name: Google
treats near-duplicate pages as thin content), add it to `NAV`, and re-run.

## What else is in place

- `web/index.html`: keyword title and description, canonical, Open Graph and
  Twitter cards, Organization / WebSite / MobileApplication JSON-LD, and a
  crawlable intro with links to the landing pages inside the loading screen.
- Landing pages: canonical, OG image (`web/site-assets/og-image.jpg`),
  Service, BreadcrumbList and FAQPage JSON-LD.
- `firebase.json`: logged-in app screens (`/dashboard`, `/login`, ...) send
  `X-Robots-Tag: noindex`, so Google indexes `/` and the landing pages only.
- Internal marketing tools in `web/pages/` (hub, festive, Dhanteras) and the
  404 page are `noindex`. The patient and doctor decks stay indexable.

## Custom domain

If the site moves to its own domain, change `SITE` in the script, the URLs in
`web/index.html` (canonical, `og:*`, JSON-LD) and in the two decks in
`web/pages/`, re-run the script, and add the new domain in Search Console.
