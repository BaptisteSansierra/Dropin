#!/bin/zsh
# Generates the localized fastlane deliver metadata from fastlane/AppStoreMetadata.xcstrings.
#
#   ./scripts/appstore_metadata.sh [--version X.Y.Z] [--skip-release-notes]
#
# Writes fastlane/metadata/<locale>/<key>.txt for every key of the catalog, en as fallback:
#   name, subtitle, description, keywords, promotional_text
#   release_notes   from the "release_notes.<version>" key (one key per version = history),
#                   version = --version, or the app's MARKETING_VERSION
# Not localized metadata is not generated: urls in fastlane/metadata/default/ (per locale copies are deleted),
# categories + copyright in fastlane/metadata/*.txt.
# Fails on a value over Apple's length limit, or a missing release notes key.
# --skip-release-notes: first version of the app, App Store Connect refuses release notes.

set -euo pipefail

ROOT="${0:A:h:h}"
CATALOG="$ROOT/fastlane/AppStoreMetadata.xcstrings"
METADATA="$ROOT/fastlane/metadata"

# MARK: - Settings

# Catalog language → App Store locale (fastlane/metadata/<locale>, same as FASTLANE_LOCALES in screenshots.sh)
LOCALES="en:en-US fr:fr-FR es:es-ES"
FALLBACK_LANGUAGE="en"

# MARK: - Main

main() {
    local version="" skip_release_notes=0
    while (( $# )); do
        case "$1" in
            --version) version="$2"; shift 2 ;;
            --skip-release-notes) skip_release_notes=1; shift ;;
            *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
    done
    if [[ -z "$version" ]]; then
        version=$(xcodebuild -project "$ROOT/Dropin.xcodeproj" -target Dropin -configuration Release \
            -showBuildSettings 2>/dev/null | awk '$1 == "MARKETING_VERSION" { print $3 }')
    fi
    [[ -n "$version" ]] || { echo "No MARKETING_VERSION found, pass --version" >&2; exit 1; }

    echo "▸ App Store metadata (version $version)"
    python3 -I - "$CATALOG" "$METADATA" "$LOCALES" "$FALLBACK_LANGUAGE" "$version" "$skip_release_notes" <<'EOF'
import json, sys
from pathlib import Path

catalog, metadata, locales, fallback, version, skip_release_notes = sys.argv[1:]
strings = json.load(open(catalog))["strings"]
locales = dict(pair.split(":") for pair in locales.split())

# file name → Apple's character limit
LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170,
          "description": 4000, "release_notes": 4000}
RELEASE_NOTES_KEY = f"release_notes.{version}"
DEFAULT_FILES = ["privacy_url.txt", "support_url.txt", "marketing_url.txt"]

def value(key, language):
    localizations = strings.get(key, {}).get("localizations", {})
    for lang in (language, fallback):
        text = localizations.get(lang, {}).get("stringUnit", {}).get("value", "")
        if text.strip():
            return text.strip(), lang
    return "", None

files = {key: key for key in strings if not key.startswith("release_notes.")}
if skip_release_notes == "1":
    print("  release notes skipped (first release)")
elif RELEASE_NOTES_KEY not in strings:
    sys.exit(f"  ✗ no '{RELEASE_NOTES_KEY}' key in {Path(catalog).name}: add this version's release notes")
else:
    files["release_notes"] = RELEASE_NOTES_KEY

# App review information is managed on App Store Connect: deliver would upload what download_metadata wrote
import shutil
shutil.rmtree(Path(metadata) / "review_information", ignore_errors=True)

errors = 0
for language, locale in locales.items():
    folder = Path(metadata) / locale
    folder.mkdir(parents=True, exist_ok=True)
    if skip_release_notes == "1":
        (folder / "release_notes.txt").unlink(missing_ok=True)
    # Same URLs for every locale: fastlane/metadata/default/ (download_metadata writes a copy per locale, which would win)
    for file in DEFAULT_FILES:
        (folder / file).unlink(missing_ok=True)
    for file, key in files.items():
        text, source = value(key, language)
        path = folder / f"{file}.txt"
        if not text:
            path.unlink(missing_ok=True)   # nothing sent, App Store Connect keeps its value
            print(f"  ⚠ {locale}/{file}: empty")
            continue
        limit = LIMITS.get(file)
        if limit and len(text) > limit:
            print(f"  ✗ {locale}/{file}: {len(text)} characters, limit {limit}", file=sys.stderr)
            errors += 1
        path.write_text(text + "\n")
        if source != language:
            print(f"  ⚠ {locale}/{file}: not translated, {source} used")
sys.exit(1 if errors else 0)
EOF
}

main "$@"
