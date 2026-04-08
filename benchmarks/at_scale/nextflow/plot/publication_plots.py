#!/usr/bin/env python3
import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PALETTE = {"neo": "#1b9e77", "baseline": "#d95f02", "mem2": "#7570b3"}
MODE_LABEL = {"mem": "MEM", "aln_se": "aDNA SE", "aln_pe": "aDNA PE"}
DATASET_LABEL = {"modern": "Modern DNA", "ancient": "Ancient DNA"}


def _style():
    plt.rcParams.update(
        {
            "font.size": 9,
            "axes.titlesize": 10,
            "axes.labelsize": 9,
            "legend.fontsize": 8,
            "xtick.labelsize": 8,
            "ytick.labelsize": 8,
            "figure.dpi": 300,
        }
    )


def _draw_grouped(ax, df, ycol, yerrcol, title, ylabel):
    if df.empty:
        ax.set_title(title)
        ax.set_ylabel(ylabel)
        ax.text(0.5, 0.5, "No data", ha="center", va="center", transform=ax.transAxes)
        return

    grouped = df.copy()
    grouped["group"] = grouped["mode"].map(MODE_LABEL).fillna(grouped["mode"]) + "\n" + grouped["threads"].astype(str) + " threads"
    groups = sorted(grouped["group"].unique(), key=lambda x: (x.split("\n")[0], int(x.split("\n")[1].split()[0])))
    tools = [t for t in ["neo", "baseline", "mem2"] if t in grouped["tool"].unique()]

    x = list(range(len(groups)))
    width = 0.8 / max(len(tools), 1)
    for idx, tool in enumerate(tools):
        sub = grouped[grouped["tool"] == tool].set_index("group")
        ys = [float(sub.loc[g, ycol]) if g in sub.index else float("nan") for g in groups]
        es = [float(sub.loc[g, yerrcol]) if g in sub.index else 0.0 for g in groups]
        offset = (idx - (len(tools) - 1) / 2.0) * width
        ax.bar(
            [v + offset for v in x],
            ys,
            width=width,
            yerr=es,
            capsize=2,
            label=tool,
            color=PALETTE.get(tool, "#666666"),
            edgecolor="black",
            linewidth=0.3,
        )

    ax.set_xticks(x)
    ax.set_xticklabels(groups, rotation=25, ha="right")
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.grid(axis="y", linewidth=0.3, alpha=0.5)
    ax.legend(frameon=False, ncol=min(3, len(tools)))


def plot_runtime(summary: pd.DataFrame, outdir: Path):
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.2), constrained_layout=True)
    for i, dataset in enumerate(["modern", "ancient"]):
        sdf = summary[summary["dataset"] == dataset].copy()
        _draw_grouped(
            axes[i],
            sdf,
            "elapsed_mean_s",
            "elapsed_sd_s",
            f"{DATASET_LABEL.get(dataset, dataset)} runtime",
            "Elapsed time (s)",
        )
    fig.savefig(outdir / "runtime_bar.pdf")
    fig.savefig(outdir / "runtime_bar.svg")
    fig.savefig(outdir / "runtime_bar.png")
    plt.close(fig)


def plot_memory(summary: pd.DataFrame, outdir: Path):
    mem = summary.copy()
    mem["rss_mean_mb"] = pd.to_numeric(mem["rss_mean_kb"], errors="coerce") / 1024.0
    mem["rss_sd_mb"] = pd.to_numeric(mem["rss_sd_kb"], errors="coerce") / 1024.0
    mem.loc[mem["rss_mean_mb"] <= 0, ["rss_mean_mb", "rss_sd_mb"]] = pd.NA

    fig, axes = plt.subplots(1, 2, figsize=(12, 4.2), constrained_layout=True)
    for i, dataset in enumerate(["modern", "ancient"]):
        sdf = mem[mem["dataset"] == dataset].copy()
        _draw_grouped(
            axes[i],
            sdf,
            "rss_mean_mb",
            "rss_sd_mb",
            f"{DATASET_LABEL.get(dataset, dataset)} memory",
            "Peak RSS (MB)",
        )
    fig.savefig(outdir / "memory_bar.pdf")
    fig.savefig(outdir / "memory_bar.svg")
    fig.savefig(outdir / "memory_bar.png")
    plt.close(fig)


def plot_speedup(summary: pd.DataFrame, outdir: Path):
    rows = []
    for (dataset, mode, threads), grp in summary.groupby(["dataset", "mode", "threads"]):
        neo = grp[grp["tool"] == "neo"]
        base = grp[grp["tool"] == "baseline"]
        if len(neo) == 1 and len(base) == 1:
            neo_t = float(neo.iloc[0]["elapsed_mean_s"])
            base_t = float(base.iloc[0]["elapsed_mean_s"])
            if neo_t > 0:
                rows.append(
                    {
                        "group": f"{DATASET_LABEL.get(dataset, dataset)}\n{MODE_LABEL.get(mode, mode)}\n{threads}t",
                        "speedup": base_t / neo_t,
                    }
                )

    df = pd.DataFrame(rows)
    fig, ax = plt.subplots(figsize=(8.2, 4.2), constrained_layout=True)
    if not df.empty:
        ax.bar(df["group"], df["speedup"], color="#4c72b0", edgecolor="black", linewidth=0.3)
    else:
        ax.text(0.5, 0.5, "No baseline comparison available", ha="center", va="center", transform=ax.transAxes)
    ax.axhline(1.0, linestyle="--", color="black", linewidth=1)
    ax.set_ylabel("Speedup vs baseline (x)")
    ax.set_title("bwa-neo speedup")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=20, ha="right")
    ax.grid(axis="y", linewidth=0.3, alpha=0.5)
    fig.savefig(outdir / "speedup_ratio.pdf")
    fig.savefig(outdir / "speedup_ratio.svg")
    fig.savefig(outdir / "speedup_ratio.png")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", required=True)
    parser.add_argument("--speedup", required=False)
    parser.add_argument("--outdir", required=True)
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    _style()

    summary = pd.read_csv(args.summary, sep="\t")
    summary["threads"] = pd.to_numeric(summary["threads"])
    summary["elapsed_mean_s"] = pd.to_numeric(summary["elapsed_mean_s"], errors="coerce")
    summary["elapsed_sd_s"] = pd.to_numeric(summary["elapsed_sd_s"], errors="coerce")
    summary["rss_mean_kb"] = pd.to_numeric(summary["rss_mean_kb"], errors="coerce")
    summary["rss_sd_kb"] = pd.to_numeric(summary["rss_sd_kb"], errors="coerce")

    plot_runtime(summary, outdir)
    plot_memory(summary, outdir)
    plot_speedup(summary, outdir)


if __name__ == "__main__":
    main()
