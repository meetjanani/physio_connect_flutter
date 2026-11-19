#!/usr/bin/env python3
"""Generate the static SEO landing pages, sitemap.xml and robots.txt.

The Flutter web app draws everything on a canvas, so search engines see almost
no text on "/". These plain-HTML pages give Google real content to index for
searches like "physiotherapy at home Ahmedabad", and every page links into the
web app and the Android app.

    python3 scripts/generate_landing_pages.py

Writes (all under web/, so `flutter build web` copies them to build/web):
    web/<slug>/index.html      one folder per page -> https://<site>/<slug>/
    web/sitemap.xml
    web/robots.txt

Edit the copy in PAGES below and re-run. scripts/deploy_web.sh runs this
automatically. If you move to a custom domain, change SITE and re-run.
"""
import html
import json
import pathlib

SITE = "https://physio-connect-app.web.app"
BRAND = "PhysioConnect"
EMAIL = "physioconnect.app@gmail.com"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.physio.connect.physio_connect&hl=en_IN"
WEB_APP = "/"
OG_IMAGE = SITE + "/site-assets/og-image.jpg"
LOGO = SITE + "/icons/Icon-512.png"

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "web"

ORG = {
    "@type": "Organization",
    "@id": SITE + "/#organization",
    "name": BRAND,
    "url": SITE + "/",
    "logo": LOGO,
    "email": EMAIL,
    "sameAs": [PLAY_URL],
}

NAV = [
    ("/physiotherapy-at-home-ahmedabad/", "Ahmedabad"),
    ("/physiotherapy-at-home-gandhinagar/", "Gandhinagar"),
    ("/online-physiotherapy-consultation/", "Online sessions"),
    ("/conditions-we-treat/", "Conditions"),
    ("/for-physiotherapists/", "For physiotherapists"),
]

# --------------------------------------------------------------------------
# Shared content blocks
# --------------------------------------------------------------------------
HOW_IT_WORKS = """
<section>
  <h2>How booking works</h2>
  <ol class="steps">
    <li><strong>Choose your care mode:</strong> a home visit at your doorstep or an online video session.</li>
    <li><strong>Pick your city and area</strong> to see physiotherapists who serve your locality.</li>
    <li><strong>Compare therapists:</strong> photo, qualifications, specialities, years of practice, patient reviews and the consultation fee, shown before you book.</li>
    <li><strong>Choose a single session or a package</strong> of 5, 10 or 15 days, every day or on alternate days.</li>
    <li><strong>Pay securely</strong> with UPI, card or net banking and get an instant confirmation.</li>
  </ol>
  <div class="cta">
    <a class="btn primary" href="/">Book a session online</a>
    <a class="btn secondary" href="{play}" rel="noopener">Get the Android app</a>
  </div>
</section>
"""

TRUST = """
<section>
  <h2>Why patients choose {brand}</h2>
  <div class="grid">
    <div class="card"><h3>Verified physiotherapists</h3><p>Every therapist's council registration number and BPT / MPT degree is checked before they can take bookings.</p></div>
    <div class="card"><h3>Upfront, transparent fees</h3><p>You see the session fee before you pay, with no surprise clinic charges.</p></div>
    <div class="card"><h3>Digital prescriptions</h3><p>Download doctor-signed exercise plans and GST invoices for insurance claims, and share them on WhatsApp.</p></div>
    <div class="card"><h3>Progress tracked every visit</h3><p>Your physiotherapist records notes after each session so you and your family can see recovery over time.</p></div>
    <div class="card"><h3>Easy rescheduling</h3><p>Move an appointment to another free slot in the app, with clear cancellation and refund rules.</p></div>
    <div class="card"><h3>Book for your family</h3><p>Manage appointments for parents, children or your spouse from one account.</p></div>
  </div>
</section>
"""

