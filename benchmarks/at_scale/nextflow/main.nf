#!/usr/bin/env nextflow

process GENERATE_SYNTHETIC_DATASETS {
    tag "datasets-1M"
    publishDir "${params.outdir}/datasets", mode: 'copy'

    input:
        path ref_modern, stageAs: "ref_modern.fa"
        path ref_ancient, stageAs: "ref_ancient.fa"

    output:
        tuple path("modern_se_1M.fq"), path("ancient_se_1M.fq"), path("ancient_pe_r1_1M.fq"), path("ancient_pe_r2_1M.fq")

    script:
        """
        set -euo pipefail
        python - <<'PY'
def load_ref(path):
    seq=[]
    with open(path) as f:
        for line in f:
            if not line.startswith(">"):
                seq.append(line.strip().upper())
    s="".join(seq)
    if len(s) < 300:
        s = s * ((300 // len(s)) + 2)
    return s

def damage(seq):
    a=list(seq)
    for i in range(min(3, len(a))):
        if a[i] == 'C':
            a[i] = 'T'
    for i in range(1, min(4, len(a)+1)):
        if a[-i] == 'G':
            a[-i] = 'A'
    return "".join(a)

def write_se(path, ref, n, read_len, damaged, prefix):
    ref_len = len(ref)
    with open(path, "w") as out:
        for i in range(n):
            start = (i * 37) % (ref_len - read_len)
            seq = ref[start:start+read_len]
            if damaged:
                seq = damage(seq)
            out.write(f"@{prefix}_{i}\\n{seq}\\n+\\n{'I'*read_len}\\n")

def write_pe(r1_path, r2_path, ref, n, read_len, insert, damaged, prefix):
    ref_len = len(ref)
    with open(r1_path, "w") as r1, open(r2_path, "w") as r2:
        for i in range(n):
            start = (i * 53) % (ref_len - insert - read_len)
            s1 = ref[start:start+read_len]
            s2 = ref[start+insert:start+insert+read_len]
            if damaged:
                s1 = damage(s1)
                s2 = damage(s2)
            r1.write(f"@{prefix}_{i}/1\\n{s1}\\n+\\n{'I'*read_len}\\n")
            r2.write(f"@{prefix}_{i}/2\\n{s2}\\n+\\n{'I'*read_len}\\n")

modern = load_ref("${ref_modern}")
ancient = load_ref("${ref_ancient}")
nm = int("${params.modern_reads_n}")
na = int("${params.ancient_reads_n}")

write_se("modern_se_1M.fq", modern, nm, 150, False, "modern")
write_se("ancient_se_1M.fq", ancient, na, 75, True, "ancient_se")
write_pe("ancient_pe_r1_1M.fq", "ancient_pe_r2_1M.fq", ancient, na, 75, 120, True, "ancient_pe")
PY
        """
}

process CAPTURE_VERSION {
    tag "${meta.tool}"
    publishDir "${params.outdir}/versions", mode: 'copy'

    input:
        val meta

    output:
        path "${meta.tool}.txt"

    script:
        """
        set -euo pipefail
        BIN='${meta.bin}'
        if command -v shasum >/dev/null 2>&1; then
          SHA=\$(shasum -a 256 "\$BIN" | awk '{print \$1}')
        else
          SHA=\$(sha256sum "\$BIN" | awk '{print \$1}')
        fi
        {
          echo -e "binary_path\\t\$BIN"
          echo -e "binary_sha256\\t\$SHA"
          echo -e "version_line\\t\$(\"\$BIN\" 2>&1 | awk 'NF{print; exit}' || true)"
        } > '${meta.tool}.txt'
        """
}

