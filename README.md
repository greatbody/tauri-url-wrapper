# tauri-url-wrapper

Wrap any URL into a native desktop app (macOS / Windows / Linux) using [Tauri](https://tauri.app). Give it a URL and a name, get a ready-to-run app — including a **single-file portable `.exe` for Windows** that needs no installation.

The app window title shows realtime memory and CPU usage of the process.

## Two ways to use it

### 1. Build via GitHub Actions (recommended, no local toolchain needed)

The repo ships a `workflow_dispatch` pipeline that builds all three platforms on demand from a form.

1. Open the repo on GitHub → **Actions** tab → **Build URL Wrapper**
2. Click **Run workflow** and fill in:

   | Input | Required | Description |
   |-------|----------|-------------|
   | `app_url` | yes | URL the app loads (e.g. `https://example.com`) |
   | `app_name` | yes | Display name. Used for window title, `productName`, and the exe file name |
   | `app_version` | yes | Semver string (default `0.1.0`) |
   | `icon_url` | no | URL to a PNG (≥512×512). Falls back to the repo default icon |
   | `window_width` | no | Default `1200` |
   | `window_height` | no | Default `800` |

3. Wait for the matrix build to finish, then download artifacts from the run page (kept for 14 days):

   | Platform | Artifact contents |
   |----------|-------------------|
   | `windows-latest` | `<AppName>-portable.exe` — single-file, no installer, no registry |
   | `macos-latest` | `.dmg` + zipped `.app` (universal arm64 + x86_64) |
   | `ubuntu-22.04` | `.AppImage` + `.deb` |

#### About the Windows portable exe

It is the raw Cargo-compiled binary, not an NSIS/MSI installer. Just copy and run.

- Requires **Microsoft Edge WebView2 Runtime** (preinstalled on Windows 10 21H2+ and Windows 11; one-time download on older systems).
- Unsigned, so SmartScreen may warn on first launch.

### 2. Build locally (macOS only, via the helper script)

```bash
./build.sh --url <URL> --name <APP_NAME> [OPTIONS]
```

#### Required

| Flag | Description |
|------|-------------|
| `--url <URL>` | The URL to load in the app window |
| `--name <APP_NAME>` | Display name of the app |

#### Optional

| Flag | Description |
|------|-------------|
| `--icon <PATH>` | Path to a PNG icon (1024×1024 recommended) |
| `--width <PIXELS>` | Window width (default: 1200) |
| `--height <PIXELS>` | Window height (default: 800) |
| `--install` | Copy the built `.app` to `/Applications` |

#### Examples

```bash
./build.sh --url http://localhost:4096 --name "OpenCode WebUI"
./build.sh --url https://example.com --name "My App" --icon ./logo.png --install
```

#### Output

```
src-tauri/target/release/bundle/macos/  # .app
src-tauri/target/release/bundle/dmg/    # .dmg
```

#### Prerequisites for local builds

- [Rust](https://rustup.rs/)
- [Tauri CLI](https://tauri.app/start/): `cargo install tauri-cli`

## License

[MIT](LICENSE)
