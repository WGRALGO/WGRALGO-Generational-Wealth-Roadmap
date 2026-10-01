#!/usr/bin/env bash
# Generational Wealth Roadmap — release validation.
# Usage: ./tools/validate-release.sh [path/to/app.apk]
# Exit non-zero if any check fails.
set -u
cd "$(dirname "$0")/.."

VERSION=$(node -p "require('./package.json').version")
CODE=$(echo "$VERSION" | awk -F. '{ print $1*100 + $2*10 + $3 }')

PASS=0
FAIL=0
ok()  { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

echo "== Game data =="
OUT=$(node - <<'NODE'
const fs = require("fs");
const h = fs.readFileSync("www/index.html", "utf8");
const R = (ok, msg) => console.log((ok ? "PASS " : "FAIL ") + msg);
const grab = name => {
  const m = h.match(new RegExp("const " + name + " = \\[([\\s\\S]*?)\\n    \\];"));
  return m ? eval("[" + m[1] + "]") : null;
};
const chars = grab("CHARACTERS"), stages = grab("STAGES"), decs = grab("DECISIONS"), prot = grab("PROTECTIONS");
if (!chars || !stages || !decs || !prot) { console.log("FAIL game data not found"); process.exit(0); }
R(chars.length === 3, chars.length + " starting characters");
R(stages.length === 5, stages.length + " life stages");
R(decs.every(d => d.title && d.q && Array.isArray(d.o) && d.o.length >= 2 &&
  d.o.every(o => o[0] && typeof o[1] === "number" && o[1] >= 0 && o[1] <= 10 && o[2] && o[3])),
  decs.length + " decisions, each with explained choices scored 0-10");
R(chars.every(c => decs.some(d => d.stage === 1 && !d.event && d.who === c.id)), "every character has its own stage-1 path");
R(decs.some(d => d.stage === 1 && !d.event && !d.who), "stage 1 has a shared decision");
R([2, 3, 4].every(s => decs.some(d => d.stage === s && !d.event)), "stages 2-4 each have planned decisions");
R(decs.filter(d => d.event).length >= 3, decs.filter(d => d.event).length + " life events (at least 3)");
R(decs.some(d => d.title === "Updating your estate plan") && decs.some(d => d.stage === 5 && d.title !== "Updating your estate plan"), "stage 5 has the estate plan plus another decision");
R(new Set(decs.map(d => d.title)).size === decs.length, "no duplicate decision titles");
R(/window\.onAndroidBack = function/.test(h), "Android back button hook present");
NODE
)
while IFS= read -r line; do
  case "$line" in
    PASS*) ok "${line#PASS }" ;;
    FAIL*) bad "${line#FAIL }" ;;
  esac
done <<< "$OUT"

echo "== Version $VERSION (code $CODE) =="
GR=android/app/build.gradle
grep -q "versionName \"$VERSION\"" $GR && ok "versionName $VERSION" || bad "versionName is not $VERSION"
grep -q "versionCode $CODE" $GR && ok "versionCode $CODE" || bad "versionCode is not $CODE"
grep -q "v$VERSION" www/index.html && ok "app shows v$VERSION" || bad "app does not show v$VERSION"
grep -q "$VERSION" README.md && ok "README mentions $VERSION" || bad "README missing $VERSION"
[ -f "release-notes/v$VERSION.md" ] && ok "release-notes/v$VERSION.md present" || bad "release-notes/v$VERSION.md missing"

echo "== Build config =="
grep -q 'applicationId "org.wgralgo.generationalwealthroadmap"' $GR && ok "appId org.wgralgo.generationalwealthroadmap" || bad "appId wrong"
grep -q 'debuggable false' $GR && ok "release debuggable false" || bad "release not debuggable false"
grep -q 'minifyEnabled true' $GR && ok "minify enabled" || bad "minify not enabled"
MAN=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET" tools:node="remove"' $MAN && ok "INTERNET permission stripped" || bad "INTERNET permission not stripped"

