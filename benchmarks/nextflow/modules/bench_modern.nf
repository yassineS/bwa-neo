process RUN_MODERN_BENCH {
    tag "modern-mem-bench"
    publishDir "${params.outdir}/perf", mode: 'copy', pattern: "modern_raw.tsv"
    publishDir "${params.outdir}/parity", mode: 'copy', pattern: "*_modern.sam"

    input:
    path ref_modern
    path modern_r1
    path modern_r2

    output:
    path "modern_raw.tsv", emit: metrics
    path "neo_modern.sam", emit: neo_sam
    path "baseline_modern.sam", emit: baseline_sam
    path "mem2_modern.sam", emit: mem2_sam

    script:
    """
    set -euo pipefail
    [ -x "${params.bwa_neo}" ] || { echo "Missing bwa_neo binary: ${params.bwa_neo}"; exit 1; }
    BASE_BIN="${params.bwa_baseline}"
    MEM2_BIN="${params.bwa_mem2}"
    if [ -z "\$BASE_BIN" ]; then BASE_BIN="\$(command -v bwa || true)"; fi
    if [ -z "\$MEM2_BIN" ]; then MEM2_BIN="\$(command -v bwa-mem2 || true)"; fi

    count_reads() { awk 'NR%4==2{r++; b+=length(\$0)} END{printf "%d\\t%d\\n", r, b}' "\$1"; }
    read MREADS MBASES < <(count_reads "${modern_r1}" | tr '\\t' ' ')

    parse_real() { awk '/^real /{print \$2}' "\$1"; }
    parse_rss() {
      local value
      value=\$(awk '/maximum resident set size/{print \$1}' "\$1" | tail -n1)
      if [ -z "\$value" ]; then
        value=\$(awk '/Maximum resident set size/{print \$6}' "\$1" | tail -n1)
      fi
      echo "\${value:--1}"
    }
    run_time() {
      local out_time="\$1"; shift
      /usr/bin/time -l -p "\$@" 2>"\$out_time" || true
      [ -s "\$out_time" ] || echo "real 0" > "\$out_time"
    }

    echo -e "dataset\\tmode\\ttool\\tthreads\\trep\\telapsed_s\\tmax_rss_kb\\treads\\tbases\\tcommand" > modern_raw.tsv

    # Classic bwa index (neo + lh3/bwa) shares one format; bwa-mem2 uses a different index layout
    # and must not be built on the same prefix or it clobbers classic index files.
    "${params.bwa_neo}" index "${ref_modern}"
    if [ -n "\$BASE_BIN" ] && [ -x "\$BASE_BIN" ]; then
      "\$BASE_BIN" index "${ref_modern}"
    fi
    MEM2_REF=""
    if [ -n "\$MEM2_BIN" ] && [ -x "\$MEM2_BIN" ]; then
      MEM2_REF="ref_mem2.fa"
      cp "${ref_modern}" "\$MEM2_REF"
      "\$MEM2_BIN" index "\$MEM2_REF"
    fi

    : > baseline_modern.sam
    : > mem2_modern.sam

    for rep in \$(seq 1 ${params.performance_repeats}); do
      t=${params.modern_threads}
      run_time neo.time "${params.bwa_neo}" mem -t "\$t" "${ref_modern}" "${modern_r1}" "${modern_r2}" > neo.sam
      e=\$(parse_real neo.time); r=\$(parse_rss neo.time)
      echo -e "modern\\tmem_neo\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa-neo mem pe" >> modern_raw.tsv
      [ "\$rep" -eq 1 ] && cp neo.sam neo_modern.sam

      if [ -n "\$BASE_BIN" ] && [ -x "\$BASE_BIN" ]; then
        run_time base.time "\$BASE_BIN" mem -t "\$t" "${ref_modern}" "${modern_r1}" "${modern_r2}" > base.sam
        e=\$(parse_real base.time); r=\$(parse_rss base.time)
        echo -e "modern\\tmem\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa mem pe" >> modern_raw.tsv
        [ "\$rep" -eq 1 ] && cp base.sam baseline_modern.sam
      fi

      if [ -n "\$MEM2_BIN" ] && [ -x "\$MEM2_BIN" ]; then
        run_time mem2.time "\$MEM2_BIN" mem -t "\$t" "\$MEM2_REF" "${modern_r1}" "${modern_r2}" > mem2.sam
        e=\$(parse_real mem2.time); r=\$(parse_rss mem2.time)
        echo -e "modern\\tmem2\\tmem2\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$MREADS\\t\$MBASES\\tbwa-mem2 mem pe" >> modern_raw.tsv
        [ "\$rep" -eq 1 ] && cp mem2.sam mem2_modern.sam
      fi
    done
    """
}
