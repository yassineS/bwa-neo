#!/usr/bin/env nextflow
/*
 * bwa-neo benchmarks (all logic in-process; no external Python).
 * - SE: index + aln -t + samse (neo: samse -t; stock bwa: samse without -t)
 * - PE: index + aln -t on each mate + sampe (no -t on upstream or neo)
 * - Optional: neo samse -t1 vs samse -tN first-11 consistency (tiny fixture)
 */
nextflow.enable.dsl = 2

process BWA_SE_BENCH {
    tag "${meta.id}"
    publishDir "${params.outdir}/se/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(reads)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        tuple val(meta), path("${meta.id}_versions.txt"), emit: versions

    script:
        def bw = meta.bwa_bin as String
        def sid = meta.id as String
        def samse_t = meta.neo ? "-t ${params.threads_samse}" : ''
        """
        set -euo pipefail
        '${bw}' index ${ref}
        '${bw}' aln -t ${params.threads_aln} ${ref} ${reads} > reads.sai
        '${bw}' samse ${samse_t} ${ref} reads.sai ${reads} > ${sid}.sam
        echo "id=${sid}" > ${sid}_versions.txt
        echo "bwa=${bw}" >> ${sid}_versions.txt
        echo "threads_aln=${params.threads_aln}" >> ${sid}_versions.txt
        echo "threads_samse=${params.threads_samse}" >> ${sid}_versions.txt
        '${bw}' 2>&1 | head -n 3 >> ${sid}_versions.txt || true
        """
}

process BWA_PE_BENCH {
    tag "${meta.id}"
    publishDir "${params.outdir}/pe/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(r1), path(r2)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        tuple val(meta), path("${meta.id}_versions.txt"), emit: versions

    script:
        def bw = meta.bwa_bin as String
        def sid = meta.id as String
        """
        set -euo pipefail
        '${bw}' index ${ref}
        '${bw}' aln -t ${params.threads_aln} ${ref} ${r1} > r1.sai
        '${bw}' aln -t ${params.threads_aln} ${ref} ${r2} > r2.sai
        '${bw}' sampe ${ref} r1.sai r2.sai ${r1} ${r2} > ${sid}.sam
        echo "id=${sid}" > ${sid}_versions.txt
        echo "bwa=${bw}" >> ${sid}_versions.txt
        echo "threads_aln=${params.threads_aln}" >> ${sid}_versions.txt
        '${bw}' 2>&1 | head -n 3 >> ${sid}_versions.txt || true
        """
}

process PARITY_SE_FIRST11 {
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(base_sam)

    output:
        path('parity_se.ok'), emit: ok
        path('parity_se.first11.diff'), optional: true, emit: diff

    script:
        """
        set -euo pipefail
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' '${neo_sam}' > neo.first11.tsv
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' '${base_sam}' > base.first11.tsv
        if cmp -s neo.first11.tsv base.first11.tsv; then
          echo "SE SAM first-11: neo == baseline OK" > parity_se.ok
        else
          echo "SE SAM first-11: MISMATCH" > parity_se.ok
          diff -u base.first11.tsv neo.first11.tsv > parity_se.first11.diff || true
          exit 1
        fi
        """
}

process PARITY_PE_FIRST11 {
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(base_sam)

    output:
        path('parity_pe.ok'), emit: ok
        path('parity_pe.first11.diff'), optional: true, emit: diff

    script:
        """
        set -euo pipefail
        awk -F'\\t' '/^pair\\t/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
        }' '${neo_sam}' | sort > neo.pair.first11.tsv
        awk -F'\\t' '/^pair\\t/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
        }' '${base_sam}' | sort > base.pair.first11.tsv
        if cmp -s neo.pair.first11.tsv base.pair.first11.tsv; then
          echo "PE SAM first-11 (pair): neo == baseline OK" > parity_pe.ok
        else
          echo "PE SAM first-11 (pair): MISMATCH" > parity_pe.ok
          diff -u base.pair.first11.tsv neo.pair.first11.tsv > parity_pe.first11.diff || true
          exit 1
        fi
        """
}

process NEO_SAMSE_THREAD_SELFTEST {
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(ref), path(reads)

    output:
        path('samse_thread_parity.ok'), emit: ok
        path('samse_thread_parity.diff'), optional: true, emit: diff

    script:
        def neo = params.bwa_neo
        def tn = params.threads_samse
        def ta = params.threads_aln
        """
        set -euo pipefail
        '${neo}' index ${ref}
        '${neo}' aln -t 1 ${ref} ${reads} > sai1.sai
        '${neo}' samse -t 1 ${ref} sai1.sai ${reads} > sam_t1.sam
        '${neo}' aln -t ${ta} ${ref} ${reads} > saiN.sai
        '${neo}' samse -t ${tn} ${ref} saiN.sai ${reads} > sam_tN.sam
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' sam_t1.sam > t1.first11.tsv
        awk '/^[^@]/{
          for(i=1;i<=11;i++) printf "%s%s", \$i, (i<11 ? "\\t" : "\\n")
          exit
        }' sam_tN.sam > tN.first11.tsv
        if cmp -s t1.first11.tsv tN.first11.tsv; then
          echo "neo samse -t 1 vs -t ${tn}: first-11 OK (aln -t ${ta} for N arm)" > samse_thread_parity.ok
        else
          echo "neo samse thread parity: MISMATCH" > samse_thread_parity.ok
          diff -u t1.first11.tsv tN.first11.tsv > samse_thread_parity.diff || true
          exit 1
        fi
        """
}

