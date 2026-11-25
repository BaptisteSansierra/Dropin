#!/bin/zsh
# Generates App Store + website screenshots from the DropinScreenshots UI tests.
#
#   ./scripts/screenshots.sh            run the tests, then process the screenshots
#   ./scripts/screenshots.sh -h|--help  show this help
#   ./scripts/screenshots.sh --reuse    skip the tests, reprocess Screenshots/last.xcresult
#   ./scripts/screenshots.sh --test testMap [--test testList] [--config fr]
#                                       partial run: only these tests (repeatable) / this configuration,
#                                       only their shots are rewritten, the other files are kept
#                                       (Screenshots/last.xcresult then holds this partial run only)
#
# Runs every configuration of DropinScreenshots.xctestplan (en, fr, es) on a 6.9" simulator,
# exports the XCTAttachments from the result bundle, then writes:
#   Screenshots/appstore/<configuration>/NN_<shot>.png APPSTORE_SHOTS, every configuration, framed:
#                                                     caption (AppStoreCaptions.xcstrings) above the shot
#   fastlane/screenshots/<locale>/N_<shot>.png        the framed App Store shots, for fastlane deliver
#   Screenshots/website/<configuration>/<file name>.webp  WEBSITE_SHOTS, every configuration, resized:
#                                                     copy into Dropin_frontend/assets/screens/
#   Screenshots/readme/<file name>.webp               README_SHOTS, en website versions, for README.md
#   Screenshots/last.xcresult                         full report: open Screenshots/last.xcresult
# Failed tests are listed; screenshots of the passing ones are still exported.
# Needs: ImageMagick + cwebp (brew install imagemagick webp), SF Pro fonts (developer.apple.com/fonts)

set -euo pipefail

SCRIPT="${0:A}"
ROOT="${SCRIPT:h:h}"
OUT="$ROOT/Screenshots"
RESULT="$OUT/last.xcresult"
TESTS_FILE="$ROOT/DropinScreenshots/DropinScreenshots.swift"
TEST_PLAN="$ROOT/DropinScreenshots.xctestplan"

# MARK: - Settings

DEVICE_NAME="iPhone 17 Pro Max"   # 6.9", the size App Store Connect requires
BUNDLE_ID="com.batsansierra.Dropin"
LOCATION="38.7159,-9.1310"        # Lisbon (Graça, below Senhora do Monte), inside Region.lisbon (DropinScreenshots.swift), clear of the pins

# Shot names = XCTAttachment names (Shot in DropinScreenshots.swift)
# App Store order: file prefix 01_, 02_... Captions: DropinScreenshots/Resources/AppStoreCaptions.xcstrings
APPSTORE_SHOTS=(
    places.map
    places.place.details
    places.map.quickcreate
    settings.import.mapstr
    places.list
)
CAPTIONS="$ROOT/DropinScreenshots/Resources/AppStoreCaptions.xcstrings"
# Test plan configuration → App Store locale (fastlane/screenshots/<locale>, same as fastlane/metadata/<locale>)
typeset -A FASTLANE_LOCALES=(
    en en-US
    fr fr-FR
    es es-ES
)
FASTLANE_SCREENSHOTS="$ROOT/fastlane/screenshots"
# Framed image: 6.9" size, screenshot scaled down under its caption
FRAME_SIZE=(1320 2868)
FRAME_BACKGROUND="#588B8B"
CAPTION_COLOR="#FDFCF8"
CAPTION_FONT="/Library/Fonts/SF-Pro-Display-Bold.otf"
CAPTION_POINTSIZE=96
CAPTION_MAX_WIDTH=1120            # longer captions are split in 2 balanced lines
SHOT_SCALE=80                     # %
SHOT_TOP=500                      # caption band height = screenshot top
SHOT_RADIUS=150
SHOT_BORDER=10                    # drawn outside the screenshot, outer radius = SHOT_RADIUS + SHOT_BORDER
SHOT_BORDER_COLOR="#FFFFFF80"     # white 50%
SHOT_SHADOW="45x28+0+24"          # opacity x sigma + offset
SHOT_SHADOW_MARGIN=56             # transparent margin -shadow adds around the image: 2 x sigma