process MODERN_MEM_BENCH {
    tag "${meta.tool}"
    publishDir "${params.outdir}/perf/modern", mode: 'copy'

    input:
        val meta
        path ref_modern
        path reads_modern

    output:
        path "${meta.tool}_modern_mem_metrics.tsv"

    script:
        """
        set -euo pipefail
        BIN='${meta.bin}'
        "\$BIN" index '${ref_modern}'

        count_stats() { awk 'NR%4==2{r++; b+=length(\$0)} END{printf "%d\\t%d\\n", r, b}' "\$1"; }
        read READS BASES < <(count_stats '${reads_modern}' | tr '\\t' ' ')

        parse_time() {
          local f="\$1"
          local elapsed rss
          if [ ! -f "\$f" ]; then
            printf "0\\t0\\n"
            return 0
          fi
          elapsed=\$(awk '/^real /{print \$2}' "\$f")
          rss=\$(awk '/maximum resident set size/{print \$1}' "\$f" | tail -n 1)
          [ -n "\$elapsed" ] || elapsed=0
          [ -n "\$rss" ] || rss=0
          printf "%s\\t%s\\n" "\$elapsed" "\$rss"
        }

        run_timed() {
          local out_time="\$1"; shift
          /usr/bin/time -p -o "\$out_time" "\$@" >/dev/null 2>/dev/null || true
          return 0
        }

        echo -e "dataset\\tmode\\ttool\\tthreads\\trep\\telapsed_s\\tmax_rss_kb\\treads\\tbases\\tcommand" > '${meta.tool}_modern_mem_metrics.tsv'
        for rep in \$(seq 1 ${params.performance_repeats}); do
          for t in ${params.thread_grid}; do
            run_timed "mem_\${rep}_\${t}.time" "\$BIN" mem -t "\$t" '${ref_modern}' '${reads_modern}'
            read e r < <(parse_time "mem_\${rep}_\${t}.time" | tr '\\t' ' ')
            echo -e "modern\\tmem\\t${meta.tool}\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$READS\\t\$BASES\\tbwa mem" >> '${meta.tool}_modern_mem_metrics.tsv'
          done
        done
        """
}

process ANCIENT_ALN_BENCH {
    tag "${meta.tool}"
    publishDir "${params.outdir}/perf/ancient", mode: 'copy'

    input:
        val meta
        path ref_ancient
        path ancient_se
        path ancient_pe_r1
        path ancient_pe_r2

    output:
        path "${meta.tool}_ancient_aln_metrics.tsv"

    script:
        """
        set -euo pipefail
        BIN='${meta.bin}'
        "\$BIN" index '${ref_ancient}'

        count_stats() { awk 'NR%4==2{r++; b+=length(\$0)} END{printf "%d\\t%d\\n", r, b}' "\$1"; }
        read READS_SE BASES_SE < <(count_stats '${ancient_se}' | tr '\\t' ' ')
        read READS_PE BASES_PE < <(count_stats '${ancient_pe_r1}' | tr '\\t' ' ')

        parse_time() {
          local f="\$1"
          local elapsed rss
          if [ ! -f "\$f" ]; then
            printf "0\\t0\\n"
            return 0
          fi
          elapsed=\$(awk '/^real /{print \$2}' "\$f")
          rss=\$(awk '/maximum resident set size/{print \$1}' "\$f" | tail -n 1)
          [ -n "\$elapsed" ] || elapsed=0
          [ -n "\$rss" ] || rss=0
          printf "%s\\t%s\\n" "\$elapsed" "\$rss"
        }

        run_timed() {
          local out_time="\$1"; shift
          /usr/bin/time -p -o "\$out_time" "\$@" >/dev/null 2>/dev/null || true
          return 0
        }

        echo -e "dataset\\tmode\\ttool\\tthreads\\trep\\telapsed_s\\tmax_rss_kb\\treads\\tbases\\tcommand" > '${meta.tool}_ancient_aln_metrics.tsv'
        for rep in \$(seq 1 ${params.performance_repeats}); do
          for t in ${params.thread_grid}; do
            run_timed "se_\${rep}_\${t}.time" bash -lc "'\$BIN' aln -t \$t '${ref_ancient}' '${ancient_se}' > se.sai && '\$BIN' samse '${ref_ancient}' se.sai '${ancient_se}' > /dev/null"
            read e r < <(parse_time "se_\${rep}_\${t}.time" | tr '\\t' ' ')
            echo -e "ancient\\taln_se\\t${meta.tool}\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$READS_SE\\t\$BASES_SE\\tbwa aln+samse" >> '${meta.tool}_ancient_aln_metrics.tsv'

            run_timed "pe_\${rep}_\${t}.time" bash -lc "'\$BIN' aln -t \$t '${ref_ancient}' '${ancient_pe_r1}' > r1.sai && '\$BIN' aln -t \$t '${ref_ancient}' '${ancient_pe_r2}' > r2.sai && '\$BIN' sampe '${ref_ancient}' r1.sai r2.sai '${ancient_pe_r1}' '${ancient_pe_r2}' > /dev/null"
            read e r < <(parse_time "pe_\${rep}_\${t}.time" | tr '\\t' ' ')
            echo -e "ancient\\taln_pe\\t${meta.tool}\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$READS_PE\\t\$BASES_PE\\tbwa aln+sampe" >> '${meta.tool}_ancient_aln_metrics.tsv'
          done
        done
        """
}

