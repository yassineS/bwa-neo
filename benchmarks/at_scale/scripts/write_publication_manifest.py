#!/usr/bin/env python3
"""Emit publication_manifest.json summarizing a benchmark Nextflow run."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def sh(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--neo-sam", required=True)
    p.add_argument("--neo-versions", required=True)
    p.add_argument("--parity-file", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--ref-fa", default="")
    p.add_argument("--reads-fq", default="")
    args = p.parse_args()

    parity_path = Path(args.parity_file)
    parity_text = parity_path.read_text().strip() if parity_path.is_file() else ""
    if parity_text.startswith("parity_skipped"):
        parity_block = {"enabled": False, "status": "skipped", "detail": None}
    else:
        parity_block = {
            "enabled": True,
            "status": "ok" if "OK" in parity_text.upper() else "check_required",
            "detail": parity_text[:500],
        }

    ref = Path(args.ref_fa) if args.ref_fa else None
    reads = Path(args.reads_fq) if args.reads_fq else None

    def _nf_ver() -> str:
        env_v = os.environ.get("NXF_VER", "")
        if env_v:
            return env_v.strip()
        try:
            r = subprocess.run(
                ["nextflow", "-version"],
                text=True,
                capture_output=True,
                check=False,
            )
            raw = (r.stdout or "") + (r.stderr or "")
        except OSError:
            raw = ""
        for line in raw.splitlines():
            ln = line.strip()
            if "nextflow" in ln.lower() and "version" in ln.lower():
                return ln
        return raw.splitlines()[0].strip() if raw else ""

    nf_ver = _nf_ver()

    manifest = {
        "schema": "bwa-neo-benchmark-manifest-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "git_sha": sh(["git", "rev-parse", "HEAD"]),
        "git_dirty": bool(sh(["git", "status", "--porcelain"])),
        "nextflow_version": nf_ver,
        "inputs": {
            "ref_fa": str(ref) if ref else None,
            "reads_fq": str(reads) if reads else None,
            "ref_bytes": ref.stat().st_size if ref and ref.is_file() else None,
            "reads_bytes": reads.stat().st_size if reads and reads.is_file() else None,
        },
        "outputs": {
            "neo_sam": str(Path(args.neo_sam).resolve()),
            "neo_versions": str(Path(args.neo_versions).resolve()),
        },
        "parity_first11": parity_block,
        "methods_notes": {
            "samse_threads": "neo uses bwa-neo `samse -t`; baseline uses stock bwa without `-t` (upstream lh3/bwa has no threaded samse).",
        },
        "environment": {
            "bwa_neo": os.environ.get("BWA_NEO", ""),
            "bwa_baseline": os.environ.get("BWA_BASELINE", ""),
        },
    }

    out = Path(args.out)
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out}", flush=True)


if __name__ == "__main__":
    main()