CONDITIONS_SHORT = """
<section>
  <h2>Conditions our physiotherapists treat</h2>
  <ul class="pill-list">
    <li>Lower back pain</li><li>Neck pain &amp; cervical spondylosis</li><li>Slip disc &amp; sciatica</li>
    <li>Frozen shoulder</li><li>Knee osteoarthritis</li><li>Knee replacement (TKR) rehab</li>
    <li>Hip replacement (THR) rehab</li><li>ACL reconstruction rehab</li><li>Fracture rehab</li>
    <li>Stroke &amp; paralysis recovery</li><li>Parkinson's disease</li><li>Bell's palsy</li>
    <li>Sports injuries</li><li>Tennis elbow</li><li>Fall prevention for seniors</li>
  </ul>
  <p><a href="/conditions-we-treat/">See all conditions we treat</a></p>
</section>
"""


def faq_block(faqs):
    items = "\n".join(
        f"  <details><summary>{html.escape(q)}</summary><p>{html.escape(a)}</p></details>" for q, a in faqs
    )
    return f'<section>\n  <h2>Frequently asked questions</h2>\n{items}\n</section>'


def faq_schema(faqs):
    return {
        "@type": "FAQPage",
        "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faqs
        ],
    }


def service_schema(slug, name, description, area=None, online=False):
    s = {
        "@type": "Service",
        "@id": f"{SITE}/{slug}/#service",
        "name": name,
        "serviceType": "Physiotherapy",
        "description": description,
        "provider": {"@id": ORG["@id"]},
        "url": f"{SITE}/{slug}/",
    }
    if area:
        s["areaServed"] = [{"@type": "City", "name": c, "containedInPlace": {"@type": "State", "name": "Gujarat"}} for c in area]
    if online:
        s["availableChannel"] = {"@type": "ServiceChannel", "name": "Online video consultation (Google Meet)"}
    return s


# --------------------------------------------------------------------------
# Pages
# --------------------------------------------------------------------------
AHMEDABAD_FAQ = [
    ("How much does physiotherapy at home cost in Ahmedabad?",
     "Each physiotherapist sets their own fee, and PhysioConnect shows it on their profile before you book. Packages of 5, 10 or 15 sessions are available for longer treatment plans."),
    ("Which areas of Ahmedabad do you cover?",
     "Choose Ahmedabad and your area in the app to see physiotherapists who serve your locality. Therapists are matched by distance so home visits stay punctual."),
    ("Are the physiotherapists qualified?",
     "Yes. Every therapist on PhysioConnect has a BPT or MPT degree and a council registration number that is verified before they can accept bookings."),
    ("Can I book physiotherapy at home for an elderly parent?",
     "Yes. You can book and manage sessions for family members from your own account, and the physiotherapist can call you on WhatsApp for directions to the house."),
    ("Do I get a prescription and invoice?",
     "Yes. Your physiotherapist shares a digital prescription with your exercise plan, and you can download a GST invoice for insurance or reimbursement."),
]

GANDHINAGAR_FAQ = [
    ("Is home physiotherapy available in Gandhinagar and GIFT City?",
     "Yes. Select Gandhinagar and your sector or area in the app to see physiotherapists who serve it, along with their available time slots."),
    ("How quickly can a physiotherapist visit?",
     "You can see each therapist's free time slots in the app and book the earliest one that suits you. Your booking is confirmed instantly after payment."),
    ("What should I keep ready for a home physiotherapy session?",
     "A little floor or bed space, comfortable clothing and any previous X-ray, MRI or doctor's notes. Your physiotherapist will bring the equipment needed for the session."),
    ("Can I continue treatment online if I travel?",
     "Yes. Many therapists also offer online video sessions, which work well for follow-ups, exercise correction and posture checks."),
    ("How do I pay?",
     "Pay securely in the app or on the website with UPI (Google Pay, PhonePe, Paytm), debit or credit card, or net banking."),
]