process AGGREGATE_METRICS {
    tag "aggregate"
    publishDir "${params.outdir}/perf", mode: 'copy'

    input:
        path metric_files

    output:
        path "raw_metrics.tsv", emit: raw
        path "summary_metrics.tsv", emit: summary
        path "speedup_metrics.tsv", emit: speedup

    script:
        """
        set -euo pipefail
        cp "\$(printf "%s\\n" ${metric_files} | head -n 1)" raw_metrics.tsv
        for f in ${metric_files}; do
          if [ "\$f" != "\$(printf "%s\\n" ${metric_files} | head -n 1)" ]; then
            tail -n +2 "\$f" >> raw_metrics.tsv
          fi
        done

        awk 'BEGIN{
            FS=OFS="\\t";
            print "dataset","mode","tool","threads","n","elapsed_mean_s","elapsed_sd_s","elapsed_min_s","elapsed_max_s","rss_mean_kb","rss_sd_kb","reads","bases";
          }
          NR>1{
            key=\$1 FS \$2 FS \$3 FS \$4;
            n[key]++; se[key]+=\$6; se2[key]+=(\$6*\$6);
            if (!(key in minE) || \$6<minE[key]) minE[key]=\$6;
            if (!(key in maxE) || \$6>maxE[key]) maxE[key]=\$6;
            sr[key]+=\$7; sr2[key]+=(\$7*\$7);
            reads[key]=\$8; bases[key]=\$9;
          }
          END{
            for (k in n){
              me=se[k]/n[k]; ve=(se2[k]/n[k])-(me*me); if (ve<0) ve=0;
              mr=sr[k]/n[k]; vr=(sr2[k]/n[k])-(mr*mr); if (vr<0) vr=0;
              split(k,p,FS);
              print p[1],p[2],p[3],p[4],n[k],me,sqrt(ve),minE[k],maxE[k],mr,sqrt(vr),reads[k],bases[k];
            }
          }' raw_metrics.tsv > summary_metrics.tsv

        awk 'BEGIN{
             FS=OFS="\\t";
             print "dataset","mode","tool","threads","elapsed_mean_s","speedup_vs_thread1";
          }
          NR>1{
             k=\$1 FS \$2 FS \$3;
             t=\$4; e=\$6;
             means[k FS t]=e;
             if (t==1) base[k]=e;
          }
          END{
             for (mt in means){
                split(mt, a, FS);
                key=a[1] FS a[2] FS a[3];
                t=a[4];
                b=base[key];
                if (b > 0) sp=b/means[mt]; else sp=0;
                print a[1],a[2],a[3],t,means[mt],sp;
             }
          }' summary_metrics.tsv > speedup_metrics.tsv

        """
}

process PLOT_METRICS {
    tag "plot"
    publishDir "${params.outdir}/plot", mode: 'copy'

    input:
        path raw_metrics
        path summary_metrics
        path speedup_metrics

    output:
        path "runtime_bar.pdf"
        path "runtime_bar.svg"
        path "runtime_bar.png"
        path "memory_bar.pdf"
        path "memory_bar.svg"
        path "memory_bar.png"
        path "speedup_ratio.pdf"
        path "speedup_ratio.svg"
        path "speedup_ratio.png"

    script:
        """
        set -euo pipefail
        python - <<'PY'
import pandas as pd
import matplotlib.pyplot as plt

summary = pd.read_csv("${summary_metrics}", sep="\\t")
summary["threads"] = pd.to_numeric(summary["threads"])
summary["label"] = summary["dataset"] + "-" + summary["mode"] + "-" + summary["tool"] + "-t" + summary["threads"].astype(str)

palette = {"neo":"#4477AA", "baseline":"#CC6677", "mem2":"#228833"}
colors = [palette.get(x, "#999999") for x in summary["tool"]]

fig, ax = plt.subplots(figsize=(11, 4.5))
x = list(range(len(summary)))
ax.bar(x, summary["elapsed_mean_s"], yerr=summary["elapsed_sd_s"], capsize=4, color=colors)
ax.set_xticks(x)
ax.set_xticklabels(summary["label"], rotation=55, ha="right")
ax.set_ylabel("Elapsed time (s)")
ax.set_title("Publication benchmarks runtime")
fig.tight_layout()
fig.savefig("runtime_bar.pdf"); fig.savefig("runtime_bar.svg"); fig.savefig("runtime_bar.png", dpi=300)
plt.close(fig)

fig, ax = plt.subplots(figsize=(11, 4.5))
ax.bar(x, summary["rss_mean_kb"], yerr=summary["rss_sd_kb"], capsize=4, color=colors)
ax.set_xticks(x)
ax.set_xticklabels(summary["label"], rotation=55, ha="right")
ax.set_ylabel("Max RSS (kB)")
ax.set_title("Publication benchmarks memory")
fig.tight_layout()
fig.savefig("memory_bar.pdf"); fig.savefig("memory_bar.svg"); fig.savefig("memory_bar.png", dpi=300)
plt.close(fig)

t8 = summary[summary["threads"] == 8]
rows = []
for (dataset, mode), _ in t8.groupby(["dataset", "mode"]):
    neo = t8[(t8["dataset"] == dataset) & (t8["mode"] == mode) & (t8["tool"] == "neo")]
    base = t8[(t8["dataset"] == dataset) & (t8["mode"] == mode) & (t8["tool"] == "baseline")]
    if len(neo) == 1 and len(base) == 1 and float(neo.iloc[0]["elapsed_mean_s"]) > 0:
        rows.append({"group": f"{dataset}-{mode}", "speedup": float(base.iloc[0]["elapsed_mean_s"]) / float(neo.iloc[0]["elapsed_mean_s"])})
df = pd.DataFrame(rows)
if len(df) > 0:
    fig, ax = plt.subplots(figsize=(6.5, 4))
    ax.bar(df["group"], df["speedup"], color="#228833")
    ax.axhline(1.0, linestyle="--", color="black", linewidth=1)
    ax.set_ylabel("Speedup vs baseline (x)")
    ax.set_title("bwa-neo speedup at 8 threads")
    fig.tight_layout()
    fig.savefig("speedup_ratio.pdf"); fig.savefig("speedup_ratio.svg"); fig.savefig("speedup_ratio.png", dpi=300)
    plt.close(fig)
else:
    open("speedup_ratio.pdf", "wb").close()
    open("speedup_ratio.svg", "w").close()
    open("speedup_ratio.png", "wb").close()
PY
        """
}