echo "== Logo, icon, splash =="
RES=android/app/src/main/res
[ -f "$RES/drawable-nodpi/splash_icon.jpg" ] && ok "Android 12+ splash logo present" || bad "splash_icon.jpg missing"
grep -q 'windowSplashScreenAnimatedIcon">@drawable/splash_icon' $RES/values/styles.xml && ok "system splash uses the logo" || bad "system splash not set to the logo"
grep -q 'windowSplashScreenBackground">@android:color/black' $RES/values/styles.xml && ok "system splash background is black" || bad "system splash background not black"
grep -q '#000000' $RES/values/ic_launcher_background.xml && ok "icon background is black" || bad "icon background not black"
[ -f www/logo.jpg ] && ok "in-app logo present" || bad "in-app logo missing"

echo "== App privacy =="
IDX=www/index.html
grep -qi 'Content-Security-Policy' $IDX && ok "CSP present" || bad "CSP missing"
grep -Eqi 'href="(https?:)?//|href="/|src="https?://|@import' $IDX && bad "external link or resource in app" || ok "no external links or resources"
grep -Eqi 'gofundme\.com|facebook\.com|instagram\.com|tiktok\.com|youtube\.com' $IDX && bad "donation/social link in app" || ok "no donation or social links"
grep -Eqi 'google-analytics|googletagmanager|gtag\(|firebase|admob' $IDX && bad "analytics/ads reference" || ok "no analytics or ads"
grep -Eq 'localStorage|sessionStorage|indexedDB|document\.cookie' $IDX && bad "app stores data on device" || ok "no on-device storage"

echo "== License =="
grep -q '"license": "GPL-3.0-or-later"' package.json && ok "package.json license GPL-3.0-or-later" || bad "package.json license not GPL-3.0-or-later"
grep -q 'GNU GENERAL PUBLIC LICENSE' LICENSE && ok "LICENSE is GPLv3" || bad "LICENSE is not GPLv3"

echo "== Name and orientation =="
grep -q '<string name="app_name">WGRALGO' android/app/src/main/res/values/strings.xml && bad "app name under the icon starts with WGRALGO" || ok "app name under the icon has no WGRALGO prefix"
grep -q 'screenOrientation' android/app/src/main/AndroidManifest.xml && bad "orientation is locked" || ok "rotates freely (portrait and landscape)"
grep -q 'WGRALGO-[A-Za-z]*-v' .github/workflows/release.yml && ok "APK named WGRALGO-<AppName>-v<version>.apk" || bad "APK name not uniform"

if [ "${1:-}" != "" ] && [ -f "${1:-}" ]; then
  APK="$1"
  echo "== APK: $APK =="
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
  BT=$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)
  if [ -x "$BT/aapt2" ]; then
    DUMP=$("$BT/aapt2" dump badging "$APK" 2>/dev/null)
    echo "$DUMP" | grep -q "versionName='$VERSION'" && ok "APK versionName $VERSION" || bad "APK versionName wrong"
    echo "$DUMP" | grep -q "versionCode='$CODE'" && ok "APK versionCode $CODE" || bad "APK versionCode wrong"
    echo "$DUMP" | grep -q "package: name='org.wgralgo.generationalwealthroadmap'" && ok "APK package id" || bad "APK package id wrong"
    echo "$DUMP" | grep -q "uses-permission: name='android.permission.INTERNET'" && bad "APK declares INTERNET" || ok "APK has no INTERNET permission"
  else
    bad "aapt2 not found"
  fi
  if [ -x "$BT/apksigner" ]; then
    CERT=$("$BT/apksigner" verify --print-certs "$APK" 2>/dev/null)
    echo "$CERT" | grep -qi "CN=Android Debug" && bad "APK signed with debug cert" || ok "APK not signed with debug cert"
    "$BT/apksigner" verify "$APK" >/dev/null 2>&1 && ok "APK signature verifies" || bad "APK signature invalid/unsigned"
  else
    bad "apksigner not found"
  fi
else
  echo "== APK checks skipped (no APK path given) =="
fi

echo
echo "RESULT: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
