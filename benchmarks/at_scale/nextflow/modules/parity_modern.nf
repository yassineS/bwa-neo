process MODERN_PARITY {
    tag "modern-parity"
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
    path neo_sam
    path baseline_sam
    path mem2_sam

    output:
    path "modern_mem_parity.tsv", emit: parity

    script:
    """
    set -euo pipefail

    norm() { awk 'BEGIN{FS=OFS="\\t"} !/^@/{print \$1,\$2,\$3,\$4,\$5,\$6,\$10,\$11}' "\$1" | sort; }

    echo -e "comparison\\tdiff_lines" > modern_mem_parity.tsv

    if [ -s "${baseline_sam}" ]; then
      norm "${neo_sam}" > neo.norm
      norm "${baseline_sam}" > baseline.norm
      d1=\$(diff -u neo.norm baseline.norm | awk 'END{print NR+0}')
      echo -e "neo_vs_baseline\\t\${d1:-0}" >> modern_mem_parity.tsv
    else
      echo -e "neo_vs_baseline\\t-1" >> modern_mem_parity.tsv
    fi

    if [ -s "${mem2_sam}" ]; then
      norm "${neo_sam}" > neo.norm
      norm "${mem2_sam}" > mem2.norm
      d2=\$(diff -u neo.norm mem2.norm | awk 'END{print NR+0}')
      echo -e "neo_vs_mem2\\t\${d2:-0}" >> modern_mem_parity.tsv
    else
      echo -e "neo_vs_mem2\\t-1" >> modern_mem_parity.tsv
    fi
    """
}