# <shot> <file name> <width> <height>: 3x of the CSS width the site displays them at
WEBSITE_SHOTS=(
    "places.map                     places.map                      855 1858"   # 285px
    "places.map                     places.map.220                  660 1434"   # 220px
    "places.map.dark                places.map.dark                 696 1512"   # 232px
    "places.list                    places.list                     855 1858"   # 285px
    "places.place.details           places.place.details            780 1695"   # 260px
    "places.map.filtered            places.map.filtered             660 1434"   # 220px
    "places.filter.off              places.filter.off               660 1434"   # 220px
    "places.filter.on               places.filter.on                660 1434"   # 220px
    "settings                       settings                        780 1695"   # 260px
    "settings.import                settings.import                 780 1695"   # 260px
    "settings.import.mapstr         settings.import.mapstr          780 1695"   # 260px
    "settings.import.mapstr.mapper  settings.import.mapstr.mapper   780 1695"   # 260px
    "settings.import.google         settings.import.google          780 1695"   # 260px
    "places.map.quickcreate         places.map.quickcreate          780 1695"   # 260px
)
WEBP_QUALITY=85

# README.md images: WEBSITE_SHOTS file names, copied from the README_LANGUAGE website versions
README_SHOTS=(
    places.list
    places.map
    places.map.dark
    places.map.quickcreate
    places.place.details
    places.filter.on
    settings
    settings.import
    settings.import.mapstr
)
README_LANGUAGE=en

# MARK: - Steps

