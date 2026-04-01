#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- defaults ---
APP_URL=""
APP_NAME=""
ICON_PATH=""
WINDOW_WIDTH=1200
WINDOW_HEIGHT=800

usage() {
  cat <<EOF
Usage: $(basename "$0") --url <URL> --name <APP_NAME> [OPTIONS]

Build a macOS .app bundle that wraps a URL in a native Tauri window.

Required:
  --url   <URL>          The URL to load in the app window
  --name  <APP_NAME>     Display name of the app (e.g. "My App")

Optional:
  --icon  <PATH>         Path to a PNG icon (1024x1024 recommended)
  --width <PIXELS>       Window width (default: 1200)
  --height <PIXELS>      Window height (default: 800)
  -h, --help             Show this help message

Examples:
  ./build.sh --url http://localhost:4096 --name "OpenCode WebUI"
  ./build.sh --url https://example.com --name "Example" --icon ./myicon.png
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

# --- build ---
echo ""
echo "==> Running: cargo tauri build"
cd "${SCRIPT_DIR}/src-tauri"
cargo tauri build

# --- report output ---
DMG_PATH=$(find "${SCRIPT_DIR}/src-tauri/target/release/bundle/dmg" -name '*.dmg' 2>/dev/null | head -1)
APP_PATH=$(find "${SCRIPT_DIR}/src-tauri/target/release/bundle/macos" -name '*.app' 2>/dev/null | head -1)

echo ""
echo "==> Build complete!"
[[ -n "${APP_PATH:-}" ]] && echo "    .app: ${APP_PATH}"
[[ -n "${DMG_PATH:-}" ]] && echo "    .dmg: ${DMG_PATH}"
