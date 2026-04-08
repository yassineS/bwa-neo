#!/usr/bin/env nextflow
/*
 * Tiny-fixture benchmark: threaded aln + samse/sampe, optional baseline parity,
 * neo samse -t self-test, publication manifest (no external Python/bash drivers).
 */

import groovy.json.JsonOutput
import java.time.Instant

process BWA_SE_BENCH {
    tag "${meta.id}"
    publishDir "${params.outdir}/se/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(reads)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        path "${meta.id}_versions.txt", emit: versions

    script:
        def samse_t_flag = meta.samse_t ? "-t ${params.threads_samse} " : ''
        """
        set -euo pipefail
        '${meta.bwa}' 2>&1 | head -n 1 > '${meta.id}_versions.txt' || true
        '${meta.bwa}' index '${ref}'
        '${meta.bwa}' aln -t ${params.threads_aln} '${ref}' '${reads}' > reads.sai
        '${meta.bwa}' samse ${samse_t_flag}'${ref}' reads.sai '${reads}' > '${meta.id}.sam'
        """
}

process BWA_PE_BENCH {
    tag "${meta.id}"
    publishDir "${params.outdir}/pe/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(r1), path(r2)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        path "${meta.id}_versions.txt", emit: versions

    script:
        """
        set -euo pipefail
        '${meta.bwa}' 2>&1 | head -n 1 > '${meta.id}_versions.txt' || true
        '${meta.bwa}' index '${ref}'
        '${meta.bwa}' aln -t ${params.threads_aln} '${ref}' '${r1}' > r1.sai
        '${meta.bwa}' aln -t ${params.threads_aln} '${ref}' '${r2}' > r2.sai
        '${meta.bwa}' sampe '${ref}' r1.sai r2.sai '${r1}' '${r2}' > '${meta.id}.sam'
        """
}

process PARITY_SE_FIRST11 {
    tag 'se'
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(baseline_sam)

    output:
        path 'parity_se.ok', emit: ok
        env SUMMARY, emit: msg

    script:
        """
        set -euo pipefail
        awk '/^r1\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n"); exit}' '${neo_sam}' | sort > neo.first11.tsv
        awk '/^r1\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n"); exit}' '${baseline_sam}' | sort > base.first11.tsv
        cmp -s neo.first11.tsv base.first11.tsv
        echo 'SE SAM first-11: neo == baseline OK' > parity_se.ok
        export SUMMARY='SE SAM first-11: neo == baseline OK'
        """
}

process PARITY_PE_FIRST11 {
    tag 'pe'
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(baseline_sam)

    output:
        path 'parity_pe.ok', emit: ok
        env SUMMARY, emit: msg

    script:
        """
        set -euo pipefail
        awk '/^pair\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")}' '${neo_sam}' | sort > neo.first11.tsv
        awk '/^pair\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")}' '${baseline_sam}' | sort > base.first11.tsv
        cmp -s neo.first11.tsv base.first11.tsv
        echo 'PE SAM first-11 (pair): neo == baseline OK' > parity_pe.ok
        export SUMMARY='PE SAM first-11 (pair): neo == baseline OK'
        """
}

process NEO_SAMSE_THREAD_SELFTEST {
    tag 'samse-t'
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(ref), path(reads)

    output:
        path 'samse_thread_parity.ok', emit: ok
        env SUMMARY, emit: msg

    when:
        params.check_samse_thread_parity

    script:
        """
        set -euo pipefail
        '${params.bwa_neo}' index '${ref}'
        '${params.bwa_neo}' aln -t 1 '${ref}' '${reads}' > one.sai
        '${params.bwa_neo}' samse -t 1 '${ref}' one.sai '${reads}' 2>/dev/null \\
            | awk '/^r1\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n"); exit}' > t1.tsv
        '${params.bwa_neo}' aln -t ${params.threads_samse} '${ref}' '${reads}' > n.sai
        '${params.bwa_neo}' samse -t ${params.threads_samse} '${ref}' n.sai '${reads}' 2>/dev/null \\
            | awk '/^r1\\t/{for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n"); exit}' > tn.tsv
        cmp -s t1.tsv tn.tsv
        echo 'neo samse -t 1 vs -t ${params.threads_samse}: first-11 OK (aln -t ${params.threads_samse} for N arm)' > samse_thread_parity.ok
        export SUMMARY='neo samse -t 1 vs -t ${params.threads_samse}: first-11 OK (aln -t ${params.threads_samse} for N arm)'
        """
}