ONLINE_FAQ = [
    ("Does online physiotherapy really work?",
     "For many conditions, yes. Online sessions are well suited to assessments, exercise programmes, posture and ergonomic advice, and follow-ups between home visits. Your physiotherapist will tell you if a condition needs hands-on treatment."),
    ("What do I need for an online session?",
     "A phone or laptop with a camera, a stable internet connection and enough space to move. The session runs on Google Meet and you join with one tap from your booking."),
    ("Can I book an online session from outside Gujarat?",
     "Yes. Online video sessions are not limited to one city, so you can consult a PhysioConnect physiotherapist from anywhere in India."),
    ("Will I get an exercise plan?",
     "Yes. After the session your physiotherapist shares a digital prescription with your exercises, sets, repetitions and precautions."),
]

PHYSIO_FAQ = [
    ("Who can join PhysioConnect as a physiotherapist?",
     "Physiotherapists with a BPT, MPT or higher degree and a valid council registration number. We verify both before your profile goes live."),
    ("How do I get paid?",
     "Patients pay online when they book. Payments are settled to your bank account through Razorpay, and you can see every session and payout in the app."),
    ("Can I set my own fees and working hours?",
     "Yes. You set your consultation fee, the areas you serve and the time slots you are available, and patients can only book those slots."),
    ("Can I offer both home visits and online sessions?",
     "Yes. You can offer doorstep home visits, online video sessions on Google Meet, or both."),
]

CONDITIONS_FAQ = [
    ("Do I need a doctor's referral for physiotherapy?",
     "You can book a physiotherapist directly for an assessment. If you have a referral, X-ray or MRI report from your orthopaedic doctor, share it with your physiotherapist at the first session."),
    ("How many physiotherapy sessions will I need?",
     "It depends on your condition. Your physiotherapist assesses you in the first session and recommends a plan, which you can book as a 5, 10 or 15 day package."),
    ("Can physiotherapy be done at home after knee replacement surgery?",
     "Yes. Home physiotherapy is common after knee and hip replacement because it avoids travel while walking is still difficult. Follow your surgeon's instructions on when to start."),
]

