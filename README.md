# tauri-url-wrapper

Wrap any URL into a native macOS app using [Tauri](https://tauri.app). Give it a URL and a name, get a `.app` bundle.

The app window title shows realtime memory and CPU usage of the process.

## Prerequisites

- [Rust](https://rustup.rs/)
- [Tauri CLI](https://tauri.app/start/): `cargo install tauri-cli`

## Usage

```bash
./build.sh --url <URL> --name <APP_NAME> [OPTIONS]
```

### Required

| Flag | Description |
|------|-------------|
| `--url <URL>` | The URL to load in the app window |
| `--name <APP_NAME>` | Display name of the app |

### Optional

| Flag | Description |
|------|-------------|
| `--icon <PATH>` | Path to a PNG icon (1024x1024 recommended) |
| `--width <PIXELS>` | Window width (default: 1200) |
| `--height <PIXELS>` | Window height (default: 800) |
| `--install` | Copy the built `.app` to `/Applications` |

### Examples

```bash
# Build an app
./build.sh --url http://localhost:4096 --name "OpenCode WebUI"

# Build with custom icon and install to /Applications
./build.sh --url https://example.com --name "My App" --icon ./logo.png --install
```

## Output

After a successful build, the `.app` and `.dmg` are located in:

```
src-tauri/target/release/bundle/macos/  # .app
src-tauri/target/release/bundle/dmg/    # .dmg
```

## License

[MIT](LICENSE)
