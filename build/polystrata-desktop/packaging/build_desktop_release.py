#!/usr/bin/env python3
"""Build a desktop release folder for AnyStrata UI: the NSIS setup, a portable ZIP,
checksums, and an install-manifest.txt that install_desktop.ps1 reads.

    python packaging/build_desktop_release.py --version 0.2.3 --out <release folder>

The engine and the model are not part of this. The EXE is bundled with its own Node
runtime (see tauri.conf.json) and is self-contained; `strata launch` inside it fetches
the engine for the user's graphics card from the same release folder, signed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "src-tauri" / "target" / "release"

MANIFEST_KEYS = ("exe", "sha256", "size", "version", "platform", "portable", "portable_sha256")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_portable_zip(exe: Path, out_dir: Path, version: str) -> tuple[Path, str, str]:
    """Bundle the EXE + its resources + a portable launcher into <out_dir>/AnyStrata_<version>_portable.zip."""
    name = f"AnyStrata_{version}_portable.zip"
    zip_path = out_dir / name
    port_dir = out_dir / "_portable_src"
    shutil.copytree(exe.parent, port_dir / "AnyStrata", dirs_exist_ok=True)
    (port_dir / "AnyStrata" / "README.md").write_text(
        "Portable AnyStrata.\n\n"
        "1. Double-click AnyStrata.exe (or run AnyStrata.bat).\n"
        "2. Choose a model on first launch; the engine downloads from this release folder.\n",
        encoding="utf-8",
    )
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _dirs, files in os.walk(port_dir / "AnyStrata"):
            for file in files:
                file_path = Path(root) / file
                zf.write(file_path, file_path.relative_to(port_dir / "AnyStrata").as_posix())
    shutil.rmtree(port_dir)
    return zip_path, sha256(zip_path), str(zip_path.stat().st_size)


def main() -> int:
    ap = argparse.ArgumentParser(description="Build a desktop release folder for AnyStrata UI.")
    ap.add_argument("--version", required=True, help="app version, e.g. 0.2.3")
    ap.add_argument("--out", type=Path, required=True, help="output release folder")
    ap.add_argument("--setup", type=Path, help="path to the NSIS setup (default: derived from --version)")
    args = ap.parse_args()

    setup = args.setup or (OUT / "bundle" / "nsis" / f"AnyStrata_{args.version}_x64-setup.exe")
    if not setup.exists():
        print(f"error: setup not found at {setup}. Run tauri build first.", file=sys.stderr)
        return 1
    out = args.out
    out.mkdir(parents=True, exist_ok=True)

    dest = out / setup.name
    shutil.copy2(setup, dest)
    sha = sha256(dest)
    size = str(dest.stat().st_size)
    print(f"setup:      {dest.name} ({int(size) // (1024 * 1024)} MB, sha256={sha[:16]}...)")

    zip_path, zsha, zsize = build_portable_zip(dest, out, args.version)
    zname = zip_path.name
    print(f"portable:   {zname} ({int(zsize) // (1024 * 1024)} MB, sha256={zsha[:16]}...)")

    # desktop-specific install-manifest.txt (exe + portable + checksums)
    manifest = out / "install-manifest.txt"
    manifest.write_text(
        f"# AnyStrata Desktop install manifest for Windows\n"
        f"# Lines: exe <name> sha256 <hash> size <bytes> version <version> platform windows-x86_64\n"
        f"# portable: AnyStrata_{args.version}_portable.zip\n"
        f"# {zname}\n"
        f"# sha256 {zsha}\n"
        f"# size {zsize}\n"
        f"exe {dest.name}\n"
        f"sha256 {sha}\n"
        f"size {size}\n"
        f"version {args.version}\n"
        f"platform windows-x86_64\n",
        encoding="utf-8",
    )

    # a human-readable RELEASE-NOTES.md for the release folder
    (out / "RELEASE-NOTES.md").write_text(
        f"# AnyStrata Desktop {args.version}\n\n"
        f"- Setup: `{dest.name}` ({int(size) // (1024 * 1024)} MB)\n"
        f"- Portable: `{zname}` ({int(zsize) // (1024 * 1024)} MB)\n"
        f"- SHA-256 setup: `{sha}`\n"
        f"- Install:\n"
        f"  - Run the setup, or\n"
        f"  - `irm <feed>/install_desktop.ps1 | iex`\n"
        f"  - Portable: unzip, double-click `AnyStrata.exe`\n\n"
        f"The engine and model download on first launch from this release folder.\n",
        encoding="utf-8",
    )

    # checksums file
    (out / "checksums.txt").write_text(
        f"{sha}  {dest.name}\n{zsha}  {zname}\n",
        encoding="utf-8",
    )

    print(f"release folder: {out}")
    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
