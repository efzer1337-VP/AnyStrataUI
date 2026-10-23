# AnyStrataUI

**One native-feeling Windows desktop app with the original Strata visual experience, PolyStrata inference, and a Hugging Face model browser.**

```
Product formula = Original Strata UI/UX + PolyStrata inference + Hugging Face model browser + hardware-aware model management
```

Builds on two upstream projects (both MIT-licensed):

- **Strata** — https://github.com/Niko1221/Strata — UI, navigation, styling, hardware-aware recommendation flow.
- **PolyStrata** — https://github.com/VecSzn/PolyStrata — expanded engine / model support, inference engines.

Upstream commits, exact licenses and attribution are recorded next to each submodule (`vendor/strata/`, `vendor/polystrata/`).

---

## What it does

- Opens one Strata-looking desktop app (Tauri + React + Vite).
- Shows the familiar **Recommended** model list with quantizations, memory estimates, download sizes.
- **Hugging Face Search** — search by name / author / repository / URL, filter for **Uncensored / Abliterated**, browse real GGUF files, quantizations, shards, sizes.
- **Smart suitability** — detect actual hardware at runtime, estimate weights / VRAM / RAM / KV cache, rate models *Excellent / Good / Limited / Not recommended / Unsupported / Unknown*.
- **Lifecycle** — search → inspect → choose GGUF → validate → download → register → load → chat → unload, without leaving the app.
- Streams replies through the correct PolyStrata engine.

---

## Repository layout

```
PolyStrataUI/
├── AGENTS.md                 # engineering rules for agents
├── GOAL.md                   # authoritative product spec
├── README.md                 # this file
├── build/
│   ├── polystrata-host/      # React UI (Vite) + API server (Node)  ← the app
│   │   ├── dist/             # built UI (npm run build)
│   │   ├── server/           # index.mjs, catalog, engine wiring
│   │   ├── src/              # React source
│   │   ├── tests/            # 970+ node:test suites (npm test)
│   │   └── package.json
│   └── polystrata-desktop/   # Tauri desktop app (Rust) → produces the .exe
│       ├── src-tauri/        # Rust app, tauri.conf.json, nsis/ (NSIS installer)
│       └── package.json      # "tauri build" → .exe (NSIS) / .app / .dmg
├── vendor/
│   ├── strata/               # upstream Strata engine (submodule, MIT)
│   └── polystrata/           # upstream PolyStrata engine (submodule, MIT)
└── packaging/                # acceptance matrix, build helpers, feeds
```

---

## Prerequisites (Windows 11)

| Tool | Why | Minimum |
| --- | --- | --- |
| **Node.js** | UI build, API server, tests | 20+ |
| **npm** | package management | 10+ |
| **Rust toolchain** | Tauri desktop app → `.exe` | `rustc` + `cargo` |
| **PowerShell 5.1+** | installer + launch helpers | built into Windows 11 |
| **Visual Studio Build Tools** | native deps for Rust | MSVC x64 workload |
| *(optional)* **Python 3.10+** | Strata control scripts | for model management |

> A discrete NVIDIA or AMD graphics card (RTX 4080-class / newer) is recommended for GPU inference. The desktop app runs on integrated graphics too, just slower.

---

## Quick install

### 1. Clone the repo

```powershell
git clone https://github.com/efzer1337-VP/AnyStrataUI.git
cd AnyStrataUI
```

### 2. Install UI + desktop dependencies

```powershell
npm install --prefix build\polystrata-host
npm install --prefix build\polystrata-desktop
```

### 3. Build the UI

```powershell
npm --prefix build\polystrata-host run build
```

### 4. Build the desktop app → `.exe` installer

```powershell
cd build\polystrata-desktop
npm run build
```

The `NSIS` installer (`.exe`) lands in:

```
build\polystrata-desktop\src-tauri\target\release\bundle\nsis\AnyStrata-<version>-x64-setup.exe
```

> Build time the first time is ~10–20 min (Rust compilation). Later runs are incremental.

### 5. Run the installer

Double-click the generated `AnyStrata-*-x64-setup.exe`. It installs to:

```
%LOCALAPPDATA%\AnyStrata\
```

After install, launch from the Start menu or run:

```powershell
& "$env:LOCALAPPDATA\AnyStrata\bin\anystrata.cmd" launch
```

---

## Running from source (no installer)

```powershell
# from the repo root
cd build\polystrata-desktop
npm run dev
```

`npm run dev` builds the UI then launches Tauri in dev mode. For production bundle without opening a dev window:

```powershell
npm run build
```

---

## Running the tests

```powershell
cd build\polystrata-host
npm test
```

- **~970 tests** across the host UI + API server + model-management + HF discovery.
- The Tauri desktop app builds and type-checks cleanly.
- Model *inference* (real GGUF load + chat) is intentionally **not** part of the automated suite — install the app first, then load one of the recommended models to verify end-to-end.

---

## Using the app

1. Launch AnyStrata.
2. Open **Recommended** to see the curated models, or open **Hugging Face Search**.
3. Search by name / author / repository; toggle **Uncensored / Abliterated** when you want fine-tunes.
4. Click a model to inspect its real GGUF files, quantizations, shards, sizes, and hardware-aware suitability.
5. **Download** or **import** an existing local GGUF.
6. **Load** it through the correct engine, **chat**, monitor performance, and **switch/unload**.

The first time you pick a model, the app fetches the right inference engine for your graphics card from the release folder.

---

## Packaging & feeds (advanced)

- `packaging/acceptance_matrix.py` — the full acceptance matrix (status counts, pass/fail).
- `packaging/install.ps1` / `install.sh` — one-line installers (PowerShell 5.1+ / bash).
- `packaging/package_engine.py`, `package_terminal.py` — engine & terminal archiving.
- Set `$env:STRATA_FEED` to a URL or local path to point installers at a custom release folder.

---

## Configuration

All settings live under `%LOCALAPPDATA%\AnyStrata\`:

- `config.json` — default engine, context length, backend, temperature.
- `models/` — downloaded / imported GGUF files.
- `logs/` — app logs.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `npm run build` fails on native deps | Install *Visual Studio Build Tools* (MSVC x64 workload). |
| UI builds but app won't launch | Re-run `npm --prefix build\polystrata-host run build` to regenerate `dist/`. |
| `.exe` too long error | Set `$env:STRATA_DATA_DIR` to a short path like `C:\AnyStrata`. |
| `git submodule` empty after clone | Run `git submodule update --init --recursive`. |
| Model won't load | Open **Recommended**, pick a model sized for your VRAM, or import a compatible local GGUF. |

---

## License & attribution

- **Strata** — https://github.com/Niko1221/Strata — **MIT** (source: `vendor/strata/`).
- **PolyStrata** — https://github.com/VecSzn/PolyStrata — **MIT** (source: `vendor/polystrata/`).

Exact upstream commit IDs, license notices, and attribution for code, bundled assets, binaries, and models are recorded inside each vendor folder and in `packaging/`.

---

## Development roadmap (see `GOAL.md`)

- Advanced model ranking and broader family discovery.
- Detailed live performance / KV-cache monitoring.
- Precise context-dependent memory estimation.
- Advanced GPU offloading, batch, and KV-cache controls for engines that implement them.
- Improved background download recovery and local cache management.
- Polished Windows installer / portable distribution and automated compatibility regression tests.