PAGES = [
    {
        "slug": "physiotherapy-at-home-ahmedabad",
        "title": "Physiotherapy at Home in Ahmedabad | Book Verified Physiotherapists – PhysioConnect",
        "description": "Book physiotherapy at home in Ahmedabad with verified BPT/MPT physiotherapists. Back pain, knee replacement rehab, stroke recovery and more. See fees upfront and book online.",
        "crumb": "Physiotherapy at home in Ahmedabad",
        "h1": "Physiotherapy at home in Ahmedabad",
        "lead": "Get treated by a verified physiotherapist at your doorstep, anywhere you see coverage in Ahmedabad. Compare therapists, see the fee upfront and book a home visit in minutes.",
        "body": """
<section>
  <h2>Home physiotherapy across Ahmedabad</h2>
  <p>Travelling to a clinic is the hardest part of treatment when you are in pain, recovering from surgery or caring for an elderly parent. PhysioConnect brings the clinic to you. Choose Ahmedabad in the app, select your area, and see physiotherapists who serve your locality, with their qualifications, specialities, reviews and available slots.</p>
  <p>Patients use PhysioConnect for home visits in areas such as Satellite, Bodakdev, Vastrapur, Prahlad Nagar, Navrangpura, Thaltej, Bopal, South Bopal, Gota, Chandkheda, Maninagar and along SG Highway. Availability depends on the therapists active near you, so check your exact area in the app.</p>
</section>
""",
        "faqs": AHMEDABAD_FAQ,
        "service": ("Physiotherapy at home in Ahmedabad", ["Ahmedabad"], False),
        "blocks": ["CONDITIONS_SHORT", "HOW_IT_WORKS", "TRUST"],
    },
    {
        "slug": "physiotherapy-at-home-gandhinagar",
        "title": "Physiotherapy at Home in Gandhinagar & GIFT City | PhysioConnect",
        "description": "Home physiotherapy in Gandhinagar, GIFT City, Kudasan and nearby sectors. Verified physiotherapists for back pain, post-surgery rehab and elderly care. Book online.",
        "crumb": "Physiotherapy at home in Gandhinagar",
        "h1": "Physiotherapy at home in Gandhinagar and GIFT City",
        "lead": "Verified physiotherapists who visit you at home in Gandhinagar's sectors, GIFT City and nearby areas. See fees and free slots before you book.",
        "body": """
<section>
  <h2>Doorstep physiotherapy in Gandhinagar</h2>
  <p>Whether you live in one of Gandhinagar's sectors or work long hours in GIFT City, getting to a clinic every day for a course of treatment is hard. With PhysioConnect, your physiotherapist comes to you at a time you choose, and you can switch to an online session on days you are away.</p>
  <p>Patients book home visits in places such as GIFT City, Kudasan, Sargasan, Raysan, Randesan, Koba, Infocity and Gandhinagar's sectors. Select Gandhinagar and your area in the app to see who is available near you.</p>
</section>
""",
        "faqs": GANDHINAGAR_FAQ,
        "service": ("Physiotherapy at home in Gandhinagar", ["Gandhinagar"], False),
        "blocks": ["CONDITIONS_SHORT", "HOW_IT_WORKS", "TRUST"],
    },
    {
        "slug": "online-physiotherapy-consultation",
        "title": "Online Physiotherapy Consultation on Video | PhysioConnect",
        "description": "Consult a verified physiotherapist online over video from anywhere in India. Assessments, exercise plans, posture correction and follow-ups. Book your online session today.",
        "crumb": "Online physiotherapy consultation",
        "h1": "Online physiotherapy consultation",
        "lead": "See a verified physiotherapist on a video call from home or office. Get an assessment, a personalised exercise plan and regular follow-ups without travelling.",
        "body": """
<section>
  <h2>When an online session is a good fit</h2>
  <div class="grid">
    <div class="card"><h3>First assessment</h3><p>Talk through your pain or injury and get advice on what to do next.</p></div>
    <div class="card"><h3>Exercise correction</h3><p>Your physiotherapist watches you do your exercises and corrects your form in real time.</p></div>
    <div class="card"><h3>Posture and ergonomics</h3><p>Set up your desk and work habits to reduce neck and back pain from long hours at a screen.</p></div>
    <div class="card"><h3>Follow-ups</h3><p>Keep your recovery on track between home visits or after you finish a course of treatment.</p></div>
  </div>
  <p>Sessions run on Google Meet. You join with one tap from your booking, and afterwards you receive a digital prescription with your exercises.</p>
</section>
""",
        "faqs": ONLINE_FAQ,
        "service": ("Online physiotherapy consultation", None, True),
        "blocks": ["HOW_IT_WORKS", "TRUST"],
    },
    {
        "slug": "conditions-we-treat",
        "title": "Conditions We Treat: Back Pain, Knee Replacement, Stroke Rehab | PhysioConnect",
        "description": "Physiotherapy for back and neck pain, sciatica, frozen shoulder, knee and hip replacement rehab, stroke and Parkinson's, sports injuries and elderly mobility, at home or online.",
        "crumb": "Conditions we treat",
        "h1": "Conditions our physiotherapists treat",
        "lead": "PhysioConnect physiotherapists treat a wide range of orthopaedic, post-surgical, neurological and sports conditions, at home or over video.",
        "body": """
<section id="orthopaedic">
  <h2>Orthopaedic and spine care</h2>
  <p>Lower back pain, neck pain and cervical spondylosis, slip disc, sciatica, frozen shoulder and knee osteoarthritis. Treatment usually combines pain relief, manual therapy and a progressive exercise programme you continue between sessions.</p>
</section>
<section id="post-surgery">
  <h2>Rehabilitation after surgery</h2>
  <p>Total knee replacement (TKR), total hip replacement (THR), ACL reconstruction and fractures. Home physiotherapy helps you regain movement and strength safely in the first weeks after surgery, when travelling to a clinic is hardest.</p>
</section>
<section id="neuro">
  <h2>Neurological rehabilitation</h2>
  <p>Stroke and paralysis recovery, Parkinson's disease, Bell's palsy, neuropathy and balance problems. Regular sessions at home focus on movement, balance, walking and independence in daily activities.</p>
</section>
<section id="sports">
  <h2>Sports injuries</h2>
  <p>Ligament tears, muscle strains, tennis elbow and runner's knee, plus return-to-sport conditioning.</p>
</section>
<section id="seniors">
  <h2>Elderly care and mobility</h2>
  <p>Fall prevention, joint stiffness, posture and strength to help older adults stay mobile and independent at home. Family members can book and track sessions for their parents from one account.</p>
</section>
<p class="note">This page is general information, not medical advice. Your physiotherapist will assess you before recommending treatment.</p>
""",
        "faqs": CONDITIONS_FAQ,
        "service": ("Physiotherapy treatment", ["Ahmedabad", "Gandhinagar"], False),
        "blocks": ["HOW_IT_WORKS"],
    },
    {
        "slug": "for-physiotherapists",
        "title": "Join PhysioConnect as a Physiotherapist | Get Home Visit Patients in Ahmedabad & Gandhinagar",
        "description": "Physiotherapists in Ahmedabad and Gandhinagar: list your practice on PhysioConnect, set your fees and slots, get home-visit and online patients and receive payments directly.",
        "crumb": "For physiotherapists",
        "h1": "Grow your practice with PhysioConnect",
        "lead": "Get patients near you for home visits and online sessions. Set your own fees and hours, and let the app handle bookings, payments, prescriptions and invoices.",
        "body": """
<section>
  <h2>What you get</h2>
  <div class="grid">
    <div class="card"><h3>Patients in your area</h3><p>Choose the areas you serve and appear to patients searching nearby.</p></div>
    <div class="card"><h3>Your fees, your hours</h3><p>Set your consultation fee and available time slots. Patients can only book the slots you open.</p></div>
    <div class="card"><h3>Online payments</h3><p>Patients pay when they book, and payouts are settled to your bank account through Razorpay.</p></div>
    <div class="card"><h3>Digital paperwork</h3><p>Create prescriptions on your letterhead and share progress notes. Patients get GST invoices automatically.</p></div>
    <div class="card"><h3>A verified profile</h3><p>Show your degree, registration number, specialities and experience to build trust before the first visit.</p></div>
    <div class="card"><h3>Home and online</h3><p>Offer doorstep visits, Google Meet video sessions, or both.</p></div>
  </div>
</section>
<section>
  <h2>How to join</h2>
  <ol class="steps">
    <li>Download the PhysioConnect app or open the website and register with your mobile number.</li>
    <li>Add your qualifications, council registration number, specialities and fee.</li>
    <li>Choose your service areas and open your available time slots.</li>
    <li>Start receiving bookings once your profile is verified.</li>
  </ol>
  <div class="cta">
    <a class="btn primary" href="/">Register on the website</a>
    <a class="btn secondary" href="/pages/doctor">View the onboarding guide</a>
  </div>
  <p class="note">Questions? Email <a href="mailto:{email}">{email}</a>.</p>
</section>
""",
        "faqs": PHYSIO_FAQ,
        "service": None,
        "blocks": [],
    },
]