process PUBLICATION_MANIFEST {
    publishDir "${params.outdir}", mode: 'copy'

    input:
        val manifest_b64

    output:
        path 'publication_manifest.json'

    script:
        """
        set -euo pipefail
        printf '%s' '${manifest_b64}' | base64 -d > publication_manifest.json
        """
}

workflow {
    def ref_se = file(params.ref_fa, checkIfExists: true)
    def reads_se = file(params.reads_fq, checkIfExists: true)
    def ref_pe = file(params.ref_pe_fa, checkIfExists: true)
    def r1 = file(params.reads_pe_1, checkIfExists: true)
    def r2 = file(params.reads_pe_2, checkIfExists: true)

    def neo_meta = [id: 'neo', bwa: params.bwa_neo, samse_t: true]
    def base_enabled = params.enable_baseline && params.bwa_baseline?.toString()?.trim()
    def base_meta = [id: 'baseline', bwa: params.bwa_baseline, samse_t: false]

    def ch_se = Channel.of(neo_meta).mix(
            base_enabled ? Channel.of(base_meta) : Channel.empty()
        )
        .map { m -> tuple(m, ref_se, reads_se) }

    def ch_pe = Channel.of(neo_meta).mix(
            base_enabled ? Channel.of(base_meta) : Channel.empty()
        )
        .map { m -> tuple(m, ref_pe, r1, r2) }

    BWA_SE_BENCH(ch_se)
    BWA_PE_BENCH(ch_pe)

    def neo_se = BWA_SE_BENCH.out.sam.filter { meta, sam -> meta.id == 'neo' }.map { m, s -> s }
    def base_se = BWA_SE_BENCH.out.sam.filter { meta, sam -> meta.id == 'baseline' }.map { m, s -> s }
    def neo_pe = BWA_PE_BENCH.out.sam.filter { meta, sam -> meta.id == 'neo' }.map { m, s -> s }
    def base_pe = BWA_PE_BENCH.out.sam.filter { meta, sam -> meta.id == 'baseline' }.map { m, s -> s }

    PARITY_SE_FIRST11(neo_se.combine(base_se))
    PARITY_PE_FIRST11(neo_pe.combine(base_pe))

    NEO_SAMSE_THREAD_SELFTEST(Channel.of([ref_se, reads_se]))

    def ch_se_detail = base_enabled \
        ? PARITY_SE_FIRST11.out.msg \
        : Channel.value('SE first-11 parity skipped (baseline disabled or no bwa_baseline)')

    def ch_pe_detail = base_enabled \
        ? PARITY_PE_FIRST11.out.msg \
        : Channel.value('PE first-11 parity skipped (baseline disabled or no bwa_baseline)')

    def ch_thread_detail = params.check_samse_thread_parity \
        ? NEO_SAMSE_THREAD_SELFTEST.out.msg \
        : Channel.value('samse thread self-test disabled (check_samse_thread_parity=false)')

    def ch_triple = ch_se_detail
        .combine(ch_pe_detail)
        .combine(ch_thread_detail)
        .map { xs ->
            def lst = xs instanceof List ? xs : [xs]
            [lst[0], lst[1], lst[2]]
        }

    def ch_manifest_b64 = ch_triple.map { sd, pd, td ->
        def manifest = [
            schema: 'bwa-neo-benchmark-manifest-v2',
            generated_utc: Instant.now().toString(),
            threads_aln: params.threads_aln,
            threads_samse: params.threads_samse,
            threads_sampe_note: 'sampe has no -t in lh3/bwa or bwa-neo; mates use aln -t only',
            enable_baseline: base_enabled,
            check_samse_thread_parity: params.check_samse_thread_parity,
            bwa_neo: params.bwa_neo,
            bwa_baseline: params.bwa_baseline ?: '',
            inputs: [
                se_ref: params.ref_fa,
                se_reads: params.reads_fq,
                pe_ref: params.ref_pe_fa,
                pe_r1: params.reads_pe_1,
                pe_r2: params.reads_pe_2
            ],
            methods_notes: [
                samse_threads: 'neo uses samse -t; conda lh3/bwa omits -t on samse',
                pe: 'sampe is single-threaded; multi-threading is via aln -t per mate'
            ],
            parity_se: [
                enabled: base_enabled,
                detail: sd
            ],
            parity_pe: [
                enabled: base_enabled,
                detail: pd
            ],
            samse_thread_selftest: [
                enabled: params.check_samse_thread_parity,
                detail: td
            ]
        ]
        JsonOutput.prettyPrint(JsonOutput.toJson(manifest)).getBytes('UTF-8').encodeBase64().toString()
    }

    PUBLICATION_MANIFEST(ch_manifest_b64)
}
