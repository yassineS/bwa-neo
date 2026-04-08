#!/usr/bin/env nextflow
/*
 * bwa-neo benchmark: index + aln + samse; optional first-11 SAM parity vs baseline bwa;
 * publication_manifest.json for methods / supplements.
 */
nextflow.enable.dsl = 2

process BWA_ALN_SAMSE {
    tag "${meta.id}"
    publishDir "${params.outdir}/${meta.id}", mode: 'copy'

    input:
        tuple val(meta), path(ref), path(reads)

    output:
        tuple val(meta), path("${meta.id}.sam"), emit: sam
        tuple val(meta), path("${meta.id}_versions.txt"), emit: versions

    script:
        def bw = meta.bwa_bin as String
        def sid = meta.id as String
        // Upstream lh3/bwa has no `samse -t`; bwa-neo does. Keep aln threading symmetric where supported.
        def samse_extra = (sid == 'neo') ? "-t ${params.threads_samse}" : ''
        """
        set -euo pipefail
        '${bw}' index ${ref}
        '${bw}' aln -t ${params.threads_aln} ${ref} ${reads} > reads.sai
        '${bw}' samse ${samse_extra} ${ref} reads.sai ${reads} > ${sid}.sam
        echo "id=${meta.id}" > ${sid}_versions.txt
        echo "bwa=${bw}" >> ${sid}_versions.txt
        '${bw}' 2>&1 | head -n 3 >> ${sid}_versions.txt || true
        """
}

process SAM_FIRST11_DIFF {
    publishDir "${params.outdir}/parity", mode: 'copy'

    input:
        tuple path(neo_sam), path(base_sam)

    output:
        path('parity.ok'), emit: ok
        path('parity.first11.diff'), optional: true, emit: diff

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
          echo "SAM first-11 fields: neo == baseline OK" > parity.ok
        else
          echo "SAM first-11 fields: MISMATCH" > parity.ok
          diff -u base.first11.tsv neo.first11.tsv > parity.first11.diff || true
          exit 1
        fi
        """
}

process PUBLICATION_MANIFEST {
    publishDir "${params.outdir}", mode: 'copy'

    input:
        tuple val(_meta), path(neo_sam), path(neo_versions), path(parity_marker)

    output:
        path('publication_manifest.json'), emit: manifest

    script:
        """
        set -euo pipefail
        export BWA_NEO='${params.bwa_neo}'
        export BWA_BASELINE='${params.bwa_baseline}'
        python3 '${projectDir}/../scripts/write_publication_manifest.py' \\
          --neo-sam '${neo_sam}' \\
          --neo-versions '${neo_versions}' \\
          --parity-file '${parity_marker}' \\
          --ref-fa '${params.ref_fa}' \\
          --reads-fq '${params.reads_fq}' \\
          --out publication_manifest.json
        """
}

workflow {
    def ref = file(params.ref_fa, checkIfExists: true)
    def reads = file(params.reads_fq, checkIfExists: true)

    def neo_meta = [id: 'neo', bwa_bin: params.bwa_neo]
    def ch = channel.of(tuple(neo_meta, ref, reads))

    if (params.enable_baseline && params.bwa_baseline) {
        def base_meta = [id: 'baseline', bwa_bin: params.bwa_baseline]
        ch = ch.mix(channel.of(tuple(base_meta, ref, reads)))
    }

    BWA_ALN_SAMSE(ch)

    def neo_join = BWA_ALN_SAMSE.out.sam.join(BWA_ALN_SAMSE.out.versions)
        .filter { meta, sam, ver -> meta.id == 'neo' }

    def ch_parity
    if (params.enable_baseline && params.bwa_baseline) {
        def neo_sam = BWA_ALN_SAMSE.out.sam.filter { meta, sam -> meta.id == 'neo' }.map { m, s -> s }.first()
        def base_sam = BWA_ALN_SAMSE.out.sam.filter { meta, sam -> meta.id == 'baseline' }.map { m, s -> s }.first()
        SAM_FIRST11_DIFF(neo_sam.combine(base_sam))
        ch_parity = SAM_FIRST11_DIFF.out.ok
    } else {
        ch_parity = channel.fromPath("${projectDir}/../assets/no_parity.txt", checkIfExists: true)
    }

    PUBLICATION_MANIFEST(neo_join.combine(ch_parity))
}
