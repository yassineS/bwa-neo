process RUN_ANCIENT_BENCH {
    tag "ancient-aln-bench"
    publishDir "${params.outdir}/perf", mode: 'copy', pattern: "ancient_raw.tsv"

    input:
    path ref_ancient
    path ancient_merged
    path ancient_r1
    path ancient_r2

    output:
    path "ancient_raw.tsv", emit: metrics

    script:
    """
    set -euo pipefail
    [ -x "${params.bwa_neo}" ] || { echo "Missing bwa_neo binary: ${params.bwa_neo}"; exit 1; }
    BASE_BIN="${params.bwa_baseline}"
    if [ -z "\$BASE_BIN" ]; then BASE_BIN="\$(command -v bwa || true)"; fi

    count_reads() { awk 'NR%4==2{r++; b+=length(\$0)} END{printf "%d\\t%d\\n", r, b}' "\$1"; }
    read AREADS_M ABASES_M < <(count_reads "${ancient_merged}" | tr '\\t' ' ')
    read AREADS_P ABASES_P < <(count_reads "${ancient_r1}" | tr '\\t' ' ')

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
      /usr/bin/time -l -p "\$@" >/dev/null 2>"\$out_time" || true
      [ -s "\$out_time" ] || echo "real 0" > "\$out_time"
    }

    echo -e "dataset\\tmode\\ttool\\tthreads\\trep\\telapsed_s\\tmax_rss_kb\\treads\\tbases\\tcommand" > ancient_raw.tsv

    "${params.bwa_neo}" index "${ref_ancient}"
    if [ -n "\$BASE_BIN" ] && [ -x "\$BASE_BIN" ]; then
      "\$BASE_BIN" index "${ref_ancient}"
    fi

    for rep in \$(seq 1 ${params.performance_repeats}); do
      for t in ${params.thread_grid}; do
        run_time neo_se.time bash -lc "'${params.bwa_neo}' aln -t \$t '${ref_ancient}' '${ancient_merged}' > n.sai && '${params.bwa_neo}' samse -t \$t '${ref_ancient}' n.sai '${ancient_merged}' > /dev/null"
        e=\$(parse_real neo_se.time); r=\$(parse_rss neo_se.time)
        echo -e "ancient\\taln_samse\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_M\\t\$ABASES_M\\tbwa-neo aln+samse" >> ancient_raw.tsv

        if [ -n "\$BASE_BIN" ] && [ -x "\$BASE_BIN" ]; then
          run_time base_se.time bash -lc "'\$BASE_BIN' aln -t \$t '${ref_ancient}' '${ancient_merged}' > b.sai && '\$BASE_BIN' samse '${ref_ancient}' b.sai '${ancient_merged}' > /dev/null"
          e=\$(parse_real base_se.time); r=\$(parse_rss base_se.time)
          echo -e "ancient\\taln_samse\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_M\\t\$ABASES_M\\tbwa aln+samse" >> ancient_raw.tsv
        fi

        run_time neo_pe.time bash -lc "'${params.bwa_neo}' aln -t \$t '${ref_ancient}' '${ancient_r1}' > n1.sai && '${params.bwa_neo}' aln -t \$t '${ref_ancient}' '${ancient_r2}' > n2.sai && '${params.bwa_neo}' sampe -t \$t '${ref_ancient}' n1.sai n2.sai '${ancient_r1}' '${ancient_r2}' > /dev/null"
        e=\$(parse_real neo_pe.time); r=\$(parse_rss neo_pe.time)
        echo -e "ancient\\taln_sampe\\tneo\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_P\\t\$ABASES_P\\tbwa-neo aln+sampe" >> ancient_raw.tsv

        if [ -n "\$BASE_BIN" ] && [ -x "\$BASE_BIN" ]; then
          run_time base_pe.time bash -lc "'\$BASE_BIN' aln -t \$t '${ref_ancient}' '${ancient_r1}' > b1.sai && '\$BASE_BIN' aln -t \$t '${ref_ancient}' '${ancient_r2}' > b2.sai && '\$BASE_BIN' sampe '${ref_ancient}' b1.sai b2.sai '${ancient_r1}' '${ancient_r2}' > /dev/null"
          e=\$(parse_real base_pe.time); r=\$(parse_rss base_pe.time)
          echo -e "ancient\\taln_sampe\\tbaseline\\t\$t\\t\$rep\\t\$e\\t\$r\\t\$AREADS_P\\t\$ABASES_P\\tbwa aln+sampe" >> ancient_raw.tsv
        fi
      done
    done
    """
}