process PUBLICATION_MANIFEST {
    publishDir "${params.outdir}", mode: 'copy'

    input:
        val manifest_b64

    output:
        path('publication_manifest.json'), emit: manifest

    script:
    """
    printf '%s' '${manifest_b64}' | base64 -d > publication_manifest.json
    """
}

workflow {
    def neo_m = { [id: 'neo', neo: true, bwa_bin: params.bwa_neo] }
    def base_m = { [id: 'baseline', neo: false, bwa_bin: params.bwa_baseline] }

    // --- single-end ---
    def ref_se = file(params.ref_fa, checkIfExists: true)
    def reads_se = file(params.reads_fq, checkIfExists: true)
    def ch_se = channel.of(tuple(neo_m(), ref_se, reads_se))
    if (params.enable_baseline && params.bwa_baseline) {
        ch_se = ch_se.mix(channel.of(tuple(base_m(), ref_se, reads_se)))
    }
    BWA_SE_BENCH(ch_se)

    def ch_se_parity
    if (params.enable_baseline && params.bwa_baseline) {
        def n_se = BWA_SE_BENCH.out.sam.filter { m, s -> m.id == 'neo' }.map { m, s -> s }.first()
        def b_se = BWA_SE_BENCH.out.sam.filter { m, s -> m.id == 'baseline' }.map { m, s -> s }.first()
        PARITY_SE_FIRST11(n_se.combine(b_se))
        ch_se_parity = PARITY_SE_FIRST11.out.ok
    } else {
        ch_se_parity = channel.fromPath("${projectDir}/../assets/no_parity.txt", checkIfExists: true)
    }

    // --- paired-end ---
    def ref_pe = file(params.ref_pe_fa, checkIfExists: true)
    def r1 = file(params.reads_pe_1, checkIfExists: true)
    def r2 = file(params.reads_pe_2, checkIfExists: true)
    def ch_pe = channel.of(tuple(neo_m(), ref_pe, r1, r2))
    if (params.enable_baseline && params.bwa_baseline) {
        ch_pe = ch_pe.mix(channel.of(tuple(base_m(), ref_pe, r1, r2)))
    }
    BWA_PE_BENCH(ch_pe)

    def ch_pe_parity
    if (params.enable_baseline && params.bwa_baseline) {
        def n_pe = BWA_PE_BENCH.out.sam.filter { m, s -> m.id == 'neo' }.map { m, s -> s }.first()
        def b_pe = BWA_PE_BENCH.out.sam.filter { m, s -> m.id == 'baseline' }.map { m, s -> s }.first()
        PARITY_PE_FIRST11(n_pe.combine(b_pe))
        ch_pe_parity = PARITY_PE_FIRST11.out.ok
    } else {
        ch_pe_parity = channel.fromPath("${projectDir}/../assets/no_parity.txt", checkIfExists: true)
    }

    // --- neo samse -t1 vs -tN (single-end fixture only) ---
    def ch_th
    if (params.check_samse_thread_parity) {
        NEO_SAMSE_THREAD_SELFTEST(channel.of(tuple(ref_se, reads_se)))
        ch_th = NEO_SAMSE_THREAD_SELFTEST.out.ok
    } else {
        ch_th = channel.fromPath("${projectDir}/../assets/omitted.txt", checkIfExists: true)
    }

    def staticJson = groovy.json.JsonOutput.toJson([
        schema: 'bwa-neo-benchmark-manifest-v2',
        generated_utc: java.time.Instant.now().toString(),
        threads_aln: params.threads_aln,
        threads_samse: params.threads_samse,
        threads_sampe_note: 'sampe has no -t in lh3/bwa or bwa-neo; mates use aln -t only',
        enable_baseline: params.enable_baseline,
        bwa_neo: params.bwa_neo,
        bwa_baseline: params.bwa_baseline ?: '',
        inputs: [
            se_ref: params.ref_fa,
            se_reads: params.reads_fq,
            pe_ref: params.ref_pe_fa,
            pe_r1: params.reads_pe_1,
            pe_r2: params.reads_pe_2,
        ],
        methods_notes: [
            samse_threads: 'neo uses samse -t; conda lh3/bwa omits -t on samse',
            pe: 'sampe is single-threaded; multi-threading is via aln -t per mate',
        ],
    ])

    def ch_manifest = ch_se_parity.combine(ch_pe_parity).combine(ch_th).combine(channel.value(staticJson))
        .map { se_parity, pe_parity, thread_parity, st ->
            def base = new groovy.json.JsonSlurper().parseText(st as String)
            def seTxt = se_parity.text.trim()
            def peTxt = pe_parity.text.trim()
            def thTxt = thread_parity.text.trim()
            if (seTxt.startsWith('OMITTED')) {
                base.parity_se = [enabled: false, reason: 'track_omitted']
            } else if (seTxt.contains('parity_skipped')) {
                base.parity_se = [enabled: false, reason: 'no_baseline']
            } else {
                base.parity_se = [enabled: true, detail: seTxt]
            }
            if (peTxt.startsWith('OMITTED')) {
                base.parity_pe = [enabled: false, reason: 'track_omitted']
            } else if (peTxt.contains('parity_skipped')) {
                base.parity_pe = [enabled: false, reason: 'no_baseline']
            } else {
                base.parity_pe = [enabled: true, detail: peTxt]
            }
            if (thTxt.startsWith('OMITTED')) {
                base.samse_thread_selftest = [enabled: false, reason: 'disabled_by_params']
            } else {
                base.samse_thread_selftest = [enabled: true, detail: thTxt]
            }
            def json = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(base))
            return json.bytes.encodeBase64().toString()
        }

    PUBLICATION_MANIFEST(ch_manifest)
}