process PUBLICATION_MANIFEST {
    tag "manifest"
    publishDir "${params.outdir}/manifest", mode: 'copy'

    input:
        val manifest_json

    output:
        path "publication_manifest.json"

    script:
        """
        set -euo pipefail
        cat > publication_manifest.json <<'JSON'
${manifest_json}
JSON
        """
}

workflow {
    def refModern = file(params.ref_fa, checkIfExists: true)
    def refAncient = file(params.ref_pe_fa, checkIfExists: true)

    GENERATE_SYNTHETIC_DATASETS(refModern, refAncient)

    def modernReads = GENERATE_SYNTHETIC_DATASETS.out.map { m, a, r1, r2 -> m }
    def ancientSe = GENERATE_SYNTHETIC_DATASETS.out.map { m, a, r1, r2 -> a }
    def ancientPeR1 = GENERATE_SYNTHETIC_DATASETS.out.map { m, a, r1, r2 -> r1 }
    def ancientPeR2 = GENERATE_SYNTHETIC_DATASETS.out.map { m, a, r1, r2 -> r2 }

    def modernTools = Channel.of(
        [tool: 'neo', bin: params.bwa_neo],
        [tool: 'baseline', bin: params.bwa_baseline],
        [tool: 'mem2', bin: params.bwa_mem2]
    )
    def ancientTools = Channel.of(
        [tool: 'neo', bin: params.bwa_neo],
        [tool: 'baseline', bin: params.bwa_baseline]
    )

    CAPTURE_VERSION(modernTools)

    MODERN_MEM_BENCH(modernTools, Channel.value(refModern), modernReads)
    ANCIENT_ALN_BENCH(ancientTools, Channel.value(refAncient), ancientSe, ancientPeR1, ancientPeR2)

    def metricFiles = MODERN_MEM_BENCH.out.mix(ANCIENT_ALN_BENCH.out).collect()
    AGGREGATE_METRICS(metricFiles)
    PLOT_METRICS(AGGREGATE_METRICS.out.raw, AGGREGATE_METRICS.out.summary, AGGREGATE_METRICS.out.speedup)

    def manifest = [
        schema: 'bwa-neo-publication-local-v2',
        generated_utc: java.time.Instant.now().toString(),
        modern_reads_n: params.modern_reads_n,
        ancient_reads_n: params.ancient_reads_n,
        thread_grid: params.thread_grid.toString().split(' '),
        performance_repeats: params.performance_repeats,
        binaries: [
            bwa_neo: params.bwa_neo,
            bwa_baseline: params.bwa_baseline,
            bwa_mem2: params.bwa_mem2
        ],
        outputs: [
            raw_metrics: "${params.outdir}/perf/raw_metrics.tsv",
            summary_metrics: "${params.outdir}/perf/summary_metrics.tsv",
            speedup_metrics: "${params.outdir}/perf/speedup_metrics.tsv",
            plots_dir: "${params.outdir}/plot"
        ]
    ]
    PUBLICATION_MANIFEST(groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(manifest)))
}
