#!/usr/bin/env nextflow
/*
 * At-scale correctness + performance benchmark for bwa-neo vs baselines.
 *
 * IMPLEMENTATION NOTES (for contributors):
 *
 * 1) Correctness
 *    - Build classic BWA index once; run: baseline `bwa` and `params.bwa_neo` with identical argv.
 *    - For mem2: build `.0123` index with bwa-mem2; compare neo mem2 vs third_party bwa-mem2.
 *    - Normalize SAM (sort, optional field strip) before diff.
 *
 * 2) Performance
 *    - Emit TSV rows: tool, stage, threads, elapsed_sec, max_rss_kb, n_reads
 *    - Call plotting script in workflow completion hook or final process.
 *
 * 3) Data
 *    - Use Zenodo modules or curl with checksum verification (see benchmarks/at_scale/README.md).
 */

workflow {
    // Stub: replace with channel-driven download + map steps
    Channel.empty()
        .view { "Define processes: FETCH_REF, FETCH_READS, " +
                "SIM_REF_SLICE (optional), SIM_MODERN, SIM_ANCIENT, " +
                "INDEX_CLASSIC, INDEX_MEM2, " +
                "RUN_ALN_SAMSE_BASELINE, RUN_ALN_SAMSE_NEO, DIFF_SAM, BENCH_*, ACCURACY (optional)" }
}

/*
 * Example process skeleton (uncomment and wire params when implementing):

process RUN_ALN_SAMSE {
    tag "${sample_id}"
    input:
        tuple val(sample_id), path(ref), path(reads)
    output:
        tuple val(sample_id), path("${sample_id}.neo.sam"), emit: sam
    script:
    """
    set -euo pipefail
    ${params.bwa_neo} index ref.fa
    ${params.bwa_neo} aln -t ${params.threads_aln} ref.fa reads.fq > reads.sai
    /usr/bin/time -v -o neo.time.txt ${params.bwa_neo} samse -t ${params.threads_samse} ref.fa reads.sai reads.fq \\
        > ${sample_id}.neo.sam 2>neo.stderr
    """
}
*/