BLOCKS = {"HOW_IT_WORKS": HOW_IT_WORKS, "TRUST": TRUST, "CONDITIONS_SHORT": CONDITIONS_SHORT}


def render(page):
    slug = page["slug"]
    url = f"{SITE}/{slug}/"
    graph = [
        ORG,
        {
            "@type": "WebPage",
            "@id": url + "#webpage",
            "url": url,
            "name": page["title"],
            "description": page["description"],
            "isPartOf": {"@id": SITE + "/#website"},
            "inLanguage": "en-IN",
        },
        {
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": BRAND, "item": SITE + "/"},
                {"@type": "ListItem", "position": 2, "name": page["crumb"], "item": url},
            ],
        },
    ]
    if page.get("service"):
        name, area, online = page["service"]
        graph.append(service_schema(slug, name, page["description"], area, online))
    if page.get("faqs"):
        graph.append(faq_schema(page["faqs"]))
    ld = json.dumps({"@context": "https://schema.org", "@graph": graph}, ensure_ascii=False, indent=1)
    ld = ld.replace("</", "<\\/")

    nav = "\n      ".join(f'<a href="{h}">{t}</a>' for h, t in NAV)
    blocks = "\n".join(BLOCKS[b] for b in page["blocks"])
    body = (page["body"] + blocks).replace("{play}", PLAY_URL).replace("{brand}", BRAND).replace("{email}", EMAIL)
    faqs = faq_block(page["faqs"]) if page.get("faqs") else ""
    footer_links = "\n          ".join(f'<li><a href="{h}">{t}</a></li>' for h, t in NAV)
    t, d = html.escape(page["title"]), html.escape(page["description"])

    return f"""<!DOCTYPE html>
<!-- Generated by scripts/generate_landing_pages.py. Edit the script, not this file. -->
<html lang="en-IN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{t}</title>
  <meta name="description" content="{d}">
  <link rel="canonical" href="{url}">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <meta name="theme-color" content="#0EA5E9">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="{BRAND}">
  <meta property="og:locale" content="en_IN">
  <meta property="og:title" content="{t}">
  <meta property="og:description" content="{d}">
  <meta property="og:url" content="{url}">
  <meta property="og:image" content="{OG_IMAGE}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{t}">
  <meta name="twitter:description" content="{d}">
  <meta name="twitter:image" content="{OG_IMAGE}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">
  <link rel="stylesheet" href="/site-assets/landing.css">
  <script type="application/ld+json">
{ld}
  </script>
</head>
<body>
  <header class="site">
    <div class="wrap">
      <a class="logo" href="/"><img src="/site-assets/logo-128.png" alt="" width="32" height="32">{BRAND}</a>
      <nav class="top" aria-label="Main">
      {nav}
      </nav>
    </div>
  </header>
  <main class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><a href="/">{BRAND}</a> › {html.escape(page["crumb"])}</nav>
    <div class="hero">
      <h1>{html.escape(page["h1"])}</h1>
      <p class="lead">{html.escape(page["lead"])}</p>
      <div class="cta">
        <a class="btn primary" href="{WEB_APP}">Book on the website</a>
        <a class="btn secondary" href="{PLAY_URL}" rel="noopener">Get the Android app</a>
      </div>
    </div>
{body}
{faqs}
  </main>
  <footer class="site">
    <div class="wrap cols">
      <div>
        <strong>{BRAND}</strong>
        <p>Verified physiotherapists at home in Ahmedabad and Gandhinagar, and online across India.</p>
        <p><a href="mailto:{EMAIL}">{EMAIL}</a></p>
      </div>
      <div>
        <strong>Physiotherapy</strong>
        <ul>
          {footer_links}
        </ul>
      </div>
      <div>
        <strong>More</strong>
        <ul>
          <li><a href="/pages/patient">Patient guide</a></li>
          <li><a href="/pages/doctor">Physiotherapist onboarding guide</a></li>
          <li><a href="{PLAY_URL}" rel="noopener">Android app</a></li>
        </ul>
      </div>
    </div>
  </footer>
</body>
</html>
"""


def main():
    for page in PAGES:
        out = WEB / page["slug"] / "index.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(render(page))

    # No <lastmod>/<priority>: Google ignores priority, and a lastmod that
    # changes on every deploy is ignored too.
    urls = ["/"] + [f"/{p['slug']}/" for p in PAGES] + ["/pages/patient", "/pages/doctor"]
    entries = "\n".join(
        f"  <url><loc>{SITE}{u}</loc></url>" for u in urls
    )
    (WEB / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + entries + "\n</urlset>\n"
    )
    (WEB / "robots.txt").write_text(
        "# App screens that need a login send `X-Robots-Tag: noindex` (see firebase.json)\n"
        "# rather than being blocked here, so Google can see that header.\n"
        "User-agent: *\n"
        "Allow: /\n\n"
        f"Sitemap: {SITE}/sitemap.xml\n"
    )
    print(f"{len(PAGES)} landing page(s), sitemap.xml ({len(urls)} URLs) and robots.txt written.")


if __name__ == "__main__":
    main()
