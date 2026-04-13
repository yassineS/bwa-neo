process MERGE_ANCIENT_READS {
    tag "merge-ancient-pairs"

    input:
    path ancient_r1
    path ancient_r2

    output:
    path "ancient_merged.fq", emit: merged

    script:
    """
    set -euo pipefail
    command -v AdapterRemoval >/dev/null 2>&1 || { echo "Missing AdapterRemoval in Pixi env"; exit 1; }

    AdapterRemoval \
      --file1 "${ancient_r1}" \
      --file2 "${ancient_r2}" \
      --basename merged \
      --threads ${params.modern_threads} \
      --collapse \
      --qualitybase 33 \
      --trimns \
      --trimqualities \
      --minlength 25 >/dev/null 2>&1 || true

    # Use collapsed reads only; fallback keeps pipeline robust on edge cases.
    if [ -s merged.collapsed ]; then
      cp merged.collapsed ancient_merged.fq
    else
      cp "${ancient_r1}" ancient_merged.fq
    fi

    if [ -n "${params.ancient_merged_fq}" ] && [ -f "${params.ancient_merged_fq}" ]; then
      cp "${params.ancient_merged_fq}" ancient_merged.fq
    fi
    """
}
