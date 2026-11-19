#!/usr/bin/env bash
# Build the Flutter web app and deploy it to Firebase Hosting.
#
#   scripts/deploy_web.sh            # build + deploy to live
#   scripts/deploy_web.sh preview    # build + deploy to a 7-day preview URL
#
# Extra flutter flags can be passed via FLUTTER_WEB_FLAGS, e.g. --dart-define=...
set -euo pipefail
cd "$(dirname "$0")/.."

python3 scripts/generate_landing_pages.py
python3 scripts/sync_page_redirects.py
# shellcheck disable=SC2086
flutter build web --release --base-href / ${FLUTTER_WEB_FLAGS:-}

if [[ "${1:-}" == "preview" ]]; then
  firebase hosting:channel:deploy preview --expires 7d
else
  firebase deploy --only hosting
fi
