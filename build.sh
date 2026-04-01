#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- defaults ---
APP_URL=""
APP_NAME=""
ICON_PATH=""
WINDOW_WIDTH=1200
WINDOW_HEIGHT=800
INSTALL=false

usage() {
  cat <<EOF
Usage: $(basename "$0") --url <URL> --name <APP_NAME> [OPTIONS]

Build a macOS .app bundle that wraps a URL in a native Tauri window.

Required:
  --url   <URL>          The URL to load in the app window
  --name  <APP_NAME>     Display name of the app (e.g. "My App")

Optional:
  --icon    <PATH>         Path to a PNG icon (1024x1024 recommended)
  --width   <PIXELS>       Window width (default: 1200)
  --height  <PIXELS>       Window height (default: 800)
  --install                Copy the built .app to /Applications after build
  -h, --help               Show this help message

Examples:
  ./build.sh --url http://localhost:4096 --name "OpenCode WebUI"
  ./build.sh --url https://example.com --name "Example" --icon ./myicon.png --install
EOF
  exit 0
}

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)    APP_URL="$2"; shift 2 ;;
    --name)   APP_NAME="$2"; shift 2 ;;
    --icon)   ICON_PATH="$2"; shift 2 ;;
    --width)  WINDOW_WIDTH="$2"; shift 2 ;;
    --height) WINDOW_HEIGHT="$2"; shift 2 ;;
    --install) INSTALL=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$APP_URL" || -z "$APP_NAME" ]]; then
  echo "Error: --url and --name are required."
  echo ""
  usage
fi

# Derive a slug from the app name for crate name / identifier
APP_SLUG="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
APP_IDENTIFIER="com.greatbody.${APP_SLUG}"

echo "==> Building: ${APP_NAME}"
echo "    URL:        ${APP_URL}"
echo "    Slug:       ${APP_SLUG}"
echo "    Identifier: ${APP_IDENTIFIER}"
echo "    Window:     ${WINDOW_WIDTH}x${WINDOW_HEIGHT}"

# --- generate dist/index.html ---
cat > "${SCRIPT_DIR}/dist/index.html" <<EOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>${APP_NAME}</title></head>
<body><p>Loading...</p></body>
</html>
EOF

# --- generate tauri.conf.json ---
cat > "${SCRIPT_DIR}/src-tauri/tauri.conf.json" <<EOF
{
  "productName": "${APP_NAME}",
  "version": "0.1.0",
  "identifier": "${APP_IDENTIFIER}",
  "build": {
    "frontendDist": "../dist",
    "devUrl": "${APP_URL}"
  },
  "bundle": {
    "icon": ["icons/icon.icns", "icons/icon.png"]
  },
  "app": {
    "windows": [
      {
        "title": "${APP_NAME}",
        "url": "${APP_URL}",
        "width": ${WINDOW_WIDTH},
        "height": ${WINDOW_HEIGHT},
        "resizable": true,
        "fullscreen": false
      }
    ],
    "security": {
      "csp": null
    }
  }
}
EOF

# --- generate Cargo.toml ---
cat > "${SCRIPT_DIR}/src-tauri/Cargo.toml" <<EOF
[package]
name = "${APP_SLUG}"
version = "0.1.0"
edition = "2024"

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = [] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sysinfo = "0.35"
EOF

# --- copy icon if provided ---
if [[ -n "$ICON_PATH" ]]; then
  if [[ ! -f "$ICON_PATH" ]]; then
    echo "Error: Icon file not found: ${ICON_PATH}"
    exit 1
  fi
  echo "    Icon:       ${ICON_PATH}"
  cp "$ICON_PATH" "${SCRIPT_DIR}/src-tauri/icons/icon.png"
fi

# --- generate .icns from icon.png ---
echo ""
echo "==> Generating icon.icns..."
ICONSET_DIR=$(mktemp -d)/icon.iconset
mkdir -p "$ICONSET_DIR"
ICON_SRC="${SCRIPT_DIR}/src-tauri/icons/icon.png"
sips -z 16 16     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png"      > /dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png"      > /dev/null
sips -z 64 64     "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png"    > /dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png"    > /dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null
iconutil -c icns "$ICONSET_DIR" -o "${SCRIPT_DIR}/src-tauri/icons/icon.icns"
rm -rf "$(dirname "$ICONSET_DIR")"
echo "    Generated: src-tauri/icons/icon.icns"

# --- build ---
echo ""
echo "==> Running: cargo tauri build --bundles app"
cd "${SCRIPT_DIR}/src-tauri"
cargo tauri build --bundles app

# --- report output ---
APP_PATH=$(find "${SCRIPT_DIR}/src-tauri/target/release/bundle/macos" -name '*.app' 2>/dev/null | head -1 || true)
DMG_PATH=$(find "${SCRIPT_DIR}/src-tauri/target/release/bundle/dmg" -name '*.dmg' 2>/dev/null | head -1 || true)

echo ""
echo "==> Build complete!"
[[ -n "${APP_PATH:-}" ]] && echo "    .app: ${APP_PATH}" || true
[[ -n "${DMG_PATH:-}" ]] && echo "    .dmg: ${DMG_PATH}" || true

# --- install ---
if [[ "$INSTALL" == true && -n "${APP_PATH:-}" ]]; then
  echo ""
  echo "==> Installing to /Applications..."
  DEST="/Applications/$(basename "$APP_PATH")"
  if [[ -d "$DEST" ]]; then
    echo "    Removing existing: ${DEST}"
    rm -rf "$DEST"
  fi
  cp -R "$APP_PATH" /Applications/
  echo "    Installed: ${DEST}"
fi