# Boots the simulator, runs the DropinScreenshots test plan into $RESULT, prints the failures.
# Sets TEST_STATUS (xcodebuild exit code).
runScreenshotsScheme() {
    local udid
    # First available simulator with that name (there may be duplicates)
    udid=$(xcrun simctl list devices available -j | python3 -I -c '
import json, sys
name = sys.argv[1]
devices = [d for runtime in json.load(sys.stdin)["devices"].values() for d in runtime if d["name"] == name]
print(devices[0]["udid"] if devices else "")' "$DEVICE_NAME")
    [[ -n "$udid" ]] || { echo "No available simulator named '$DEVICE_NAME'" >&2; exit 1; }

    echo "▸ Booting $DEVICE_NAME ($udid)"
    xcrun simctl boot "$udid" 2>/dev/null || true   # already booted is fine
    xcrun simctl bootstatus "$udid" >/dev/null
    xcrun simctl status_bar "$udid" override \
        --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    # Real LocationManager authorized + positioned in Lisbon (no "location not authorized" UI, dot on the map)
    xcrun simctl privacy "$udid" grant location "$BUNDLE_ID"
    xcrun simctl location "$udid" set "$LOCATION"

    echo "▸ Running DropinScreenshots"
    mkdir -p "$OUT"
    rm -rf "$RESULT"
    set +e
    xcodebuild test \
        -project "$ROOT/Dropin.xcodeproj" \
        -scheme DropinScreenshots \
        -testPlan DropinScreenshots \
        -destination "platform=iOS Simulator,id=$udid" \
        -parallel-testing-enabled NO \
        -resultBundlePath "$RESULT" \
        "${FILTER_ARGS[@]}" \
        -quiet 2>&1 | { grep -v -e "IDELaunchParametersSnapshot" -e "Upload Debug Symbols to Sentry" || true; }   # drop Xcode's debugger-version noise + the Sentry phase note (it exits unless archiving)
    TEST_STATUS=${pipestatus[1]}
    set -e

    xcrun simctl status_bar "$udid" clear
    xcrun simctl location "$udid" clear
    [[ -d "$RESULT" ]] || { echo "No result bundle (build failure?)" >&2; exit 1; }

    xcrun xcresulttool get test-results summary --path "$RESULT" > "$WORK/summary.json"
    python3 -I - "$WORK/summary.json" "${RESULT#$ROOT/}" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
failures = d.get("testFailures", [])
mark = "✗" if failures else "✓"
print(f"{mark} {d.get('failedTests', 0)} failed / {d.get('passedTests', 0)} passed")
for f in failures:
    print(f"  - {f.get('testIdentifierString')}: {f.get('failureText')}")
if failures:
    print(f"  Full report: open {sys.argv[2]}")
EOF
}

# Exports the attachments of $RESULT to $RAW/<configuration>/<shot>.png
retrieveSnapshots() {
    echo "▸ Exporting attachments"
    xcrun xcresulttool export attachments --path "$RESULT" --output-path "$WORK/attachments" >/dev/null
    python3 -I - "$WORK/attachments" "$RAW" <<'EOF'
import json, re, shutil, sys
from pathlib import Path
src, dst = Path(sys.argv[1]), Path(sys.argv[2])
count = 0
for test in json.loads((src / "manifest.json").read_text()):
    for a in test["attachments"]:
        if a.get("isAssociatedWithFailure"):
            continue   # XCTest's automatic "App UI hierarchy" capture of a failed test
        # suggestedHumanReadableName = "<stem>_<n>_<uuid><ext>": xcresulttool reads the attachment
        # name's last ".xxx" as an extension ("places.map" → "places_0_<uuid>.map")
        m = re.match(r"^(.*)_\d+_[0-9A-Fa-f-]{36}(\.[^.]+)?$", a.get("suggestedHumanReadableName", ""))
        if not m:
            continue
        name = (m.group(1) + (m.group(2) or "")).removesuffix(".png")
        folder = dst / a.get("configurationName", "default")
        folder.mkdir(parents=True, exist_ok=True)
        shutil.copy(src / a["exportedFileName"], folder / f"{name}.png")
        count += 1
print(f"  {count} screenshots")
EOF
}

# APPSTORE_SHOTS of every configuration → Screenshots/appstore/<configuration>/NN_<shot>.png, framed
processAppstore() {
    local config lang shot text index
    echo "▸ App Store (framed)"
    (( PARTIAL )) || rm -rf "$OUT/appstore"
    for config in "$RAW"/*(/N); do
        lang=${config:t}
        mkdir -p "$OUT/appstore/$lang"
        index=0
        for shot in $APPSTORE_SHOTS; do
            index=$(( index + 1 ))
            if [[ ! -f "$config/$shot.png" ]]; then
                (( PARTIAL )) || { echo "  ✗ missing $lang/$shot" >&2; MISSING=1 }
                continue
            fi
            if ! text=$(caption "$shot" "$lang"); then
                echo "  ✗ no caption for $shot in ${CAPTIONS:t}" >&2; MISSING=1; continue
            fi
            frameShot "$config/$shot.png" "$text" "$OUT/appstore/$lang/$(printf %02d $index)_$shot.png"
            WRITTEN+=("$OUT/appstore/$lang/$(printf %02d $index)_$shot.png")
        done
    done
}

# Screenshots/appstore/<configuration>/NN_<shot>.png → fastlane/screenshots/<locale>/N_<shot>.png
# deliver uploads them in file name order, its device type comes from the image size
processFastlane() {
    local config lang locale file
    echo "▸ fastlane"
    for config in "$OUT/appstore"/*(/N); do
        lang=${config:t}
        locale=${FASTLANE_LOCALES[$lang]:-}
        if [[ -z "$locale" ]]; then
            echo "  ✗ no locale for configuration '$lang' in FASTLANE_LOCALES" >&2; MISSING=1; continue
        fi
        (( PARTIAL )) || rm -rf "$FASTLANE_SCREENSHOTS/$locale"   # only the locales generated here, other folders are kept
        mkdir -p "$FASTLANE_SCREENSHOTS/$locale"
        for file in "$config"/*.png(N); do
            # Partial: only the shots of this run (the others were framed by a previous run)
            (( PARTIAL )) && [[ ! -f "$RAW/$lang/${${${file:t}#[0-9][0-9]_}%.png}.png" ]] && continue
            cp "$file" "$FASTLANE_SCREENSHOTS/$locale/${${file:t}#0}"   # 01_places.map.png → 1_places.map.png
            WRITTEN+=("$FASTLANE_SCREENSHOTS/$locale/${${file:t}#0}")
        done
    done
}

# WEBSITE_SHOTS of every configuration → Screenshots/website/<configuration>/<file name>.webp, resized
# (the site's pages load /assets/screens/<language>/<file name>.webp)
processWeb() {
    local config lang entry shot name width height src
    echo "▸ Website (webp q$WEBP_QUALITY)"
    (( PARTIAL )) || rm -rf "$OUT/website"
    for config in "$RAW"/*(/N); do
        lang=${config:t}
        mkdir -p "$OUT/website/$lang"
        for entry in $WEBSITE_SHOTS; do
            read -r shot name width height <<< "$entry"
            src="$config/$shot.png"
            if [[ -f "$src" ]]; then
                cwebp -quiet -q $WEBP_QUALITY -resize $width $height "$src" -o "$OUT/website/$lang/$name.webp"
                WRITTEN+=("$OUT/website/$lang/$name.webp")
            elif (( ! PARTIAL )); then
                echo "  ✗ missing $lang/$shot (for $name)" >&2; MISSING=1
            fi
        done
    done
}

# Exported shots in neither APPSTORE_SHOTS nor WEBSITE_SHOTS: they produce no file
warnUnusedShots() {
    local file shot entry
    local -a used unused
    used=($APPSTORE_SHOTS ${WEBSITE_SHOTS%% *})
    for file in "$RAW"/*/*.png(N); do
        shot=${file:t:r}
        (( ${used[(Ie)$shot]} )) || unused+=("$shot")
    done
    unused=(${(u)unused})
    (( ${#unused} )) || return 0
    echo "▸ Not in APPSTORE_SHOTS nor WEBSITE_SHOTS (no file written):"
    for shot in $unused; do echo "  - $shot"; done
}

# README_SHOTS → Screenshots/readme/<file name>.webp, from Screenshots/website/README_LANGUAGE
processReadme() {
    local name src
    echo "▸ README"
    (( PARTIAL )) || rm -rf "$OUT/readme"
    mkdir -p "$OUT/readme"
    for name in $README_SHOTS; do
        src="$OUT/website/$README_LANGUAGE/$name.webp"
        if (( PARTIAL )); then
            # Partial: only the website files of this run
            (( ${WRITTEN[(Ie)$src]} )) || continue
        elif [[ ! -f "$src" ]]; then
            echo "  ✗ missing $README_LANGUAGE/$name" >&2; MISSING=1; continue
        fi
        cp "$src" "$OUT/readme/$name.webp"
        WRITTEN+=("$OUT/readme/$name.webp")
    done
}

# MARK: - App Store helpers

# caption <shot> <language>: from AppStoreCaptions.xcstrings, en as fallback;
# split in 2 balanced lines when wider than CAPTION_MAX_WIDTH
caption() {
    local text width
    text=$(python3 -I - "$CAPTIONS" "$1" "$2" <<'EOF'
import json, sys
strings = json.load(open(sys.argv[1]))["strings"]
locs = strings.get(sys.argv[2], {}).get("localizations", {})
unit = (locs.get(sys.argv[3]) or locs.get("en") or {}).get("stringUnit", {})
print(unit.get("value", ""))
EOF
)
    [[ -n "$text" ]] || return 1
    width=$(magick -background none -font "$CAPTION_FONT" -pointsize $CAPTION_POINTSIZE label:"$text" -format "%w" info:)
    if (( width > CAPTION_MAX_WIDTH )); then
        text=$(python3 -I -c '
import sys
words = sys.argv[1].split(" ")
i = min(range(1, len(words)), key=lambda i: abs(len(" ".join(words[:i])) - len(" ".join(words[i:]))))
print(" ".join(words[:i]) + "\n" + " ".join(words[i:]))' "$text")
    fi
    print -r -- "$text"
}

# frameShot <shot.png> <caption> <out.png>
# Separate magick calls: a single combined one crashes ImageMagick 7.1.2 (SIGABRT)
frameShot() {
    local w=$FRAME_SIZE[1] h=$FRAME_SIZE[2] tmp="$WORK/frame"
    local sw=$(( w * SHOT_SCALE / 100 )) sh=$(( h * SHOT_SCALE / 100 ))
    local b=$SHOT_BORDER
    local bw=$(( sw + 2 * b )) bh=$(( sh + 2 * b )) br=$(( SHOT_RADIUS + b ))
    mkdir -p "$tmp"
    # Screenshot with rounded corners
    magick -size ${sw}x${sh} xc:black -fill white \
        -draw "roundrectangle 0,0 $((sw - 1)),$((sh - 1)) $SHOT_RADIUS,$SHOT_RADIUS" "$tmp/mask.png"
    magick "$1" -resize ${sw}x${sh}! "$tmp/mask.png" -alpha off -compose CopyOpacity -composite "$tmp/rounded.png"
    # Border outside the screenshot (never over the UI): ring of radius SHOT_RADIUS + b, screenshot on top
    magick -size ${bw}x${bh} xc:none -fill "$SHOT_BORDER_COLOR" \
        -draw "roundrectangle 0,0 $((bw - 1)),$((bh - 1)) $br,$br" PNG32:"$tmp/plate.png"   # PNG32: a white-only plate would be saved gray, turning the shot gray
    magick "$tmp/plate.png" "$tmp/rounded.png" -geometry +${b}+${b} -compose Over -composite PNG32:"$tmp/bordered.png"
    magick "$tmp/bordered.png" \( +clone -background "#1E3A3A" -shadow $SHOT_SHADOW \) +swap \
        -background none -layers merge +repage PNG32:"$tmp/shot.png"
    magick -background none -fill "$CAPTION_COLOR" -font "$CAPTION_FONT" -pointsize $CAPTION_POINTSIZE \
        -gravity center label:"$2" -extent ${w}x${SHOT_TOP} "$tmp/caption.png"
    # The screenshot itself starts at SHOT_TOP: shift up by the border and the shadow margin
    magick -size ${w}x${h} xc:"$FRAME_BACKGROUND" \
        "$tmp/caption.png" -gravity north -geometry +0+0 -compose Over -composite \
        "$tmp/shot.png" -gravity north -geometry +0+$(( SHOT_TOP - b - SHOT_SHADOW_MARGIN )) -compose Over -composite \
        -alpha off "$3"
}

# MARK: - Main

# The header comment of this script
usage() {
    sed -n '2,/^[^#]/p' "$SCRIPT" | sed -e '$d' -e 's/^# \{0,1\}//'
    echo "Tests (--test):"
    sed -n 's/^ *func \(test[A-Za-z0-9_]*\)(.*/  \1/p' "$TESTS_FILE"
    echo "Configurations (--config):"
    python3 -I -c 'import json, sys; print("\n".join("  " + c["name"] for c in json.load(open(sys.argv[1]))["configurations"]))' "$TEST_PLAN"
}

main() {
    local reuse=0 test config=""
    local -a tests=()
    while (( $# )); do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --reuse) reuse=1 ;;
            --test) [[ -n "${2:-}" ]] || { echo "--test needs a test method name" >&2; exit 1; }
                    tests+=("$2"); shift ;;
            --config) [[ -n "${2:-}" ]] || { echo "--config needs a configuration name" >&2; exit 1; }
                      config="$2"; shift ;;
            *) echo "Unknown argument: $1" >&2; exit 1 ;;
        esac
        shift
    done

    # Partial run: --test / --config
    FILTER_ARGS=()
    PARTIAL=0
    if (( ${#tests} )) || [[ -n "$config" ]]; then
        (( reuse )) && { echo "--reuse can't be combined with --test / --config" >&2; exit 1; }
        PARTIAL=1
    fi
    for test in $tests; do
        grep -q "func $test(" "$TESTS_FILE" || { echo "No test '$test' in ${TESTS_FILE#$ROOT/}" >&2; exit 1; }
        FILTER_ARGS+=("-only-testing:DropinScreenshots/DropinScreenshots/$test")
    done
    if [[ -n "$config" ]]; then
        grep -q "\"name\" : \"$config\"" "$TEST_PLAN" || { echo "No configuration '$config' in ${TEST_PLAN#$ROOT/}" >&2; exit 1; }
        FILTER_ARGS+=("-only-test-configuration" "$config")
    fi

    command -v cwebp >/dev/null || { echo "cwebp not found: brew install webp" >&2; exit 1; }
    command -v magick >/dev/null || { echo "magick not found: brew install imagemagick" >&2; exit 1; }
    [[ -f "$CAPTION_FONT" ]] || { echo "Font not found: $CAPTION_FONT (SF Pro: developer.apple.com/fonts)" >&2; exit 1; }

    WORK="$(mktemp -d)"
    RAW="$WORK/raw"
    trap 'rm -rf "$WORK"' EXIT
    TEST_STATUS=0
    MISSING=0
    WRITTEN=()

    if (( reuse )); then
        [[ -d "$RESULT" ]] || { echo "No ${RESULT#$ROOT/} to reuse" >&2; exit 1; }
        echo "▸ Reusing ${RESULT#$ROOT/}"
    else
        runScreenshotsScheme
    fi
    retrieveSnapshots
    processAppstore
    processFastlane
    processWeb
    processReadme
    warnUnusedShots

    echo "▸ Done → $OUT"
    if (( PARTIAL )); then
        # Only the files of this run
        (( ${#WRITTEN} )) || echo "  nothing written"
        print -l -- $WRITTEN | sort | sed "s|^$ROOT/||"
    else
        find "$OUT/appstore" "$OUT/website" "$OUT/readme" "$FASTLANE_SCREENSHOTS" -type f -name "*.*" | sort | sed "s|^$ROOT/||"
    fi
    (( TEST_STATUS == 0 && MISSING == 0 )) || exit 1
}

main "$@"
