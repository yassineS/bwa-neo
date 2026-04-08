process RENDER_PUBLICATION_ASSETS {
    tag "render-publication-assets"
    publishDir "${params.outdir}/plot", mode: 'copy', pattern: "*.{pdf,svg,png}"
    publishDir "${params.outdir}/tables", mode: 'copy', pattern: "*.{tsv,md}"

    input:
    path raw_metrics
    path summary_metrics
    path speedup_metrics
    path ancient_speedup_metrics
    path modern_mem_parity

    output:
    path "runtime_by_mode.pdf"
    path "runtime_by_mode.svg"
    path "runtime_by_mode.png"
    path "ancient_speedup_curve.pdf"
    path "ancient_speedup_curve.svg"
    path "ancient_speedup_curve.png"
    path "memory_by_mode.pdf"
    path "memory_by_mode.svg"
    path "memory_by_mode.png"
    path "table_modern_runtime.tsv"
    path "table_modern_runtime.md"
    path "table_ancient_scaling.tsv"
    path "table_ancient_scaling.md"
    path "table_modern_parity.tsv"
    path "table_modern_parity.md"

    script:
    """
    set -euo pipefail
    python - <<'PY'
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

plt.rcParams.update({
    "figure.dpi": 150,
    "savefig.dpi": 300,
    "font.size": 9,
    "axes.titlesize": 10,
    "axes.labelsize": 9,
    "legend.fontsize": 8,
})

palette = {
    "neo": "#4C72B0",
    "baseline": "#DD8452",
    "mem2": "#55A868",
}

raw = pd.read_csv("${raw_metrics}", sep="\\t")
summary = pd.read_csv("${summary_metrics}", sep="\\t")
speedup = pd.read_csv("${speedup_metrics}", sep="\\t")
anc_speed = pd.read_csv("${ancient_speedup_metrics}", sep="\\t")
parity = pd.read_csv("${modern_mem_parity}", sep="\\t")

# Table 1: Modern runtime/memory comparison.
modern_tbl = summary[summary["dataset"] == "modern"].copy()
modern_tbl = modern_tbl[[
    "mode", "tool", "threads", "n",
    "elapsed_mean_s", "elapsed_sd_s",
    "rss_mean_kb", "rss_sd_kb",
    "reads", "bases",
]]
modern_tbl = modern_tbl.sort_values(["mode", "tool", "threads"])
modern_tbl.to_csv("table_modern_runtime.tsv", sep="\\t", index=False)
modern_tbl.to_markdown("table_modern_runtime.md", index=False)

# Table 2: Ancient scaling table.
anc_tbl = speedup[speedup["dataset"] == "ancient"].copy()
anc_tbl = anc_tbl[[
    "mode", "tool", "threads", "elapsed_mean_s", "speedup_vs_thread1"
]]
anc_tbl = anc_tbl.sort_values(["mode", "tool", "threads"])
anc_tbl.to_csv("table_ancient_scaling.tsv", sep="\\t", index=False)
anc_tbl.to_markdown("table_ancient_scaling.md", index=False)

# Table 3: Modern parity.
parity.to_csv("table_modern_parity.tsv", sep="\\t", index=False)
parity.to_markdown("table_modern_parity.md", index=False)

# Figure 1: Runtime by mode/tool.
runtime = summary.copy()
runtime["label"] = runtime["dataset"] + ":" + runtime["mode"] + ":" + runtime["tool"]
runtime = runtime.sort_values(["dataset", "mode", "tool", "threads"])

fig, ax = plt.subplots(figsize=(10, 4.5))
x = range(len(runtime))
colors = [palette.get(t, "#8172B3") for t in runtime["tool"]]
ax.bar(x, runtime["elapsed_mean_s"], yerr=runtime["elapsed_sd_s"], color=colors, capsize=2)
ax.set_xticks(list(x))
ax.set_xticklabels(runtime["label"], rotation=60, ha="right")
ax.set_ylabel("Elapsed mean (s)")
ax.set_title("Runtime by dataset/mode/tool")
ax.grid(axis="y", linestyle="--", alpha=0.35)
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
fig.tight_layout()
for ext in ("pdf", "svg", "png"):
    fig.savefig(f"runtime_by_mode.{ext}", bbox_inches="tight")
plt.close(fig)

# Figure 2: Ancient speedup curve.
anc = anc_speed.copy()
fig, ax = plt.subplots(figsize=(8, 4.5))
for (mode, tool), grp in anc.groupby(["mode", "tool"]):
    grp = grp.sort_values("threads")
    ax.plot(
        grp["threads"],
        grp["speedup_vs_thread1"],
        marker="o",
        linewidth=1.8,
        label=f"{mode}:{tool}",
        color=palette.get(tool, "#8172B3"),
    )
ax.set_xlabel("Threads")
ax.set_ylabel("Speedup vs thread=1")
ax.set_title("Ancient DNA scaling curves")
ax.set_xticks(sorted(anc["threads"].unique()))
ax.grid(axis="y", linestyle="--", alpha=0.35)
ax.legend(frameon=False, ncol=2)
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
fig.tight_layout()
for ext in ("pdf", "svg", "png"):
    fig.savefig(f"ancient_speedup_curve.{ext}", bbox_inches="tight")
plt.close(fig)

# Figure 3: Memory by mode/tool.
mem = summary.copy()
mem["label"] = mem["dataset"] + ":" + mem["mode"] + ":" + mem["tool"]
mem = mem.sort_values(["dataset", "mode", "tool", "threads"])
fig, ax = plt.subplots(figsize=(10, 4.5))
colors = [palette.get(t, "#8172B3") for t in mem["tool"]]
ax.bar(range(len(mem)), mem["rss_mean_kb"], yerr=mem["rss_sd_kb"], color=colors, capsize=2)
ax.set_xticks(list(range(len(mem))))
ax.set_xticklabels(mem["label"], rotation=60, ha="right")
ax.set_ylabel("Peak RSS mean (KB)")
ax.set_title("Memory footprint by dataset/mode/tool")
ax.grid(axis="y", linestyle="--", alpha=0.35)
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
fig.tight_layout()
for ext in ("pdf", "svg", "png"):
    fig.savefig(f"memory_by_mode.{ext}", bbox_inches="tight")
plt.close(fig)
PY
    """
}
